#include "services_controller.h"

#include "app_paths.h"
#include "image_cache.h"
#include "network_requests.h"

#include <QCryptographicHash>
#include <QDesktopServices>
#include <QDir>
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

ServicesController::ServicesController(QObject *parent)
    : QObject(parent), m_net(new QNetworkAccessManager(this))
{
    QSettings s(settingsFilePath(), QSettings::IniFormat);
    s.beginGroup("artist_images");
    for (const QString &key : s.childKeys()) {
        const QString imageUrl = s.value(key).toString();
        if (QUrl(imageUrl).isLocalFile() && QFileInfo::exists(QUrl(imageUrl).toLocalFile())) {
            m_artistImages.insert(key, imageUrl);
        }
    }
    s.endGroup();
}

bool ServicesController::onlineEnabled() const
{
    QSettings settings(settingsFilePath(), QSettings::IniFormat);
    return !settings.value("network/offlineBlackout", false).toBool();
}

bool ServicesController::serviceEnabled(const QString &service) const
{
    QSettings settings(settingsFilePath(), QSettings::IniFormat);
    return serviceEnabled(settings, service);
}

bool ServicesController::serviceEnabled(const QSettings &settings, const QString &service)
{
    return settings.value("services/" + service, true).toBool();
}

bool ServicesController::selfCheck()
{
    class PendingReply final : public QNetworkReply {
    public:
        void abort() override {
            setFinished(true);
            emit finished();
        }
    protected:
        qint64 readData(char *, qint64) override { return -1; }
    };

    ServicesController services;
    QTemporaryDir settingsDir;
    if (!settingsDir.isValid()) return false;
    QSettings serviceSettings(settingsDir.filePath("settings.ini"), QSettings::IniFormat);
    serviceSettings.setValue("services/deezer", false);
    if (serviceEnabled(serviceSettings, "deezer") || !serviceEnabled(serviceSettings, "wiki")) return false;

    PendingReply replies[8];
    for (auto &reply : replies) services.trackReply(&reply);
    services.m_radioReply = &replies[0];

    services.setBlackoutEnabled(false);
    for (const auto &reply : replies) {
        if (!reply.isRunning()) return false;
    }

    services.cancelRadioRequests();
    if (!replies[0].isFinished() || services.m_radioReply) return false;
    for (int i = 1; i < 8; ++i) {
        if (!replies[i].isRunning()) return false;
    }

    services.setBlackoutEnabled(true);
    for (const auto &reply : replies) {
        if (!reply.isFinished()) return false;
    }
    services.setBlackoutEnabled(true);
    return services.m_pendingReplies.isEmpty();
}

QNetworkReply *ServicesController::trackReply(QNetworkReply *reply)
{
    m_pendingReplies.append(reply);
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        m_pendingReplies.removeAll(reply);
    });
    return reply;
}

void ServicesController::fetchRadioStations(const QString &searchQuery, const QString &country, const QString &language, const QString &tag, const QString &sort, bool reverse)
{
        if (!onlineEnabled() || !serviceEnabled("radio")) return;
        cancelRadioRequests();
        const int requestToken = m_radioRequestToken;
        QUrl url("https://de1.api.radio-browser.info/json/stations/search");
        QUrlQuery q;
        const QString normalizedSort = QStringList{"votes", "clicktrend", "name", "country", "bitrate"}.contains(sort) ? sort : "votes";
        q.addQueryItem("order", normalizedSort);
        q.addQueryItem("reverse", reverse ? "true" : "false");
        q.addQueryItem("lastcheckok", "1");
        q.addQueryItem("limit", "80");
        if (!searchQuery.trimmed().isEmpty()) {
            q.addQueryItem("name", searchQuery.trimmed());
        }
        if (!country.trimmed().isEmpty()) q.addQueryItem("country", country.trimmed());
        if (!language.trimmed().isEmpty()) q.addQueryItem("language", language.trimmed());
        if (!tag.trimmed().isEmpty()) q.addQueryItem("tag", tag.trimmed());
        url.setQuery(q);

        QNetworkRequest req(url);
        req.setTransferTimeout(services::detail::requestTimeoutMs);
        req.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");

        auto *reply = trackReply(m_net->get(req));
        m_radioReply = reply;
        connect(reply, &QNetworkReply::finished, this, [this, reply, requestToken]() {
            if (reply == m_radioReply) m_radioReply = nullptr;
            reply->deleteLater();
            if (!onlineEnabled() || !serviceEnabled("radio")) return;
            if (requestToken != m_radioRequestToken) return;
            if (reply->error() == QNetworkReply::NoError) {
                const auto doc = QJsonDocument::fromJson(reply->readAll());
                if (doc.isArray()) {
                    QVariantList stations;
                    const auto arr = doc.array();
                    for (const auto &v : arr) {
                        const auto obj = v.toObject();
                        const QString streamUrl = obj.value("url_resolved").toString();
                        if (streamUrl.isEmpty()) continue;

                        QVariantMap s;
                        s["id"] = obj.value("stationuuid").toString();
                        s["name"] = obj.value("name").toString();
                        s["streamUrl"] = streamUrl;
                        s["favicon"] = obj.value("favicon").toString();
                        s["tags"] = obj.value("tags").toString();
                        s["country"] = obj.value("country").toString();
                        s["language"] = obj.value("language").toString();
                        s["bitrate"] = obj.value("bitrate").toInt();
                        stations.append(s);
                    }
                    emit radioStationsLoaded(stations);
                }
            }
        });
    }

void ServicesController::cancelRadioRequests()
{
        ++m_radioRequestToken;
        if (m_radioReply && m_radioReply->isRunning()) m_radioReply->abort();
        m_radioReply = nullptr;
}

void ServicesController::cancelNetworkRequests()
{
        ++m_lyricsRequestToken;
        cancelRadioRequests();
        cancelNetworkReplies(m_pendingReplies);
}

void ServicesController::setBlackoutEnabled(bool enabled)
{
        if (!enabled) return;
        cancelNetworkRequests();
}

void ServicesController::openExternalUrl(const QString &url)
{
        if (!onlineEnabled()) return;
        QDesktopServices::openUrl(QUrl(url));
    }

