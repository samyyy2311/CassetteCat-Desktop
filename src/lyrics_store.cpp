#include "lyrics_store.h"

#include "app_settings.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QStandardPaths>

namespace lyrics {
namespace {

// Misses are retried after this, since LRCLIB keeps growing.
constexpr qint64 missingRetrySeconds = 30LL * 24 * 60 * 60;

// Not CacheLocation: user-entered lyrics have no other copy.
QString folder() {
    return QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/lyrics";
}

QString pathFor(const QString &key) {
    return folder() + "/" + key + ".json";
}

QJsonObject readObject(const QString &key) {
    QFile file(pathFor(key));
    if (!file.open(QIODevice::ReadOnly))
        return {};
    return QJsonDocument::fromJson(file.readAll()).object();
}

bool writeObject(const QString &key, const QJsonObject &object) {
    QDir().mkpath(folder());
    QSaveFile file(pathFor(key));
    return file.open(QIODevice::WriteOnly) && file.write(QJsonDocument(object).toJson(QJsonDocument::Compact)) >= 0 &&
           file.commit();
}

} // namespace

QString key(const QString &title, const QString &artist, const QString &album) {
    const QString source = (artist + "|" + title + "|" + album).trimmed().toCaseFolded();
    return QString::fromLatin1(QCryptographicHash::hash(source.toUtf8(), QCryptographicHash::Sha256).toHex());
}

QString keyFor(const QVariantMap &track) {
    const QString title = track.value("title").toString();
    return key(title.isEmpty() ? track.value("fileName").toString() : title, track.value("artist").toString(),
               track.value("album").toString());
}

Stored load(const QString &key) {
    const QJsonObject object = readObject(key);
    return {object.value("text").toString(), object.value("provider").toString(),
            object.value("missingAt").toInteger()};
}

bool save(const QString &key, const QString &text, const QString &provider) {
    return writeObject(key, {{"text", text}, {"provider", provider}});
}

void markMissing(const QString &key) {
    // Lyrics saved during the lookup take precedence.
    if (!load(key).text.isEmpty())
        return;
    writeObject(key, {{"missingAt", QDateTime::currentSecsSinceEpoch()}});
}

bool missingRecently(const Stored &stored) {
    return stored.missingAt > 0 && QDateTime::currentSecsSinceEpoch() - stored.missingAt < missingRetrySeconds;
}

void moveFromSettings() {
    const QVariantMap texts = SettingsController::globalGroup("lyrics/cache");
    const QVariantMap providers = SettingsController::globalGroup("lyrics/provider");
    if (texts.isEmpty() && providers.isEmpty())
        return;
    bool moved = true;
    for (auto it = texts.cbegin(); it != texts.cend(); ++it) {
        // A retry after a failed move must not overwrite lyrics saved since.
        if (load(it.key()).text.isEmpty())
            moved = save(it.key(), it.value().toString(), providers.value(it.key(), "LRCLIB").toString()) && moved;
    }
    if (!moved) {
        qWarning() << "Could not move every saved lyric out of settings; trying again next start";
        return;
    }
    SettingsController::removeGlobalGroup("lyrics/cache");
    SettingsController::removeGlobalGroup("lyrics/provider");
}

} // namespace lyrics
