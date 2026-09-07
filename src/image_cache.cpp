#include "image_cache.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFileInfo>
#include <QSaveFile>
#include <QStandardPaths>
#include <QUrl>

QString saveCachedImage(const QByteArray &image, const QString &key, bool png, const QString &category)
{
    if (image.isEmpty()) {
        return {};
    }

    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/" + category;
    QDir().mkpath(cacheDir);
    const QString path = cacheDir + "/" + QString::fromLatin1(
        QCryptographicHash::hash(key.toUtf8(), QCryptographicHash::Sha1).toHex()) + (png ? ".png" : ".jpg");
    if (!QFileInfo::exists(path)) {
        QSaveFile output(path);
        if (!output.open(QIODevice::WriteOnly) || output.write(image) != image.size() || !output.commit()) {
            return {};
        }
    }
    return QUrl::fromLocalFile(path).toString();
}
