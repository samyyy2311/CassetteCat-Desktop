#include "streaming_protocols.h"

#include <QCryptographicHash>
#include <QHostAddress>
#include <QJsonDocument>
#include <QRandomGenerator>
#include <QUrlQuery>

#include <algorithm>

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

// Names a home network answers for itself, so they never reach the internet's DNS.
bool isLocalName(const QString &host) {
    static const QStringList localSuffixes{".local", ".lan", ".home.arpa", ".internal", ".localdomain"};
    return host.compare("localhost", Qt::CaseInsensitive) == 0 ||
           std::any_of(localSuffixes.cbegin(), localSuffixes.cend(),
                       [&](const QString &suffix) { return host.endsWith(suffix, Qt::CaseInsensitive); });
}

bool isPrivateIpv4(quint32 ipv4) {
    const quint8 first = static_cast<quint8>(ipv4 >> 24);
    const quint8 second = static_cast<quint8>((ipv4 >> 16) & 0xff);
    // 100.64.0.0/10 isn't counted: Tailscale uses it, but so do mobile carriers, so it may not be the user's
    // network.
    return first == 10 || (first == 172 && second >= 16 && second <= 31) || (first == 192 && second == 168) ||
           (first == 169 && second == 254);
}

// Unique local (fc00::/7) and link-local (fe80::/10) addresses.
bool isPrivateIpv6(const Q_IPV6ADDR &ipv6) {
    return (ipv6.c[0] & 0xfe) == 0xfc || (ipv6.c[0] == 0xfe && (ipv6.c[1] & 0xc0) == 0x80);
}

bool isPrivateOrLocalHost(const QString &host) {
    const QString value = host.trimmed();
    if (value.isEmpty()) {
        return false;
    }
    if (isLocalName(value)) {
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
    return isIpv4 ? isPrivateIpv4(ipv4) : isPrivateIpv6(address.toIPv6Address());
}

QString withoutTrailingSlashes(QString url) {
    while (url.endsWith('/')) {
        url.chop(1);
    }
    return url;
}

// A bare http(s) server address: nothing but a scheme, host, port and path.
bool isBareServerUrl(const QUrl &url) {
    const bool web = url.scheme().compare("http", Qt::CaseInsensitive) == 0 ||
                     url.scheme().compare("https", Qt::CaseInsensitive) == 0;
    return url.isValid() && !url.host().isEmpty() && web && url.userInfo().isEmpty() && !url.hasQuery() &&
           !url.hasFragment();
}

QString hostFromUnschemedUrl(const QString &value) {
    return QUrl("http://" + value).host();
}

} // namespace

bool isUnencryptedPublicUrl(const QString &raw) {
    const QUrl url(normalizeServerUrl(raw));
    return url.scheme().compare("http", Qt::CaseInsensitive) == 0 && !isPrivateOrLocalHost(url.host());
}

QString normalizeServerUrl(const QString &raw, int defaultPort) {
    QString url = withoutTrailingSlashes(raw.trimmed());
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
    if (!isBareServerUrl(parsed)) {
        return {};
    }
    if (defaultPort <= 0 || parsed.port() != -1 || !isPrivateOrLocalHost(parsed.host())) {
        return withoutTrailingSlashes(parsed.toString());
    }
    QUrl withPort(parsed);
    withPort.setPort(defaultPort);
    return withoutTrailingSlashes(withPort.toString());
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

namespace {
QString joinedNames(const QJsonArray &values, const QString &field = {}) {
    QStringList names;
    for (const QJsonValue &value : values) {
        const QString name = (field.isEmpty() ? value.toString() : value.toObject().value(field).toString()).trimmed();
        if (!name.isEmpty())
            names << name;
    }
    return names.join(", ");
}

// Jellyfin lists artists as names in Artists and as objects in ArtistItems, and either may be missing.
QString jellyfinArtist(const QJsonObject &item) {
    for (const QString &artist :
         {joinedNames(item.value("Artists").toArray()), joinedNames(item.value("ArtistItems").toArray(), "Name"),
          item.value("AlbumArtist").toString().trimmed()}) {
        if (!artist.isEmpty())
            return artist;
    }
    return QStringLiteral("Unknown Artist");
}

// Maps Jellyfin's container names, which can list several, to the formats the library shows.
QString jellyfinFormat(const QString &rawContainer) {
    const QString container = rawContainer.toUpper();
    static const std::pair<const char *, const char *> known[] = {
        {"M4A", "M4A"},   {"AAC", "M4A"}, {"MP4", "M4A"}, {"FLAC", "FLAC"}, {"MP3", "MP3"},
        {"OPUS", "OPUS"}, {"OGG", "OGG"}, {"WAV", "WAV"}, {"ALAC", "ALAC"},
    };
    for (const auto &[part, format] : known) {
        if (container.contains(part))
            return format;
    }
    const QString first = container.section(',', 0, 0).trimmed();
    return first.isEmpty() ? QStringLiteral("AUDIO") : first;
}
} // namespace

QVariantMap jellyfinTrackMap(const QJsonObject &item) {
    const QString id = item.value("Id").toString();
    const long long ticks = item.value("RunTimeTicks").toVariant().toLongLong();
    const int secs = static_cast<int>(ticks / 10000000LL);
    QVariantMap track;
    track.insert("filePath", "jellyfin:" + id);
    track.insert("fileName", item.value("Name").toString());
    track.insert("title", item.value("Name").toString());

    track.insert("artist", jellyfinArtist(item));

    const QString album = item.value("Album").toString().trimmed();
    track.insert("album", album.isEmpty() ? QString("Unknown Album") : album);

    const QJsonArray genres = item.value("Genres").toArray();
    track.insert("genre", genres.isEmpty() ? QString("Soundtrack") : genres.first().toString().trimmed());

    track.insert("durationSeconds", secs);
    track.insert("duration", formatTrackDuration(secs));

    track.insert("format", jellyfinFormat(item.value("Container").toString()));

    track.insert("source", QString("jellyfin"));
    track.insert("remoteId", id);
    track.insert("isFavorite", item.value("UserData").toObject().value("IsFavorite").toBool(false));

    // A song without its own picture shows its album's.
    const QJsonObject imageTags = item.value("ImageTags").toObject();
    const bool hasPrimary = imageTags.contains("Primary") && !imageTags.value("Primary").isNull();
    track.insert("remoteArtId", hasPrimary ? id : item.value("AlbumId").toString());
    return track;
}

} // namespace streaming::protocol
