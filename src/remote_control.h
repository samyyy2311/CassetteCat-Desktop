#pragma once

#include <QByteArray>
#include <QElapsedTimer>
#include <QJsonArray>
#include <QJsonObject>
#include <QObject>
#include <QString>
#include <QTcpServer>
#include <QTimer>
#include <QUdpSocket>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

class LibraryController;
class PlayerController;
class QHostAddress;
class QTcpSocket;

/// Lets the Android app control playback over the local network. It speaks the same HTTP API as the
/// CassetteCat hardware player, plus a bearer pairing code, so the phone reuses its device client.
class RemoteControlServer final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    /// The code for pairing by address. Phones allowed from this computer get their own code instead.
    Q_PROPERTY(QString code READ code WRITE setCode NOTIFY codeChanged)
    /// Phones allowed from this computer, as {name, code}; removing one unpairs only that phone.
    Q_PROPERTY(QVariantList pairedPhones READ pairedPhones WRITE setPairedPhones NOTIFY pairedPhonesChanged)
    Q_PROPERTY(QString address READ address NOTIFY addressChanged)
    /// The name phones show for this computer when they find it.
    Q_PROPERTY(QString computerName READ computerName CONSTANT)
    /// The phone controlling playback right now, or empty.
    Q_PROPERTY(QString controllerName READ controllerName NOTIFY controllerChanged)
    /// What a paired phone is playing itself, as {name, title, artist, isPlaying, positionMs, durationMs, updatedAt,
    /// volumePercent, artwork, filePath}; empty when none is. filePath is the same song in this library, if any.
    Q_PROPERTY(QVariantMap phonePlayback READ phonePlayback NOTIFY phonePlaybackChanged)
    Q_PROPERTY(int repeatMode MEMBER m_repeatMode)
    /// The next few queued tracks as {index, title, artist, durationMs, filePath, artworkUrl}, kept current by QML.
    Q_PROPERTY(QVariantList upNext MEMBER m_upNext)
    /// The favorite file paths, kept current by QML, so a paired phone can sync likes.
    Q_PROPERTY(QStringList favoritePaths MEMBER m_favoritePaths NOTIFY favoritePathsChanged)
    /// The saved playlists as {name, trackPaths}, kept current by QML, so a paired phone can copy them.
    Q_PROPERTY(QVariantList playlists MEMBER m_playlists)
    /// The phone asking to pair, waiting for this computer to allow or deny it; empty when none is.
    Q_PROPERTY(QString pairingRequest READ pairingRequest NOTIFY pairingRequestChanged)

  public:
    RemoteControlServer(PlayerController *player, LibraryController *library, QObject *parent = nullptr);

    bool enabled() const;
    void setEnabled(bool enabled);
    QString code() const;
    void setCode(const QString &code);
    QVariantList pairedPhones() const;
    void setPairedPhones(const QVariantList &phones);
    Q_INVOKABLE void unpairPhone(const QString &code);
    /// Returns "ip:port" for the phone to connect to, or empty while stopped.
    QString address() const;
    QString computerName() const;
    QString controllerName() const;
    Q_INVOKABLE void regenerateCode();
    /// Asks the controlling phone to take over playback; it picks this up on its next poll.
    Q_INVOKABLE void continueOnPhone();
    QVariantMap phonePlayback() const;
    /// Queues \p command (play, pause, next, previous, handoff) for the phone's next check-in.
    Q_INVOKABLE void sendToPhone(const QString &command);
    /// Asks the phone to play the track named \p title by \p artist next, if its library has it.
    Q_INVOKABLE void playNextOnPhone(const QString &title, const QString &artist);
    QString pairingRequest() const;
    /// Allows or denies the phone in pairingRequest; once allowed, it receives the pairing code on its next check.
    Q_INVOKABLE void answerPairing(bool allow);

    /// Verifies pairing, routing and the status payload without opening sockets.
    static bool selfCheck();

  signals:
    void enabledChanged();
    void codeChanged();
    void pairedPhonesChanged();
    void addressChanged();
    void controllerChanged();
    void phonePlaybackChanged();
    void playRequested();
    void pauseRequested();
    void nextRequested();
    void previousRequested();
    void shuffleToggleRequested();
    void repeatCycleRequested();
    void volumeRequested(double volume);
    void seekRequested(qint64 positionMs);
    /// Requests playback of the track at \p index in the active queue.
    void queueTrackRequested(int index);
    /// Moves the queued track at \p from to \p to; both are positions in the active queue.
    void queueMoveRequested(int from, int to);
    void queueRemoveRequested(int index);
    /// Asks to continue the phone's queue here: \p tracks as {title, artist}, starting at \p index.
    void handoffRequested(const QVariantList &tracks, int index, qint64 positionMs, bool playing);
    /// Asks to play the track named \p title by \p artist next, if the library has it.
    void playNextRequested(const QString &title, const QString &artist);
    void favoritePathsChanged();
    void pairingRequestChanged();
    /// Asks to like the tracks at \p likePaths and unlike those at \p unlikePaths, as synced from the phone.
    void likesChangeRequested(const QStringList &likePaths, const QStringList &unlikePaths);
    /// Asks to save the playlist \p name with the tracks at \p trackPaths, matched from \p sentCount sent tracks,
    /// replacing one with the same name.
    void playlistReceived(const QString &name, const QStringList &trackPaths, int sentCount);

  private:
    struct Response {
        int status;
        QByteArray body;
        QByteArray contentType = "application/json";
        // Set for /api/stream: the library file to send, honouring the request's Range header.
        QString filePath;
    };

    bool acceptsCode(const QByteArray &code) const;
    void serve(QTcpSocket *socket);
    /// Sends \p response's library file over \p socket, from the byte range in \p range if one was asked for.
    void streamFile(QTcpSocket *socket, const Response &response, const QByteArray &range);
    Response respond(const QByteArray &method, const QByteArray &target, const QByteArray &authorization,
                     const QByteArray &body, const QHostAddress &peer, const QByteArray &deviceName = {});
    /// Answers a phone looking for computers on the network, or returns empty for anything else.
    QByteArray discoveryReply(const QByteArray &datagram, const QHostAddress &peer) const;
    QJsonObject status();
    /// Emits addressChanged when the address a phone should use differs from the one last shown.
    void checkAddress();

    PlayerController *m_player = nullptr;
    LibraryController *m_library = nullptr;
    QStringList m_favoritePaths;
    QVariantList m_playlists;
    // Tells a syncing phone that likes or the library changed since it last looked.
    int m_likesRevision = 0;
    QTcpServer m_server;
    QUdpSocket m_discovery;
    QString m_code;
    QVariantList m_pairedPhones;
    bool m_enabled = false;
    int m_repeatMode = 0;
    QVariantList m_upNext;
    int m_failedAttempts = 0;
    QElapsedTimer m_lockedSince;
    QString m_controllerName;
    // A controlling phone polls every couple of seconds; when it stops, it is no longer shown.
    QTimer m_controllerTimeout;
    bool m_handoffToPhone = false;
    QVariantMap m_phonePlayback;
    QStringList m_phoneCommands;
    QJsonArray m_phonePlayNext;
    // A playing phone checks in every couple of seconds; when it stops, its strip goes away.
    QTimer m_phoneTimeout;
    QTimer m_addressCheck;
    enum class PairingAnswer { Waiting, Allowed, Denied };
    QString m_pairingRequestId;
    QString m_pairingRequestName;
    PairingAnswer m_pairingAnswer = PairingAnswer::Waiting;
    // A phone that is not answered in time is turned away, so the prompt does not wait forever.
    QTimer m_pairingTimeout;
    QString m_lastAddress;
};
