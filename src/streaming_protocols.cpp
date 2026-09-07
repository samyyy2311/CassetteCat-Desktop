#include "streaming_protocols.h"

#include <QCryptographicHash>
#include <QJsonDocument>
#include <QRandomGenerator>
#include <QUrlQuery>

namespace streaming::protocol {

namespace {

constexpr char kSubsonicVersion[] = "1.16.1";
constexpr char kClientName[] = "CassetteCat";
constexpr char kJellyfinVersion[] = "2.0.0";

QString formatTrackDuration(int totalSeconds)
{
    if (totalSeconds <= 0) {
        return {};
    }
    return QString("%1:%2").arg(totalSeconds / 60).arg(totalSeconds % 60, 2, 10, QChar('0'));
}

} // namespace

QString normalizeServerUrl(const QString &raw, int defaultPort)
{
    QString url = raw.trimmed();
    while (url.endsWith('/')) {
        url.chop(1);
    }
    if (url.isEmpty()) {
        return {};
    }
    if (!url.startsWith("http://", Qt::CaseInsensitive) && !url.startsWith("https://", Qt::CaseInsensitive)) {
        const bool isLocal = url.startsWith("192.168.") || url.startsWith("10.") ||
                             url.startsWith("172.") || url.startsWith("127.") ||
                             url.startsWith("localhost", Qt::CaseInsensitive) ||
                             url.contains(".local", Qt::CaseInsensitive) ||
                             url.contains(":8096") || url.contains(":4533") ||
                             url.contains(":8080") || url.contains(":8000");
        url.prepend(isLocal ? "http://" : "https://");
    }
    if (defaultPort > 0) {
        QUrl parsed(url);
        if (parsed.port() == -1) {
            const QString host = parsed.host();
            const bool isLocalHost = host.startsWith("192.168.") || host.startsWith("10.") ||
                                     host.startsWith("172.") || host.startsWith("127.") ||
                                     host.compare("localhost", Qt::CaseInsensitive) == 0 ||
                                     host.endsWith(".local", Qt::CaseInsensitive);
            if (isLocalHost) {
                parsed.setPort(defaultPort);
                url = parsed.toString();
                while (url.endsWith('/')) {
                    url.chop(1);
                }
            }
        }
    }
    return url;
}

QString md5Hex(const QString &input)
{
    return QString::fromLatin1(
        QCryptographicHash::hash(input.toUtf8(), QCryptographicHash::Md5).toHex());
}

QString randomSalt()
{
    QString salt;
    salt.reserve(12);
    static const char digits[] = "0123456789abcdef";
    for (int i = 0; i < 12; ++i) {
        salt.append(digits[QRandomGenerator::global()->bounded(16)]);
    }
    return salt;
}

QUrl subsonicUrl(const QString &base, const QString &endpoint, const QString &username,
                 const QString &token, const QString &salt,
                 const QList<QPair<QString, QString>> &extra)
{
    QUrl url(base + "/rest/" + endpoint);
    QUrlQuery q;
    q.addQueryItem("u", username);
    q.addQueryItem("t", token);
    q.addQueryItem("s", salt);
    q.addQueryItem("v", kSubsonicVersion);
    q.addQueryItem("c", kClientName);
    q.addQueryItem("f", "json");
    for (const auto &item : extra) {
        q.addQueryItem(item.first, item.second);
    }
    url.setQuery(q);
    return url;
}

QJsonArray jsonArrayTolerant(const QJsonObject &object, const char *key)
{
    const QJsonValue value = object.value(QLatin1String(key));
    if (value.isArray()) {
        return value.toArray();
    }
    if (value.isObject()) {
        return QJsonArray{value.toObject()};
    }
    return {};
}

QJsonObject parseSubsonicBody(const QByteArray &body)
{
    const QJsonDocument doc = QJsonDocument::fromJson(body);
    if (!doc.isObject()) {
        return {{"_error", QString("Unreadable server response")}};
    }
    const QJsonObject response = doc.object().value("subsonic-response").toObject();
    if (response.value("status").toString() != "ok") {
        const QString message = response.value("error").toObject().value("message").toString();
        return {{"_error", message.isEmpty() ? QString("Subsonic request failed") : message}};
    }
    return response;
}

QVariantMap subsonicTrackMap(const QJsonObject &song, const QString &albumName, const QString &albumCover)
{
    const QString id = song.value("id").toString();
    const int secs = song.value("duration").toVariant().toLongLong();
    QVariantMap track;
    track.insert("filePath", "subsonic:" + id);
    track.insert("fileName", song.value("title").toString());
    track.insert("title", song.value("title").toString());
    const QString artist = song.value("artist").toString();
    track.insert("artist", artist.isEmpty() ? QString("Unknown Artist") : artist);
    track.insert("album", albumName);
    track.insert("genre", song.value("genre").toString());
    track.insert("durationSeconds", secs);
    track.insert("duration", formatTrackDuration(secs));
    track.insert("format", song.value("suffix").toString().toUpper());
    track.insert("source", QString("subsonic"));
    track.insert("remoteId", id);
    track.insert("isFavorite", song.contains("starred") && !song.value("starred").isNull());
    const QString cover = song.value("coverArt").toString();
    track.insert("remoteArtId", cover.isEmpty() ? albumCover : cover);
    return track;
}

QString jellyfinAuthHeader(const QString &deviceId, const QString &accessToken)
{
    QString header = QString("MediaBrowser Client=\"%1\", Device=\"Desktop\", DeviceId=\"%2\", Version=\"%3\"")
                         .arg(kClientName, deviceId, kJellyfinVersion);
    if (!accessToken.isEmpty()) {
        header += QString(", Token=\"%1\"").arg(accessToken);
    }
    return header;
}

QVariantMap jellyfinTrackMap(const QJsonObject &item)
{
    const QString id = item.value("Id").toString();
    const long long ticks = item.value("RunTimeTicks").toVariant().toLongLong();
    const int secs = static_cast<int>(ticks / 10000000LL);
    QVariantMap track;
    track.insert("filePath", "jellyfin:" + id);
    track.insert("fileName", item.value("Name").toString());
    track.insert("title", item.value("Name").toString());
    const QString artist = item.value("AlbumArtist").toString();
    track.insert("artist", artist.isEmpty() ? QString("Unknown Artist") : artist);
    const QString album = item.value("Album").toString();
    track.insert("album", album.isEmpty() ? QString("Unknown Album") : album);
    const QJsonArray genres = item.value("Genres").toArray();
    track.insert("genre", genres.isEmpty() ? QString() : genres.first().toString());
    track.insert("durationSeconds", secs);
    track.insert("duration", formatTrackDuration(secs));
    track.insert("format", item.value("Container").toString().toUpper());
    track.insert("source", QString("jellyfin"));
    track.insert("remoteId", id);
    track.insert("isFavorite", item.value("UserData").toObject().value("IsFavorite").toBool(false));
    const QJsonObject imageTags = item.value("ImageTags").toObject();
    track.insert("remoteArtId", imageTags.contains("Primary") && !imageTags.value("Primary").isNull()
        ? id : item.value("AlbumId").toString());
    return track;
}

} // namespace streaming::protocol
