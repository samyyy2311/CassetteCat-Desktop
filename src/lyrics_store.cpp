#include "lyrics_store.h"

#include "app_settings.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QStandardPaths>

namespace lyrics {
namespace {

// A song LRCLIB had nothing for is asked about again after this, in case someone has added it since.
constexpr qint64 missingRetrySeconds = 30LL * 24 * 60 * 60;

// Kept with the app's data rather than its cache, as lyrics written in the app exist nowhere else.
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

void writeObject(const QString &key, const QJsonObject &object) {
    QDir().mkpath(folder());
    QSaveFile file(pathFor(key));
    if (file.open(QIODevice::WriteOnly) && file.write(QJsonDocument(object).toJson(QJsonDocument::Compact)) >= 0)
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

Stored read(const QString &key) {
    const QJsonObject object = readObject(key);
    return {object.value("text").toString(), object.value("provider").toString()};
}

void write(const QString &key, const QString &text, const QString &provider) {
    writeObject(key, {{"text", text}, {"provider", provider}});
}

void markMissing(const QString &key) {
    writeObject(key, {{"missingAt", QDateTime::currentSecsSinceEpoch()}});
}

bool missingRecently(const QString &key) {
    const qint64 missingAt = readObject(key).value("missingAt").toInteger();
    return missingAt > 0 && QDateTime::currentSecsSinceEpoch() - missingAt < missingRetrySeconds;
}

void moveFromSettings() {
    const QVariantMap texts = SettingsController::takeGlobalGroup("lyrics/cache");
    const QVariantMap providers = SettingsController::takeGlobalGroup("lyrics/provider");
    for (auto it = texts.cbegin(); it != texts.cend(); ++it)
        write(it.key(), it.value().toString(), providers.value(it.key(), "LRCLIB").toString());
}

} // namespace lyrics
