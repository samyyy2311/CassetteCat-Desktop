#pragma once

#include <QHash>
#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QObject>
#include <QPointer>
#include <QSet>
#include <QString>
#include <QVariantList>

#include <functional>
#include <optional>

class QNetworkReply;
class QSettings;

namespace services::detail {
inline constexpr int requestTimeoutMs = 15'000;
// MusicBrainz and LRCLIB ask callers to name the app and a way to reach its authors.
QNetworkRequest request(const QUrl &url);
} // namespace services::detail

class ServicesController : public QObject {
    Q_OBJECT
    /// Why ListenBrainz last refused a listen, in its own words; empty once one goes through.
    Q_PROPERTY(QString listenBrainzProblem READ listenBrainzProblem NOTIFY listenBrainzProblemChanged)
    /// Library-wide lyrics fetch progress.
    Q_PROPERTY(int libraryLyricsFound READ libraryLyricsFound NOTIFY libraryLyricsChanged)
    Q_PROPERTY(int libraryLyricsTotal READ libraryLyricsTotal NOTIFY libraryLyricsChanged)
    Q_PROPERTY(int libraryLyricsLeft READ libraryLyricsLeft NOTIFY libraryLyricsChanged)
    /// Loves still waiting to be sent.
    Q_PROPERTY(int lovesLeft READ lovesLeft NOTIFY lovesChanged)

  public:
    explicit ServicesController(QObject *parent = nullptr);
    /// Runs deterministic checks for service configuration and cancellation.
    static bool selfCheck();

    Q_INVOKABLE QString getArtistImage(const QString &artist) const;
    Q_INVOKABLE QString localLyricsFor(const QString &filePath) const;
    Q_INVOKABLE void cacheLyrics(const QString &title, const QString &artist, const QString &album,
                                 const QString &syncedLyrics, const QString &plainLyrics, const QString &provider);
    Q_INVOKABLE void fetchLyrics(const QString &title, const QString &artist, const QString &album,
                                 int durationSeconds);
    Q_INVOKABLE void searchLyrics(const QString &title, const QString &artist);
    /// Fetches lyrics one at a time for \p tracks that have none and no recent miss.
    Q_INVOKABLE void fetchLibraryLyrics(const QVariantList &tracks);
    Q_INVOKABLE void stopLibraryLyrics();
    int libraryLyricsFound() const;
    int libraryLyricsTotal() const;
    int libraryLyricsLeft() const;
    Q_INVOKABLE void fetchRadioStations(const QString &searchQuery = "", const QString &country = "",
                                        const QString &language = "", const QString &tag = "",
                                        const QString &sort = "votes", bool reverse = true);
    Q_INVOKABLE void cancelRadioRequests();
    Q_INVOKABLE void cancelNetworkRequests();
    Q_INVOKABLE void setBlackoutEnabled(bool enabled);
    Q_INVOKABLE void fetchArtistBio(const QString &artist);
    Q_INVOKABLE void fetchAlbumBio(const QString &album, const QString &artist);
    Q_INVOKABLE void fetchArtistImage(const QString &artist);
    /// Opens \p url when online services are enabled.
    Q_INVOKABLE void openExternalUrl(const QString &url);
    Q_INVOKABLE void validateListenBrainzToken(const QString &token);
    /// Signs in to an Audioscrobbler network, \p service being "librefm" or "lastfm".
    Q_INVOKABLE void authenticateScrobbleAccount(const QString &service, const QString &username,
                                                 const QString &password);
    Q_INVOKABLE void scrobbleNowPlaying(const QVariantMap &track);
    Q_INVOKABLE void scrobbleTrack(const QVariantMap &track, qint64 timestampSec);
    /// Marks a liked song as loved on the connected Last.fm, Libre.fm and ListenBrainz accounts, or clears it. Loves
    /// are sent one a second, so liking many songs at once stays under the services' rate limits.
    Q_INVOKABLE void loveTrack(const QVariantMap &track, bool loved);
    // Loves the liked songs each account lacks, and takes back loves the app sent for library songs no
    // longer liked. Songs outside the library are left alone.
    Q_INVOKABLE void syncLikes(const QVariantList &likedTracks, const QVariantList &libraryTracks);
    int lovesLeft() const {
        return int(m_loves.size());
    }
    Q_INVOKABLE void saveListenBrainzSession(const QString &token, const QString &userName);
    Q_INVOKABLE void disconnectListenBrainz();
    Q_INVOKABLE void disconnectScrobbleAccount(const QString &service);
    Q_INVOKABLE bool hasListenBrainzSession();
    QString listenBrainzProblem() const;
    Q_INVOKABLE bool hasScrobbleSession(const QString &service);
    /// Whether this build has a Last.fm API account.
    Q_INVOKABLE bool lastFmAvailable() const;
    /// Searches enabled artwork providers for matching album covers.
    Q_INVOKABLE void searchAlbumCovers(const QString &album, const QString &artist = "");
    /// Looks \p track up on MusicBrainz by its title, artist and length; answers with musicBrainzTagsReady.
    Q_INVOKABLE void findMusicBrainzTags(const QVariantMap &track);
    /// Downloads and caches \p imageUrl as album artwork.
    Q_INVOKABLE void applyAlbumCover(const QString &album, const QString &artist, const QString &imageUrl,
                                     const QString &filePath = "");
    /// Queries the latest release and emits the resulting update status.
    Q_INVOKABLE void checkForUpdates(bool manual = false);
    /// The changelog's points for \p version, empty when it has none.
    Q_INVOKABLE QStringList releaseNotes(const QString &version) const;
    /// Compares dotted release versions, returning their relative order.
    static int compareVersions(const QString &v1, const QString &v2);

  signals:
    void lyricsFetched(const QString &title, const QString &artist, const QString &lyrics, const QString &provider);
    void lyricsSearchResultsReady(const QVariantList &results);
    void libraryLyricsChanged();
    void lovesChanged();
    void lyricsSaved(const QString &key, const QString &text);
    void coverSearchResultsReady(const QVariantList &results);
    /// \p tags is empty without a confident match. \p problem is "off" when MusicBrainz is turned off or the app is
    /// offline, and "busy" when it kept refusing.
    void musicBrainzTagsReady(const QString &filePath, const QVariantMap &tags, const QString &problem);
    void coverSearchFailed(const QString &error);
    void coverApplied(const QString &album, const QString &artist, const QString &artworkPath, const QString &filePath);
    void radioStationsLoaded(const QVariantList &stations);
    void artistBioLoaded(const QString &artist, const QString &bio);
    void albumBioLoaded(const QString &album, const QString &bio);
    void artistImageLoaded(const QString &artist, const QString &imageUrl);
    void listenBrainzValidationFinished(bool valid, const QString &userName, const QString &error);
    void listenBrainzProblemChanged();
    void scrobbleAccountAuthFinished(const QString &service, bool success, const QString &userName,
                                     const QString &error);
    /// Announces the result of a completed update check.
    void updateCheckFinished(bool updateAvailable, const QString &latestVersion, const QString &releaseUrl,
                             const QString &releaseNotes, bool manual);
    /// Announces that an update check failed with \p error.
    void updateCheckFailed(const QString &error, bool manual);

  private:
    static QStringList releaseNotesFrom(const QString &changelog, const QString &version);
    enum class LyricsLookup { Found, Missing, Failed };
    /// Exact match first, then search; synced lyrics preferred.
    void lookUpLyrics(const QVariantMap &song, std::function<void(LyricsLookup, const QString &)> done);
    /// Falls back to LRCLIB's search when it has no exact match for the song.
    void searchLyrics(const QString &title, const QString &artist,
                      std::function<void(LyricsLookup, const QString &)> done);
    void fetchNextLibraryLyrics();
    static QString canonicalArtistName(const QString &artist);
    static QString deezerPicture(const QJsonArray &artists, const QString &key);
    static bool serviceEnabled(const QSettings &settings, const QString &service);
    bool onlineEnabled() const;
    bool serviceEnabled(const QString &service) const;
    QNetworkReply *trackReply(QNetworkReply *reply);
    void publishArtistImage(const QString &artist, const QString &imageUrl);
    void downloadArtistImage(const QString &artist, const QString &imageUrl, const QString &service);
    /// Tries \p queries on Wikipedia in turn and passes the first intro found to \p found, or calls \p missing.
    void fetchWikipediaIntro(const QStringList &queries, int index, std::function<void(const QString &)> found,
                             std::function<void()> missing);
    /// Searches TheAudioDB for \p artist and passes the artists it returns to \p handle.
    void searchAudioDb(const QString &artist, std::function<void(const QJsonArray &)> handle);
    void setListenBrainzProblem(const QString &problem);
    void submitToListenBrainz(const char *listenType, const QString &artist, const QString &title, const QString &album,
                              qint64 listenedAt);
    /// Tags for \p track from a MusicBrainz recording \p search, or empty without a confident match.
    static QVariantMap musicBrainzTagsFrom(const QJsonObject &search, const QVariantMap &track);
    /// How long to wait before the next MusicBrainz request, which allows one a second.
    int nextMusicBrainzSlotMs();
    void requestMusicBrainzTags(const QNetworkRequest &request, const QVariantMap &track, int attempt);
    void searchDeezerCovers(quint64 requestToken, const QString &term, const QString &album, const QString &artist,
                            const QVariantList &results, const QSet<QString> &seen);
    /// Adds covers from the Cover Art Archive, found through MusicBrainz, and reports the search's results.
    void searchArchiveCovers(quint64 requestToken, const QString &album, const QString &artist,
                             const QVariantList &results, const QSet<QString> &seen, int retry = 0);
    void fetchArtistImageFromAudioDb(const QString &artist);
    void fetchArtistBioFromAudioDb(const QString &artist);
    void initScrobbleCredentials();
    void saveScrobbleSession(const QString &service, const QString &username, const QString &sessionKey);
    void postToScrobbleAccounts(const QMap<QString, QString> &params);

    QNetworkAccessManager *m_net = nullptr;
    QHash<QString, QString> m_artistImages;
    QSet<QString> m_artistImagePending;
    QPointer<QNetworkReply> m_radioReply;
    QList<QPointer<QNetworkReply>> m_pendingReplies;
    int m_radioRequestToken = 0;
    quint64 m_lyricsRequestToken = 0;
    QList<QVariantMap> m_libraryLyricsQueue;
    bool m_libraryLyricsRunning = false;
    struct Love {
        QString artist;
        QString title;
        bool loved;
        // The account records (service and username) this goes to, fixed when it's queued so it never reaches an
        // account signed in afterwards.
        QStringList to;
    };
    // The songs an account has loved through the app, so Sync Likes sends each account only what it lacks.
    /// The songs loved through the app on the account whose record is \p record.
    static QStringList lovedSongs(const QString &record);
    static void recordLove(const QString &record, const QString &song, bool loved);
    // Whether the account has the app's love, not counting one an unlove is on its way to take back.
    bool hasLove(const QString &record, const QString &song) const;
    void queueLove(const Love &love);
    // Each service's own list of loves, by song, for the accounts whose list could be read.
    using AccountLoves = QHash<QString, QSet<QString>>;
    void loveTrackOn(const QVariantMap &track, bool loved, const AccountLoves &onAccounts);
    // One page of an account's loves: \c total is the page count for Last.fm and Libre.fm, and the number of loves
    // for ListenBrainz. Empty when the reply isn't such a page.
    struct LovedPage {
        QSet<QString> songs;
        int total = 0;
    };
    static std::optional<LovedPage> lovedTracksPage(const QJsonObject &reply);
    static std::optional<LovedPage> feedbackPage(const QJsonObject &reply);
    // A Sync Likes waiting for the accounts' lists of loves, so it sends only what each account is missing.
    struct LikesSync {
        QVariantList liked;
        QVariantList library;
        AccountLoves onAccounts;
        int waiting = 0;
    };
    std::optional<LikesSync> m_likesSync;
    quint64 m_likesSyncId = 0;
    void readAccountLoves(const QString &service, quint64 sync, int position);
    void finishLikesSync();
    QStringList lovingServices() const;
    QList<Love> m_loves;
    QHash<QString, quint64> m_loveGenerations;
    // Unloves waiting for an answer. Their love stays recorded until the account takes them, so a failed one is
    // tried again, while liking the song again meanwhile still sends the love.
    QSet<QString> m_unloving;
    bool m_lovesRunning = false;
    void sendNextLove();
    void sendLove(const Love &love);
    void sendLoveToScrobblers(const Love &love);
    void sendLoveToListenBrainz(const Love &love);
    void sendListenBrainzFeedback(const QString &mbid, bool loved, const QString &key, const QString &record,
                                  const QString &token);
    int m_libraryLyricsFailures = 0;
    int m_libraryLyricsFound = 0;
    int m_libraryLyricsTotal = 0;
    quint64 m_libraryLyricsScan = 0;
    // Songs looked up while a scan runs, and whether lyrics were found; the scan may have read them beforehand.
    QHash<QString, bool> m_libraryLyricsHandled;
    quint64 m_coverRequestToken = 0;
    qint64 m_nextMusicBrainzRequestMs = 0;
    QString m_listenBrainzToken;
    QString m_listenBrainzProblem;
    QHash<QString, QString> m_scrobbleSessionKeys;
    bool m_scrobbleCredentialsLoaded = false;
};
