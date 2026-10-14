#include "services_controller.h"

#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>
#include <QUrlQuery>

#include <cstdlib>

namespace {
// A recording this much longer or shorter than the file is another version, such as a live take or a radio edit.
constexpr qint64 kLengthToleranceMs = 3000;
constexpr int kMinimumScore = 90;

QString quotedTerm(QString value) {
    value.replace('\\', QStringLiteral("\\\\")).replace('"', QStringLiteral("\\\""));
    return '"' + value.trimmed() + '"';
}

QString creditedArtist(const QJsonArray &credits) {
    QString artist;
    for (const QJsonValue &credit : credits)
        artist += credit[QStringLiteral("name")].toString() + credit[QStringLiteral("joinphrase")].toString();
    return artist;
}

// Spelling that differs only in case, quote style or spacing reads the same.
QString comparableText(QString value) {
    value = value.toLower().simplified();
    value.replace(QChar(0x2018), '\'')
        .replace(QChar(0x2019), '\'')
        .replace(QChar(0x201c), '"')
        .replace(QChar(0x201d), '"');
    return value;
}

bool isStudioAlbum(const QJsonObject &release) {
    const QJsonObject group = release[QStringLiteral("release-group")].toObject();
    return release[QStringLiteral("status")].toString() == QStringLiteral("Official") &&
           group[QStringLiteral("primary-type")].toString() == QStringLiteral("Album") &&
           group[QStringLiteral("secondary-types")].toArray().isEmpty();
}

// Releases without a date sort last.
QString sortableDate(const QJsonObject &release) {
    const QString date = release[QStringLiteral("date")].toString();
    return date.isEmpty() ? QStringLiteral("9999") : date;
}
} // namespace

int ServicesController::nextMusicBrainzSlotMs() {
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    m_nextMusicBrainzRequestMs = qMax(now, m_nextMusicBrainzRequestMs);
    const int delayMs = int(m_nextMusicBrainzRequestMs - now);
    // MusicBrainz allows one request a second on average; a little more keeps clear of its limit.
    m_nextMusicBrainzRequestMs += 1100;
    return delayMs;
}

QVariantMap ServicesController::musicBrainzTagsFrom(const QJsonObject &search, const QVariantMap &track) {
    const qint64 lengthMs = track.value("durationSeconds").toLongLong() * 1000;
    const QString album = track.value("album").toString().trimmed();
    // MusicBrainz often has the same song as several recordings, so every one that fits is searched for its album:
    // the one the file already names, or else the earliest studio album, where the song first came out.
    QList<QJsonObject> confident;
    for (const QJsonValue &value : search[QStringLiteral("recordings")].toArray()) {
        const QJsonObject recording = value.toObject();
        const qint64 recordingMs = recording[QStringLiteral("length")].toInteger();
        if (recording[QStringLiteral("score")].toInt() >= kMinimumScore &&
            (lengthMs <= 0 || recordingMs <= 0 || std::llabs(recordingMs - lengthMs) <= kLengthToleranceMs))
            confident.append(recording);
    }
    // A recording with the file's own title wins over versions of it, such as a remix of the same length.
    const QString title = comparableText(track.value("title").toString());
    QList<QJsonObject> fitting;
    for (const QJsonObject &recording : confident)
        if (comparableText(recording[QStringLiteral("title")].toString()) == title)
            fitting.append(recording);
    if (fitting.isEmpty())
        fitting = confident;

    QJsonObject firstRecording, namedRecording, namedRelease, studioRecording, studioRelease;
    for (const QJsonObject &recording : fitting) {
        if (firstRecording.isEmpty())
            firstRecording = recording;
        for (const QJsonValue &releaseValue : recording[QStringLiteral("releases")].toArray()) {
            const QJsonObject release = releaseValue.toObject();
            // Of the releases with the file's album name, the earliest is the original rather than a reissue.
            if (!album.isEmpty() &&
                release[QStringLiteral("title")].toString().compare(album, Qt::CaseInsensitive) == 0 &&
                (namedRelease.isEmpty() || sortableDate(release) < sortableDate(namedRelease))) {
                namedRecording = recording;
                namedRelease = release;
            }
            if (isStudioAlbum(release) &&
                (studioRelease.isEmpty() || sortableDate(release) < sortableDate(studioRelease))) {
                studioRecording = recording;
                studioRelease = release;
            }
        }
    }
    if (firstRecording.isEmpty())
        return {};

    const bool named = !namedRelease.isEmpty();
    const QJsonObject recording = named ? namedRecording : studioRelease.isEmpty() ? firstRecording : studioRecording;
    const QJsonObject release = named ? namedRelease : studioRelease;
    QVariantMap tags{{"title", recording[QStringLiteral("title")].toString()},
                     {"artist", creditedArtist(recording[QStringLiteral("artist-credit")].toArray())}};
    // Without the file's album or a studio album, the release would be a guess, such as one of many compilations.
    if (release.isEmpty())
        return tags;
    const QJsonObject medium = release[QStringLiteral("media")].toArray().first().toObject();
    tags.insert("album", release[QStringLiteral("title")].toString());
    if (const QString releaseId = release[QStringLiteral("id")].toString(); !releaseId.isEmpty())
        tags.insert("releaseId", releaseId);
    if (const int year = release[QStringLiteral("date")].toString().left(4).toInt(); year > 0)
        tags.insert("year", year);
    const QJsonObject entry = medium[QStringLiteral("track")].toArray().first().toObject();
    if (const int number = entry[QStringLiteral("number")].toString().toInt(); number > 0)
        tags.insert("trackNumber", number);
    if (const int disc = medium[QStringLiteral("position")].toInt(); disc > 0)
        tags.insert("discNumber", disc);
    return tags;
}

void ServicesController::findMusicBrainzTags(const QVariantMap &track) {
    const QString filePath = track.value("filePath").toString();
    const QString title = track.value("title").toString().trimmed();
    if (title.isEmpty()) {
        emit musicBrainzTagsReady(filePath, {}, {});
        return;
    }
    if (!onlineEnabled() || !serviceEnabled("archive")) {
        emit musicBrainzTagsReady(filePath, {}, QStringLiteral("off"));
        return;
    }
    QString query = QStringLiteral("recording:") + quotedTerm(title);
    if (const QString artist = track.value("artist").toString().trimmed(); !artist.isEmpty())
        query += QStringLiteral(" AND artist:") + quotedTerm(artist);
    QUrl url(QStringLiteral("https://musicbrainz.org/ws/2/recording"));
    url.setQuery(QUrlQuery{{"fmt", "json"}, {"limit", "25"}, {"query", query}});

    QNetworkRequest request(url);
    request.setTransferTimeout(services::detail::requestTimeoutMs);
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");
    requestMusicBrainzTags(request, track, 0);
}

void ServicesController::requestMusicBrainzTags(const QNetworkRequest &request, const QVariantMap &track, int attempt) {
    const QString filePath = track.value("filePath").toString();
    QTimer::singleShot(nextMusicBrainzSlotMs(), this, [this, request, track, filePath, attempt] {
        // A retry can come after MusicBrainz or going online was turned off.
        if (!onlineEnabled() || !serviceEnabled("archive")) {
            emit musicBrainzTagsReady(filePath, {}, QStringLiteral("off"));
            return;
        }
        auto *reply = trackReply(m_net->get(request));
        connect(reply, &QNetworkReply::finished, this, [this, reply, request, track, filePath, attempt] {
            reply->deleteLater();
            if (reply->error() == QNetworkReply::NoError) {
                emit musicBrainzTagsReady(
                    filePath, musicBrainzTagsFrom(QJsonDocument::fromJson(reply->readAll()).object(), track), {});
                return;
            }
            const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            // Any other answer means this song can't be looked up, so the check moves on without it.
            if (status != 0 && status != 503) {
                qWarning().noquote() << "[MUSICBRAINZ] lookup refused status=" << status << reply->errorString();
                emit musicBrainzTagsReady(filePath, {}, {});
                return;
            }
            // MusicBrainz answers 503 when it's busy or asked too often, and no answer means the network dropped, so
            // either gets a few more tries, further apart.
            if (attempt < 3) {
                QTimer::singleShot(2000 * (attempt + 1), this, [this, request, track, attempt] {
                    requestMusicBrainzTags(request, track, attempt + 1);
                });
                return;
            }
            qWarning().noquote() << "[MUSICBRAINZ] lookup failed status=" << status << reply->errorString();
            emit musicBrainzTagsReady(filePath, {}, QStringLiteral("busy"));
        });
    });
}
