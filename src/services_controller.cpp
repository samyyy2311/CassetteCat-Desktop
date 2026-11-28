#include "services_controller.h"

#include "app_paths.h"
#include "app_settings.h"
#include "image_cache.h"
#include "lyrics_store.h"
#include "network_requests.h"
#include "self_check.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSet>
#include <QSettings>
#include <QStringList>
#include <QTemporaryDir>
#include <QUrlQuery>

#include <algorithm>

QNetworkRequest services::detail::request(const QUrl &url) {
    QNetworkRequest request(url);
    request.setTransferTimeout(requestTimeoutMs);
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      QStringLiteral("CassetteCat/%1 (https://github.com/samyyy2311/CassetteCat-Desktop)")
                          .arg(QCoreApplication::applicationVersion()));
    return request;
}

ServicesController::ServicesController(QObject *parent) : QObject(parent), m_net(new QNetworkAccessManager(this)) {
    lyrics::moveFromSettings();
    QSettings s(settingsFilePath(), QSettings::IniFormat);
    s.beginGroup("artist_images");
    for (const QString &key : s.childKeys()) {
        const QString imageUrl = s.value(key).toString();
        if (imageUrl.startsWith("http://", Qt::CaseInsensitive) ||
            imageUrl.startsWith("https://", Qt::CaseInsensitive)) {
            m_artistImages.insert(key, imageUrl);
        } else if (QUrl(imageUrl).isLocalFile() && QFileInfo::exists(QUrl(imageUrl).toLocalFile())) {
            m_artistImages.insert(key, imageUrl);
        }
    }
    s.endGroup();
}

bool ServicesController::onlineEnabled() const {
    return !SettingsController::globalValue("network/offlineBlackout", false).toBool();
}

bool ServicesController::serviceEnabled(const QString &service) const {
    return SettingsController::globalValue("services/" + service, true).toBool();
}

bool ServicesController::serviceEnabled(const QSettings &settings, const QString &service) {
    return settings.value("services/" + service, true).toBool();
}

bool ServicesController::selfCheck() {
    SelfCheck check("Services");
    const QVariantList notes = releaseNotesFrom(
        QStringLiteral("## [1.1.0]\n* First.\n### Lyrics\n* **Lyrics**: synced.\n* `Faster`.\n### Empty\n\n---\n\n"
                       "## [1.0.0]\n* Old.\n"),
        QStringLiteral("1.1.0"));
    check.expect(
        notes == QVariantList{QVariantMap{{"title", QString()}, {"notes", QStringList{"First."}}},
                              QVariantMap{{"title", "Lyrics"}, {"notes", QStringList{"Lyrics: synced.", "Faster."}}}},
        "release notes keep their parts");
    class PendingReply final : public QNetworkReply {
      public:
        void abort() override {
            setFinished(true);
            emit finished();
        }

      protected:
        qint64 readData(char *, qint64) override {
            return -1;
        }
    };

    ServicesController services;
    QTemporaryDir settingsDir;
    check.expect(settingsDir.isValid(), "makes a settings folder");
    QSettings serviceSettings(settingsDir.filePath("settings.ini"), QSettings::IniFormat);
    serviceSettings.setValue("services/deezer", false);
    check.expect(!serviceEnabled(serviceSettings, "deezer"), "turns a service off");
    check.expect(serviceEnabled(serviceSettings, "wiki"), "leaves other services on");
    check.expect(serviceEnabled(serviceSettings, "archive"), "starts with services on");

    PendingReply replies[8];
    for (auto &reply : replies)
        services.trackReply(&reply);
    services.m_radioReply = &replies[0];
    const auto running = [](const PendingReply &reply) { return reply.isRunning(); };
    const auto finished = [](const PendingReply &reply) { return reply.isFinished(); };
    services.setBlackoutEnabled(false);
    check.expect(std::all_of(std::begin(replies), std::end(replies), running),
                 "leaves requests running outside blackout");
    services.cancelRadioRequests();
    check.expect(replies[0].isFinished(), "cancels the radio request");
    check.expect(!services.m_radioReply, "forgets the cancelled radio request");
    check.expect(std::all_of(std::begin(replies) + 1, std::end(replies), running), "leaves other requests running");
    services.setBlackoutEnabled(true);
    check.expect(std::all_of(std::begin(replies), std::end(replies), finished), "cancels every request in blackout");
    services.setBlackoutEnabled(true);
    check.expect(services.m_pendingReplies.isEmpty(), "forgets cancelled requests");

    // A 3:20 song: the 4:00 live recording is skipped, and the original 1999 album beats a later compilation.
    const QJsonObject search = QJsonDocument::fromJson(R"json({"recordings": [
        {"score": 100, "title": "Song (Live)", "length": 240000, "artist-credit": [{"name": "Band"}],
         "releases": [{"title": "Live", "status": "Official", "media": [{"position": 1, "track": [{"number": "1"}]}]}]},
        {"score": 98, "title": "Song", "length": 201000,
         "artist-credit": [{"name": "Band", "joinphrase": " feat. "}, {"name": "Singer"}],
         "releases": [
            {"title": "Greatest Hits", "status": "Official", "date": "2005",
             "release-group": {"primary-type": "Album", "secondary-types": ["Compilation"]},
             "media": [{"position": 1, "track": [{"number": "12"}]}]},
            {"title": "First Album", "status": "Official", "date": "2020",
             "release-group": {"primary-type": "Album"},
             "media": [{"position": 1, "track": [{"number": "4"}]}]},
            {"title": "First Album", "status": "Official", "date": "1999-03-01",
             "release-group": {"primary-type": "Album"},
             "media": [{"position": 2, "track": [{"number": "4"}]}]}]}]})json")
                                   .object();
    const QVariantMap expected{{"title", "Song"},        {"artist", "Band feat. Singer"},
                               {"album", "First Album"}, {"year", 1999},
                               {"trackNumber", 4},       {"discNumber", 2}};
    check.expect(musicBrainzTagsFrom(search, {{"durationSeconds", 200}}) == expected,
                 "picks the original album's MusicBrainz tags");
    check.expect(musicBrainzTagsFrom(search, {{"durationSeconds", 200}, {"album", "greatest hits"}}).value("album") ==
                     QStringLiteral("Greatest Hits"),
                 "keeps the album a file already names");
    check.expect(musicBrainzTagsFrom(search, {{"durationSeconds", 150}}).isEmpty(),
                 "skips recordings of another length");
    // A file already naming the album still gets the original's year, not a reissue's.
    check.expect(musicBrainzTagsFrom(search, {{"durationSeconds", 200}, {"album", "first album"}}).value("year") ==
                     1999,
                 "takes the original's year");
    // With only a compilation to go on, the album is left alone.
    check.expect(musicBrainzTagsFrom(search, {{"durationSeconds", 240}}) ==
                     QVariantMap{{"title", "Song (Live)"}, {"artist", "Band"}},
                 "leaves the album alone without an original");

    const auto loved = [](const char *json) { return QJsonDocument::fromJson(json).object(); };
    const std::optional<LovedPage> two =
        lovedTracksPage(loved(R"({"lovedtracks": {"track": [{"name": "One", "artist": {"name": "A"}},
                  {"name": "Two", "artist": {"name": "B"}}], "@attr": {"totalPages": "3"}}})"));
    check.expect(two && two->songs.size() == 2 && two->total == 3, "reads a page of loved songs");
    const std::optional<LovedPage> solo = lovedTracksPage(loved(
        R"({"lovedtracks": {"track": {"name": "Solo", "artist": {"name": "C"}}, "@attr": {"totalPages": "1"}}})"));
    check.expect(solo && solo->songs.size() == 1, "reads a page holding one loved song");
    check.expect(!lovedTracksPage(loved(R"({"error": 6, "message": "User not found"})")),
                 "turns down an error instead of an empty list");
    const std::optional<LovedPage> feedback =
        feedbackPage(loved(R"({"feedback": [{"track_metadata": {"artist_name": "A", "track_name": "One"}},
                  {"track_metadata": null}], "total_count": 1500})"));
    check.expect(feedback && feedback->songs.size() == 1 && feedback->total == 1500,
                 "reads ListenBrainz loves, skipping recordings without details");

    check.expect(compareVersions("0.6.1", "0.6.0") > 0, "orders a newer patch version");
    check.expect(compareVersions("0.6.0", "0.6.0") == 0, "matches the same version");
    check.expect(compareVersions("0.5.1", "0.6.0") < 0, "orders an older minor version");
    check.expect(compareVersions("v1.0.0", "0.9.9") > 0, "ignores a leading v");
    return check.passed();
}

QNetworkReply *ServicesController::trackReply(QNetworkReply *reply) {
    m_pendingReplies.append(reply);
    connect(reply, &QNetworkReply::finished, this, [this, reply] { m_pendingReplies.removeAll(reply); });
    return reply;
}

namespace {
QUrlQuery radioQuery(const QString &searchQuery, const QString &country, const QString &language, const QString &tag,
                     const QString &sort, bool reverse) {
    QUrlQuery q;
    const QString normalizedSort =
        QStringList{"votes", "clicktrend", "name", "country", "bitrate"}.contains(sort) ? sort : "votes";
    q.addQueryItem("order", normalizedSort);
    q.addQueryItem("reverse", reverse ? "true" : "false");
    q.addQueryItem("lastcheckok", "1");
    q.addQueryItem("limit", "80");
    const std::pair<const char *, QString> filters[] = {
        {"name", searchQuery}, {"country", country}, {"language", language}, {"tag", tag}};
    for (const auto &[name, value] : filters) {
        if (!value.trimmed().isEmpty())
            q.addQueryItem(name, value.trimmed());
    }
    return q;
}

// Stations without a working stream address are left out.
QVariantList radioStationsFrom(const QJsonArray &results) {
    QVariantList stations;
    for (const auto &value : results) {
        const auto obj = value.toObject();
        const QString streamUrl = obj.value("url_resolved").toString();
        if (streamUrl.isEmpty())
            continue;
        stations.append(QVariantMap{{"id", obj.value("stationuuid").toString()},
                                    {"name", obj.value("name").toString()},
                                    {"streamUrl", streamUrl},
                                    {"favicon", obj.value("favicon").toString()},
                                    {"tags", obj.value("tags").toString()},
                                    {"country", obj.value("country").toString()},
                                    {"language", obj.value("language").toString()},
                                    {"bitrate", obj.value("bitrate").toInt()}});
    }
    return stations;
}
} // namespace

void ServicesController::fetchRadioStations(const QString &searchQuery, const QString &country, const QString &language,
                                            const QString &tag, const QString &sort, bool reverse) {
    if (!onlineEnabled() || !serviceEnabled("radio"))
        return;
    cancelRadioRequests();
    const int requestToken = m_radioRequestToken;
    QUrl url("https://de1.api.radio-browser.info/json/stations/search");
    url.setQuery(radioQuery(searchQuery, country, language, tag, sort, reverse));

    auto *reply = trackReply(m_net->get(services::detail::request(url)));
    m_radioReply = reply;
    connect(reply, &QNetworkReply::finished, this, [this, reply, requestToken]() {
        if (reply == m_radioReply)
            m_radioReply = nullptr;
        reply->deleteLater();
        if (!onlineEnabled() || !serviceEnabled("radio") || requestToken != m_radioRequestToken)
            return;
        if (reply->error() != QNetworkReply::NoError)
            return;
        const auto doc = QJsonDocument::fromJson(reply->readAll());
        if (doc.isArray())
            emit radioStationsLoaded(radioStationsFrom(doc.array()));
    });
}

void ServicesController::cancelRadioRequests() {
    ++m_radioRequestToken;
    if (m_radioReply && m_radioReply->isRunning())
        m_radioReply->abort();
    m_radioReply = nullptr;
}

void ServicesController::cancelNetworkRequests() {
    ++m_lyricsRequestToken;
    cancelRadioRequests();
    cancelNetworkReplies(m_pendingReplies);
}

void ServicesController::setBlackoutEnabled(bool enabled) {
    if (!enabled)
        return;
    cancelNetworkRequests();
}

void ServicesController::openExternalUrl(const QString &url) {
    if (!onlineEnabled())
        return;
    QDesktopServices::openUrl(QUrl(url));
}

int ServicesController::compareVersions(const QString &v1, const QString &v2) {
    const auto parseVersion = [](QString v) -> QList<int> {
        if (v.startsWith('v', Qt::CaseInsensitive))
            v = v.mid(1);
        const QStringList parts = v.split('.');
        QList<int> numbers;
        for (const QString &part : parts) {
            numbers.append(part.toInt());
        }
        while (numbers.size() < 3)
            numbers.append(0);
        return numbers;
    };
    const QList<int> nums1 = parseVersion(v1);
    const QList<int> nums2 = parseVersion(v2);
    const int count = qMax(nums1.size(), nums2.size());
    for (int i = 0; i < count; ++i) {
        const int n1 = i < nums1.size() ? nums1[i] : 0;
        const int n2 = i < nums2.size() ? nums2[i] : 0;
        if (n1 > n2)
            return 1;
        if (n1 < n2)
            return -1;
    }
    return 0;
}

QVariantList ServicesController::releaseNotes(const QString &version) const {
    QFile changelog(QStringLiteral(":/qt/qml/CassetteCat/CHANGELOG.md"));
    if (!changelog.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return releaseNotesFrom(QString::fromUtf8(changelog.readAll()), version);
}

// Each part of the version's notes, such as Lyrics or Fixes, as {title, notes}. Notes before any "### " heading go in
// an untitled part, and parts with no notes are left out.
QVariantList ServicesController::releaseNotesFrom(const QString &changelog, const QString &version) {
    QList<std::pair<QString, QStringList>> parts;
    bool inSection = false;
    for (const QString &line : changelog.split('\n')) {
        if (line.startsWith(QStringLiteral("## ["))) {
            if (inSection)
                break;
            inSection = line.startsWith(QStringLiteral("## [") + version + ']');
        } else if (inSection && line.startsWith(QStringLiteral("### "))) {
            parts.append({line.mid(4).trimmed(), {}});
        } else if (inSection && line.startsWith(QStringLiteral("* "))) {
            if (parts.isEmpty())
                parts.append({QString(), {}});
            parts.last().second.append(line.mid(2).remove(QStringLiteral("**")).remove(u'`').trimmed());
        }
    }
    QVariantList sections;
    for (const auto &[title, notes] : parts) {
        if (!notes.isEmpty())
            sections.append(QVariantMap{{"title", title}, {"notes", notes}});
    }
    return sections;
}

void ServicesController::checkForUpdates(bool manual) {
    if (!onlineEnabled()) {
        if (manual) {
            emit updateCheckFailed(tr("Offline blackout is enabled."), manual);
        }
        return;
    }

    const QUrl url(QStringLiteral("https://api.github.com/repos/samyyy2311/CassetteCat-Desktop/releases/latest"));
    QNetworkRequest request = services::detail::request(url);
    request.setRawHeader("Accept", "application/vnd.github.v3+json");

    QNetworkReply *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, manual]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit updateCheckFailed(reply->errorString(), manual);
            return;
        }

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isObject()) {
            emit updateCheckFailed(tr("Invalid response from GitHub."), manual);
            return;
        }

        const QJsonObject root = doc.object();
        QString tag = root.value(QStringLiteral("tag_name")).toString();
        const QString releaseUrl = root.value(QStringLiteral("html_url")).toString();
        const QString body = root.value(QStringLiteral("body")).toString();

        if (tag.startsWith('v', Qt::CaseInsensitive)) {
            tag = tag.mid(1);
        }

        const bool updateAvailable = compareVersions(tag, QCoreApplication::applicationVersion()) > 0;
        emit updateCheckFinished(updateAvailable, tag, releaseUrl, body, manual);
    });
}
