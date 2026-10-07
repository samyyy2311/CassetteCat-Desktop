#pragma once

#include <QByteArray>
#include <QQuickImageProvider>
#include <QString>

QString saveCachedImage(const QByteArray &image, const QString &key, bool png, const QString &category);
/// Shrinks downloaded images that earlier versions cached at full size, keeping their file names so saved references
/// still point at them. Images that already fit are not touched.
void shrinkOversizedCachedImages();

/// Serves cover art as image://cover/<radius>/<source>, decoding off the GUI thread. <source> is a local file URL or
/// track:<base64 path> for embedded artwork; <radius> is the corner radius as a fraction of the shorter side.
class CoverImageProvider final : public QQuickImageProvider {
  public:
    CoverImageProvider();
    static QString urlFor(const QString &filePath);
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
};
