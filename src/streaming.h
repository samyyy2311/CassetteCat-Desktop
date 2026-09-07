#pragma once

#include <QHash>
#include <QList>
#include <QObject>
#include <QPointer>
#include <QSet>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>

#include <memory>

class QNetworkAccessManager;
class QNetworkReply;
class RemoteTrackModel;

namespace streaming::detail {
inline constexpr int requestTimeoutMs = 60'000;
}

// Streaming-server support (Subsonic/Navidrome, Jellyfin), mirroring the
// Android data/streaming clients. Secrets live only in the OS credential
// store plus transient request memory; QSettings holds non-secret config.
// QML receives track metadata only, never passwords, tokens, or session keys.
class StreamingController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList remoteTracks READ remoteTracks NOTIFY remoteTracksChanged)
    Q_PROPERTY(bool subsonicConnected READ subsonicConnected NOTIFY statusChanged)
    Q_PROPERTY(bool jellyfinConnected READ jellyfinConnected NOTIFY statusChanged)
    Q_PROPERTY(QString subsonicStatus READ subsonicStatus NOTIFY statusChanged)
    Q_PROPERTY(QString jellyfinStatus READ jellyfinStatus NOTIFY statusChanged)
    Q_PROPERTY(bool remoteLibraryLoading READ remoteLibraryLoading NOTIFY remoteLibraryLoadingChanged)
    Q_PROPERTY(int remoteArtRevision READ remoteArtRevision NOTIFY remoteArtChanged)
    Q_PROPERTY(RemoteTrackModel *jellyfinModel READ jellyfinModel CONSTANT)
    Q_PROPERTY(RemoteTrackModel *subsonicModel READ subsonicModel CONSTANT)

public:
    explicit StreamingController(const QString &settingsPath, QObject *parent = nullptr);

    QVariantList remoteTracks() const { return m_remoteTracks; }
    bool subsonicConnected() const { return m_subsonicConnected; }
    bool jellyfinConnected() const { return m_jellyfinConnected; }
    QString subsonicStatus() const { return m_subsonicStatus; }
    QString jellyfinStatus() const { return m_jellyfinStatus; }
    bool remoteLibraryLoading() const { return m_refreshing; }
    int remoteArtRevision() const { return m_remoteArtRevision; }
    RemoteTrackModel *jellyfinModel() const { return m_jellyfinModel; }
    RemoteTrackModel *subsonicModel() const { return m_subsonicModel; }

    Q_INVOKABLE void connectSubsonic(const QString &serverUrl, const QString &username, const QString &password);
    Q_INVOKABLE void connectJellyfin(const QString &serverUrl, const QString &username, const QString &password);
    Q_INVOKABLE void disconnectServer(const QString &protocol);
    Q_INVOKABLE void refreshLibrary();
    Q_INVOKABLE void setBlackoutEnabled(bool enabled);
    Q_INVOKABLE void setServerFavorite(const QString &filePath, bool favorite);
    Q_INVOKABLE QString remoteArtwork(const QString &filePath);

    // C++-only: build an authenticated stream URL for playback. Never exposed to QML.
    QUrl streamSourceFor(const QString &source, const QString &remoteId) const;
    static bool isRemotePath(const QString &filePath);

    // Non-secret server config snapshot for prefilling the connect sheet.
    // Tested to exclude secrets.
    Q_INVOKABLE QVariantMap serverConfigSnapshot() const;
    static QVariantMap serverConfigSnapshot(const QString &settingsPath);

signals:
    void remoteTracksChanged();
    void statusChanged();
    void remoteArtChanged();
    void remoteLibraryLoadingChanged();
    void serverConnected(const QString &protocol, const QString &displayName);
    void serverFailed(const QString &protocol, const QString &message);
    void serverFavoriteFailed(const QString &filePath);

private:
    void updateStatusTexts();
    void setRemoteTracks(const QVariantList &tracks);
    void removeProviderTracks(const QString &prefix);
    void setStatus(const QString &protocol, bool connected, const QString &status);
    void setRemoteLibraryLoading(bool loading);
    bool blackoutEnabled() const;
    QString deviceId();
    QNetworkReply *trackReply(QNetworkReply *reply);
    QString friendlyError(QNetworkReply *reply, const QString &fallback);
    void beginRefresh();
    void finishRefreshStage();
    void cancelPendingRequests();
    void refreshSubsonic(const QString &base, const QString &user, const QString &password, int tokenSnapshot);
    void fetchSubsonicAlbumIds(const QString &base, const QString &user, const QString &token,
                               const QString &salt, int offset, std::shared_ptr<QStringList> ids,
                               std::shared_ptr<QVariantList> out, int tokenSnapshot);
    void fetchSubsonicAlbum(const QString &base, const QString &user, const QString &token,
                            const QString &salt, std::shared_ptr<QStringList> ids,
                            std::shared_ptr<QVariantList> out, std::shared_ptr<int> nextIndex,
                            std::shared_ptr<int> activeRequests, int tokenSnapshot);
    void refreshJellyfin(const QString &base, const QString &userId, const QString &accessToken, int tokenSnapshot);
    void fetchJellyfinPage(const QString &base, const QString &userId, const QString &accessToken,
                           int startIndex, std::shared_ptr<QVariantList> out, int tokenSnapshot);

    QString m_settingsPath;
    QVariantList m_remoteTracks;
    bool m_subsonicConnected = false;
    bool m_jellyfinConnected = false;
    QString m_subsonicStatus;
    QString m_jellyfinStatus;
    int m_remoteArtRevision = 0;
    QHash<QString, QString> m_remoteArt;
    QHash<QString, QString> m_remoteArtSource;
    QSet<QString> m_remoteArtPending;
    int m_remoteArtDownloads = 0;
    QList<QPointer<QNetworkReply>> m_pendingReplies;
    int m_subConnectToken = 0;
    int m_jellyConnectToken = 0;
    int m_refreshToken = 0;
    bool m_refreshing = false;
    bool m_refreshQueued = false;
    int m_pendingStages = 0;
    QNetworkAccessManager *m_net = nullptr;
    RemoteTrackModel *m_jellyfinModel = nullptr;
    RemoteTrackModel *m_subsonicModel = nullptr;
};

namespace streaming {

// Deterministic protocol/unit checks. The vault probe is opt-in because some
// unattended Windows sessions cannot access Credential Manager.
bool runSelfChecks(bool includeVaultProbe = false);

}
