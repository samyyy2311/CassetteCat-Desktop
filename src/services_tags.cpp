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
    m_nextMusicBrainzRequestMs += 1000;
    return delayMs;
}

QVariantMap ServicesController::musicBrainzTagsFrom(const QJsonObject &search, const QVariantMap &track) {
    const qint64 lengthMs = track.value("durationSeconds").toLongLong() * 1000;
    const QString album = track.value("album").toString().trimmed();
    // MusicBrainz often has the same song as several recordings, so every one that fits is searched for its album:
    // the one the file already names, or else the earliest studio album, where the song first came out.
    QJsonObject firstRecording, namedRecording, namedRelease, studioRecording, studioRelease;
    for (const QJsonValue &value : search[QStringLiteral("recordings")].toArray()) {
        const QJsonObject recording = value.toObject();
        const qint64 recordingMs = recording[QStringLiteral("length")].toInteger();
        if (recording[QStringLiteral("score")].toInt() < kMinimumScore ||
            (lengthMs > 0 && recordingMs > 0 && std::llabs(recordingMs - lengthMs) > kLengthToleranceMs))
            continue;
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
    if (!onlineEnabled() || !serviceEnabled("archive") || title.isEmpty()) {
        emit musicBrainzTagsReady(filePath, {}, false);
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
    QTimer::singleShot(nextMusicBrainzSlotMs(), this, [this, request, track, filePath] {
        if (!onlineEnabled()) {
            emit musicBrainzTagsReady(filePath, {}, false);
            return;
        }
        auto *reply = trackReply(m_net->get(request));
        connect(reply, &QNetworkReply::finished, this, [this, reply, track, filePath] {
            reply->deleteLater();
            const bool reached = reply->error() == QNetworkReply::NoError;
            const QVariantMap tags =
                reached ? musicBrainzTagsFrom(QJsonDocument::fromJson(reply->readAll()).object(), track)
                        : QVariantMap();
            emit musicBrainzTagsReady(filePath, tags, reached);
        });
    });
}
