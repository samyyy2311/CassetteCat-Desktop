#include "streaming_protocols.h"

#include <QCryptographicHash>
#include <QHostAddress>
#include <QJsonDocument>
#include <QRandomGenerator>
#include <QUrlQuery>

namespace streaming::protocol {

namespace {

constexpr char kSubsonicVersion[] = "1.16.1";
constexpr char kClientName[] = "CassetteCat";
constexpr char kJellyfinVersion[] = "2.0.0";

QString formatTrackDuration(int totalSeconds) {
    if (totalSeconds <= 0) {
        return {};
    }
    return QString("%1:%2").arg(totalSeconds / 60).arg(totalSeconds % 60, 2, 10, QChar('0'));
}

bool isPrivateOrLocalHost(const QString &host) {
    const QString value = host.trimmed();
    if (value.isEmpty()) {
        return false;
    }
    if (value.compare("localhost", Qt::CaseInsensitive) == 0 || value.endsWith(".local", Qt::CaseInsensitive) ||
        value.endsWith(".lan", Qt::CaseInsensitive) || value.endsWith(".home.arpa", Qt::CaseInsensitive) ||
        value.endsWith(".internal", Qt::CaseInsensitive) || value.endsWith(".localdomain", Qt::CaseInsensitive)) {
        return true;
    }

    QHostAddress address;
    if (!address.setAddress(value)) {
        return !value.contains('.');
    }
    if (address.isLoopback()) {
        return true;
    }

    bool isIpv4 = false;
    const quint32 ipv4 = address.toIPv4Address(&isIpv4);
    if (isIpv4) {
        const quint8 first = static_cast<quint8>(ipv4 >> 24);
        const quint8 second = static_cast<quint8>((ipv4 >> 16) & 0xff);
        return first == 10 || (first == 172 && second >= 16 && second <= 31) || (first == 192 && second == 168) ||
               (first == 169 && second == 254);
    }

    const Q_IPV6ADDR ipv6 = address.toIPv6Address();
    return (ipv6.c[0] & 0xfe) == 0xfc || (ipv6.c[0] == 0xfe && (ipv6.c[1] & 0xc0) == 0x80);
}

QString hostFromUnschemedUrl(const QString &value) {
    return QUrl("http://" + value).host();
}

} // namespace

QString normalizeServerUrl(const QString &raw, int defaultPort) {
    QString url = raw.trimmed();
    while (url.endsWith('/')) {
        url.chop(1);
    }
    if (url.isEmpty()) {
        return {};
    }
    if (!url.startsWith("http://", Qt::CaseInsensitive) && !url.startsWith("https://", Qt::CaseInsensitive)) {
        const QString host = hostFromUnschemedUrl(url);
        if (host.isEmpty()) {
            return {};
        }
        url.prepend(isPrivateOrLocalHost(host) ? "http://" : "https://");
    }

    const QUrl parsed(url);
    if (!parsed.isValid() || parsed.host().isEmpty() ||
        (parsed.scheme().compare("http", Qt::CaseInsensitive) != 0 &&
         parsed.scheme().compare("https", Qt::CaseInsensitive) != 0) ||
        !parsed.userInfo().isEmpty() || parsed.hasQuery() || parsed.hasFragment() ||
        (parsed.scheme().compare("http", Qt::CaseInsensitive) == 0 && !isPrivateOrLocalHost(parsed.host()))) {
        return {};
    }

    QString normalized = parsed.toString();
    while (normalized.endsWith('/')) {
        normalized.chop(1);
    }
    if (defaultPort > 0) {
        QUrl withPort(parsed);
        if (withPort.port() == -1 && isPrivateOrLocalHost(parsed.host())) {
            withPort.setPort(defaultPort);
            normalized = withPort.toString();
            while (normalized.endsWith('/')) {
                normalized.chop(1);
            }
        }
    }
    return normalized;
}

QString md5Hex(const QString &input) {
    return QString::fromLatin1(QCryptographicHash::hash(input.toUtf8(), QCryptographicHash::Md5).toHex());
}

QString randomSalt() {
    QString salt;
    salt.reserve(12);
    static const char digits[] = "0123456789abcdef";
    for (int i = 0; i < 12; ++i) {
        salt.append(digits[QRandomGenerator::global()->bounded(16)]);
    }
    return salt;
}

QUrl subsonicUrl(const QString &base, const QString &endpoint, const QString &username, const QString &token,
                 const QString &salt, const QList<QPair<QString, QString>> &extra) {
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

QJsonArray jsonArrayTolerant(const QJsonObject &object, const char *key) {
    const QJsonValue value = object.value(QLatin1String(key));
    if (value.isArray()) {
        return value.toArray();
    }
    if (value.isObject()) {
        return QJsonArray{value.toObject()};
    }
    return {};
}

QJsonObject parseSubsonicBody(const QByteArray &body) {
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

QVariantMap subsonicTrackMap(const QJsonObject &song, const QString &albumName, const QString &albumCover) {
    const QString id = song.value("id").toString();
    const int secs = song.value("duration").toVariant().toLongLong();
    QVariantMap track;
    track.insert("filePath", "subsonic:" + id);
    track.insert("fileName", song.value("title").toString());
    track.insert("title", song.value("title").toString());
    QString artist = song.value("artist").toString().trimmed();
    if (artist.isEmpty()) {
        artist = "Unknown Artist";
    }
    track.insert("artist", artist);
    const QString album = song.value("album").toString().trimmed();
    track.insert("album", album.isEmpty() ? (albumName.isEmpty() ? QString("Unknown Album") : albumName) : album);
    const QString genre = song.value("genre").toString().trimmed();
    track.insert("genre", genre.isEmpty() ? QString("Soundtrack") : genre);
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

QString jellyfinAuthHeader(const QString &deviceId, const QString &accessToken) {
    QString header = QString("MediaBrowser Client=\"%1\", Device=\"Desktop\", DeviceId=\"%2\", Version=\"%3\"")
                         .arg(kClientName, deviceId, kJellyfinVersion);
    if (!accessToken.isEmpty()) {
        header += QString(", Token=\"%1\"").arg(accessToken);
    }
    return header;
}

QVariantMap jellyfinTrackMap(const QJsonObject &item) {
    const QString id = item.value("Id").toString();
    const long long ticks = item.value("RunTimeTicks").toVariant().toLongLong();
    const int secs = static_cast<int>(ticks / 10000000LL);
    QVariantMap track;
    track.insert("filePath", "jellyfin:" + id);
    track.insert("fileName", item.value("Name").toString());
    track.insert("title", item.value("Name").toString());

    QString artist;
    const QJsonArray artistsArray = item.value("Artists").toArray();
    if (!artistsArray.isEmpty()) {
        QStringList names;
        for (const auto &val : artistsArray) {
            const QString n = val.toString().trimmed();
            if (!n.isEmpty())
                names << n;
        }
        artist = names.join(", ");
    }
    if (artist.isEmpty()) {
        const QJsonArray artistItems = item.value("ArtistItems").toArray();
        if (!artistItems.isEmpty()) {
            QStringList names;
            for (const auto &val : artistItems) {
                const QString n = val.toObject().value("Name").toString().trimmed();
                if (!n.isEmpty())
                    names << n;
            }
            artist = names.join(", ");
        }
    }
    if (artist.isEmpty()) {
        artist = item.value("AlbumArtist").toString().trimmed();
    }
    if (artist.isEmpty()) {
        artist = "Unknown Artist";
    }
    track.insert("artist", artist);

    const QString album = item.value("Album").toString().trimmed();
    track.insert("album", album.isEmpty() ? QString("Unknown Album") : album);

    const QJsonArray genres = item.value("Genres").toArray();
    track.insert("genre", genres.isEmpty() ? QString("Soundtrack") : genres.first().toString().trimmed());

    track.insert("durationSeconds", secs);
    track.insert("duration", formatTrackDuration(secs));

    QString container = item.value("Container").toString().toUpper();
    if (container.contains("M4A") || container.contains("AAC") || container.contains("MP4"))
        container = "M4A";
    else if (container.contains("FLAC"))
        container = "FLAC";
    else if (container.contains("MP3"))
        container = "MP3";
    else if (container.contains("OPUS"))
        container = "OPUS";
    else if (container.contains("OGG"))
        container = "OGG";
    else if (container.contains("WAV"))
        container = "WAV";
    else if (container.contains("ALAC"))
        container = "ALAC";
    else if (container.contains(","))
        container = container.section(',', 0, 0).trimmed();
    track.insert("format", container.isEmpty() ? QString("AUDIO") : container);

    track.insert("source", QString("jellyfin"));
    track.insert("remoteId", id);
    track.insert("isFavorite", item.value("UserData").toObject().value("IsFavorite").toBool(false));

    const QJsonObject imageTags = item.value("ImageTags").toObject();
    const bool hasPrimary = imageTags.contains("Primary") && !imageTags.value("Primary").isNull();
    const QString albumId = item.value("AlbumId").toString();
    const QString albumTag = item.value("AlbumPrimaryImageTag").toString();
    QString artId;
    if (hasPrimary) {
        artId = id;
    } else if (!albumId.isEmpty() && !albumTag.isEmpty()) {
        artId = albumId;
    } else if (!albumId.isEmpty()) {
        artId = albumId;
    }
    track.insert("remoteArtId", artId);
    return track;
}

} // namespace streaming::protocol
