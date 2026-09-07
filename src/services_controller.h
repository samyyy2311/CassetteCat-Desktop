#pragma once

#include <QHash>
#include <QList>
#include <QNetworkAccessManager>
#include <QObject>
#include <QPointer>
#include <QSet>
#include <QString>
#include <QVariantList>

class QNetworkReply;
class QSettings;

namespace services::detail {
inline constexpr int requestTimeoutMs = 15'000;
}

class ServicesController : public QObject
{
    Q_OBJECT
public:
    explicit ServicesController(QObject *parent = nullptr);
    static bool selfCheck();

    Q_INVOKABLE QString getArtistImage(const QString &artist) const;
    Q_INVOKABLE QString localLyricsFor(const QString &filePath) const;
    Q_INVOKABLE void cacheLyrics(const QString &title, const QString &artist, const QString &album, const QString &syncedLyrics, const QString &plainLyrics, const QString &provider);
    Q_INVOKABLE void fetchLyrics(const QString &title, const QString &artist, const QString &album, int durationSeconds);
    Q_INVOKABLE void searchLyrics(const QString &title, const QString &artist);
    Q_INVOKABLE void fetchRadioStations(const QString &searchQuery = "", const QString &country = "", const QString &language = "", const QString &tag = "", const QString &sort = "votes", bool reverse = true);
    Q_INVOKABLE void cancelRadioRequests();
    Q_INVOKABLE void cancelNetworkRequests();
    Q_INVOKABLE void setBlackoutEnabled(bool enabled);
    Q_INVOKABLE void fetchArtistBio(const QString &artist);
    Q_INVOKABLE void fetchArtistImage(const QString &artist);
    Q_INVOKABLE void openExternalUrl(const QString &url);

signals:
    void lyricsFetched(const QString &title, const QString &artist, const QString &lyrics, const QString &provider);
    void lyricsSearchResultsReady(const QVariantList &results);
    void radioStationsLoaded(const QVariantList &stations);
    void artistBioLoaded(const QString &artist, const QString &bio);
    void artistImageLoaded(const QString &artist, const QString &imageUrl);

private:
    static QString lyricsCacheKey(const QString &title, const QString &artist, const QString &album);
    static QString canonicalArtistName(const QString &artist);
    static bool serviceEnabled(const QSettings &settings, const QString &service);
    bool onlineEnabled() const;
    bool serviceEnabled(const QString &service) const;
    QNetworkReply *trackReply(QNetworkReply *reply);
    void publishArtistImage(const QString &artist, const QString &imageUrl);
    void downloadArtistImage(const QString &artist, const QString &imageUrl, const QString &service);
    void fetchArtistImageFromAudioDb(const QString &artist);
    void fetchArtistBioFromWikipedia(const QString &artist, const QStringList &queries, int index);
    void fetchArtistBioFromAudioDb(const QString &artist);

    QNetworkAccessManager *m_net = nullptr;
    QHash<QString, QString> m_artistImages;
    QSet<QString> m_artistImagePending;
    QPointer<QNetworkReply> m_radioReply;
    QList<QPointer<QNetworkReply>> m_pendingReplies;
    int m_radioRequestToken = 0;
    quint64 m_lyricsRequestToken = 0;
};
