#include "image_cache.h"

#include "audio_metadata.h"

#include <QBuffer>
#include <QCryptographicHash>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QImageReader>
#include <QPainter>
#include <QSaveFile>
#include <QStandardPaths>
#include <QUrl>

namespace {

// Nothing in the app shows a cached image larger than kFullArtworkSize, so a larger download is stored at that size.
// Anything that already fits is kept byte for byte.
QByteArray fitForCache(const QByteArray &image, bool png) {
    QBuffer input;
    input.setData(image);
    QImageReader reader(&input);
    reader.setAutoTransform(true);
    const QSize size = reader.size();
    if (!size.isValid() || (size.width() <= kFullArtworkSize && size.height() <= kFullArtworkSize))
        return image;
    QImage fitted =
        reader.read().scaled(kFullArtworkSize, kFullArtworkSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    if (fitted.isNull())
        return image;
    // The encoding must match the file's extension; JPEG has no transparency, so it is flattened onto black.
    if (!png && fitted.hasAlphaChannel()) {
        QImage flat(fitted.size(), QImage::Format_RGB32);
        flat.fill(Qt::black);
        QPainter(&flat).drawImage(0, 0, fitted);
        fitted = flat;
    }
    QByteArray output;
    QBuffer buffer(&output);
    buffer.open(QIODevice::WriteOnly);
    return fitted.save(&buffer, png ? "PNG" : "JPEG", png ? -1 : 92) ? output : image;
}

} // namespace

void shrinkOversizedCachedImages() {
    const QString root = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    for (const QString &category : {QStringLiteral("covers"), QStringLiteral("artists")}) {
        QDirIterator it(root + "/" + category, QDir::Files);
        while (it.hasNext()) {
            const QString path = it.next();
            const QSize size = QImageReader(path).size();
            if (size.width() <= kFullArtworkSize && size.height() <= kFullArtworkSize)
                continue;
            QFile file(path);
            if (!file.open(QIODevice::ReadOnly))
                continue;
            const QByteArray original = file.readAll();
            file.close();
            const QByteArray fitted = fitForCache(original, path.endsWith(QStringLiteral(".png")));
            if (fitted.size() >= original.size())
                continue;
            QSaveFile output(path);
            if (output.open(QIODevice::WriteOnly) && output.write(fitted) == fitted.size())
                output.commit();
        }
    }
}

QString saveCachedImage(const QByteArray &image, const QString &key, bool png, const QString &category) {
    if (image.isEmpty()) {
        return {};
    }

    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/" + category;
    QDir().mkpath(cacheDir);
    const QString path = cacheDir + "/" +
                         QString::fromLatin1(QCryptographicHash::hash(key.toUtf8(), QCryptographicHash::Sha1).toHex()) +
                         (png ? ".png" : ".jpg");
    if (!QFileInfo::exists(path)) {
        const QByteArray fitted = fitForCache(image, png);
        QSaveFile output(path);
        if (!output.open(QIODevice::WriteOnly) || output.write(fitted) != fitted.size() || !output.commit()) {
            return {};
        }
    }
    return QUrl::fromLocalFile(path).toString();
}

CoverImageProvider::CoverImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image, QQmlImageProviderBase::ForceAsynchronousImageLoading) {}

QString CoverImageProvider::urlFor(const QString &filePath) {
    // Base64 keeps arbitrary path characters intact through QML's URL handling. The leading 0 is the corner radius.
    const auto options = QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals;
    return QStringLiteral("image://cover/0/track:") + QString::fromLatin1(filePath.toUtf8().toBase64(options));
}

QImage CoverImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize) {
    const double radiusFraction = id.section('/', 0, 0).toDouble();
    const QString source = id.section('/', 1);
    QString imagePath;
    if (source.startsWith(QStringLiteral("track:"))) {
        const QString trackPath =
            QString::fromUtf8(QByteArray::fromBase64(source.mid(6).toLatin1(), QByteArray::Base64UrlEncoding));
        // Most covers are small; only large views pay for a full-size extraction.
        const int longEdge = qMax(requestedSize.width(), requestedSize.height());
        imagePath = QUrl(extractEmbeddedArtwork(trackPath, longEdge > 512 ? kFullArtworkSize : 512)).toLocalFile();
    } else if (source.startsWith(QStringLiteral("qrc:"))) {
        imagePath = ':' + QUrl(source).path();
    } else {
        imagePath = QUrl(source).toLocalFile();
    }
    // Qt logs a warning for every failed request, so a missing cover is a transparent 1x1 image that Cover
    // treats as no artwork.
    if (imagePath.isEmpty() || !QFileInfo::exists(imagePath)) {
        *size = QSize(1, 1);
        QImage none(1, 1, QImage::Format_ARGB32_Premultiplied);
        none.fill(Qt::transparent);
        return none;
    }

    QImageReader reader(imagePath);
    reader.setAutoTransform(true);
    *size = reader.size();
    // Items that are not laid out yet request 0x0.
    if (requestedSize.isEmpty() || !size->isValid())
        return reader.read();

    // Crop to the requested box and round the corners here, so QML needs no per-cover mask layers.
    reader.setScaledSize(size->scaled(requestedSize, Qt::KeepAspectRatioByExpanding));
    QImage image = reader.read();
    if (image.isNull())
        return {};
    if (image.width() < requestedSize.width() || image.height() < requestedSize.height())
        image = image.scaled(requestedSize, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
    image = image.copy((image.width() - requestedSize.width()) / 2, (image.height() - requestedSize.height()) / 2,
                       requestedSize.width(), requestedSize.height());
    const double radius = radiusFraction * qMin(requestedSize.width(), requestedSize.height());
    if (radius <= 0)
        return image;

    QImage rounded(requestedSize, QImage::Format_ARGB32_Premultiplied);
    rounded.fill(Qt::transparent);
    QPainter painter(&rounded);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setPen(Qt::NoPen);
    painter.setBrush(image);
    painter.drawRoundedRect(QRectF(QPointF(0, 0), QSizeF(requestedSize)), radius, radius);
    return rounded;
}
