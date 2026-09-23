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
    /// Runs deterministic checks for service configuration and cancellation.
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
    Q_INVOKABLE void fetchAlbumBio(const QString &album, const QString &artist);
    Q_INVOKABLE void fetchArtistImage(const QString &artist);
    /// Opens \p url when online services are enabled.
    Q_INVOKABLE void openExternalUrl(const QString &url);
    Q_INVOKABLE void validateListenBrainzToken(const QString &token);
    Q_INVOKABLE void authenticateLibreFm(const QString &username, const QString &password);
    Q_INVOKABLE void scrobbleNowPlaying(const QVariantMap &track);
    Q_INVOKABLE void scrobbleTrack(const QVariantMap &track, qint64 timestampSec);
    Q_INVOKABLE void saveListenBrainzSession(const QString &token, const QString &userName);
    Q_INVOKABLE void disconnectListenBrainz();
    Q_INVOKABLE void saveLibreFmSession(const QString &username, const QString &sessionKey);
    Q_INVOKABLE void disconnectLibreFm();
    Q_INVOKABLE bool hasListenBrainzSession();
    Q_INVOKABLE bool hasLibreFmSession();
    /// Searches enabled artwork providers for matching album covers.
    Q_INVOKABLE void searchAlbumCovers(const QString &album, const QString &artist = "");
    /// Downloads and caches \p imageUrl as album artwork.
    Q_INVOKABLE void applyAlbumCover(const QString &album, const QString &artist, const QString &imageUrl, const QString &filePath = "");
    /// Queries the latest release and emits the resulting update status.
    Q_INVOKABLE void checkForUpdates(bool manual = false);
    /// Compares dotted release versions, returning their relative order.
    static int compareVersions(const QString &v1, const QString &v2);

signals:
    void lyricsFetched(const QString &title, const QString &artist, const QString &lyrics, const QString &provider);
    void lyricsSearchResultsReady(const QVariantList &results);
    void coverSearchResultsReady(const QVariantList &results);
    void coverSearchFailed(const QString &error);
    void coverApplied(const QString &album, const QString &artist, const QString &artworkPath, const QString &filePath);
    void radioStationsLoaded(const QVariantList &stations);
    void artistBioLoaded(const QString &artist, const QString &bio);
    void albumBioLoaded(const QString &album, const QString &bio);
    void artistImageLoaded(const QString &artist, const QString &imageUrl);
    void listenBrainzValidationFinished(bool valid, const QString &userName, const QString &error);
    void libreFmAuthFinished(bool success, const QString &userName, const QString &sessionKey, const QString &error);
    /// Announces the result of a completed update check.
    void updateCheckFinished(bool updateAvailable, const QString &latestVersion, const QString &releaseUrl, const QString &releaseNotes, bool manual);
    /// Announces that an update check failed with \p error.
    void updateCheckFailed(const QString &error, bool manual);

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
    void fetchAlbumBioFromWikipedia(const QString &album, const QStringList &queries, int index);
    void initScrobbleCredentials();
    static QString generateLibreFmApiSig(const QMap<QString, QString> &params);

    QNetworkAccessManager *m_net = nullptr;
    QHash<QString, QString> m_artistImages;
    QSet<QString> m_artistImagePending;
    QPointer<QNetworkReply> m_radioReply;
    QList<QPointer<QNetworkReply>> m_pendingReplies;
    int m_radioRequestToken = 0;
    quint64 m_lyricsRequestToken = 0;
    quint64 m_coverRequestToken = 0;
    QString m_listenBrainzToken;
    QString m_libreFmSessionKey;
    bool m_scrobbleCredentialsLoaded = false;
};
