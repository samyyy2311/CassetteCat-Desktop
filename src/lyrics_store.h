#pragma once

#include <QString>
#include <QVariantMap>

/// Lyrics fetched online or written in the app, kept as one small file per song so a library's worth of them stays
/// out of the settings file.
namespace lyrics {

struct Stored {
    QString text;
    QString provider;
};

QString key(const QString &title, const QString &artist, const QString &album);
/// The key for a library track; one without a title goes by its file name, as when its lyrics are fetched.
QString keyFor(const QVariantMap &track);
Stored read(const QString &key);
void write(const QString &key, const QString &text, const QString &provider);
/// Notes that no lyrics were found, so fetching for the whole library skips the song for a while.
void markMissing(const QString &key);
bool missingRecently(const QString &key);
/// Moves lyrics saved by earlier versions in the settings file into their own files.
void moveFromSettings();

} // namespace lyrics
