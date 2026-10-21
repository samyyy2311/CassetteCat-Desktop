#pragma once

#include <QString>
#include <QVariantMap>

/// Per-song lyrics files. Kept out of settings.ini, which QSettings rewrites whole on every change.
namespace lyrics {

struct Stored {
    QString text;
    QString provider;
};

QString key(const QString &title, const QString &artist, const QString &album);
/// Uses the file name when the track has no title, as fetchLyrics does.
QString keyFor(const QVariantMap &track);
Stored load(const QString &key);
void save(const QString &key, const QString &text, const QString &provider);
/// Records a miss so the library fetch skips the song for a while.
void markMissing(const QString &key);
bool missingRecently(const QString &key);
/// One-time migration from the old lyrics/cache settings keys.
void moveFromSettings();

} // namespace lyrics
