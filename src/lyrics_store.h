#pragma once

#include <QString>
#include <QVariantMap>

/// Per-song lyrics files. Kept out of settings.ini, which QSettings rewrites whole on every change.
namespace lyrics {

struct Stored {
    QString text;
    QString provider;
    qint64 missingAt = 0;
};

QString key(const QString &title, const QString &artist, const QString &album);
/// Uses the file name when the track has no title, as fetchLyrics does.
QString keyFor(const QVariantMap &track);
Stored load(const QString &key);
/// Returns false if the file could not be written.
bool save(const QString &key, const QString &text, const QString &provider);
/// Records a miss so the library fetch skips the song for a while.
void markMissing(const QString &key);
bool missingRecently(const Stored &stored);
/// Moves lyrics out of the old lyrics/cache settings keys, which are kept until all of them are moved.
void moveFromSettings();

} // namespace lyrics
