#pragma once

#include <QByteArray>
#include <QElapsedTimer>
#include <QJsonObject>
#include <QObject>
#include <QString>
#include <QTcpServer>
#include <QTimer>
#include <QUdpSocket>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

class PlayerController;
class QHostAddress;
class QTcpSocket;

/// Lets the Android app control playback over the local network. It speaks the same HTTP API as the
/// CassetteCat hardware player, plus a bearer pairing code, so the phone reuses its device client.
class RemoteControlServer final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QString code READ code WRITE setCode NOTIFY codeChanged)
    Q_PROPERTY(QString address READ address NOTIFY addressChanged)
    /// The phone controlling playback right now, or empty.
    Q_PROPERTY(QString controllerName READ controllerName NOTIFY controllerChanged)
    /// What a paired phone is playing itself, as {name, title, artist, isPlaying}; empty when none is.
    Q_PROPERTY(QVariantMap phonePlayback READ phonePlayback NOTIFY phonePlaybackChanged)
    Q_PROPERTY(int repeatMode MEMBER m_repeatMode)
    /// The next few queued tracks as {index, title, artist, durationMs, filePath, artworkUrl}, kept current by QML.
    Q_PROPERTY(QVariantList upNext MEMBER m_upNext)

  public:
    explicit RemoteControlServer(PlayerController *player, QObject *parent = nullptr);

    bool enabled() const;
    void setEnabled(bool enabled);
    QString code() const;
    void setCode(const QString &code);
    /// Returns "ip:port" for the phone to connect to, or empty while stopped.
    QString address() const;
    QString controllerName() const;
    Q_INVOKABLE void regenerateCode();
    /// Asks the controlling phone to take over playback; it picks this up on its next poll.
    Q_INVOKABLE void continueOnPhone();
    QVariantMap phonePlayback() const;
    /// Queues \p command (play, pause, next, previous, handoff) for the phone's next check-in.
    Q_INVOKABLE void sendToPhone(const QString &command);

    /// Verifies pairing, routing and the status payload without opening sockets.
    static bool selfCheck();

  signals:
    void enabledChanged();
    void codeChanged();
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
    /// Asks to continue the phone's queue here: \p tracks as {title, artist}, starting at \p index.
    void handoffRequested(const QVariantList &tracks, int index, qint64 positionMs, bool playing);

  private:
    struct Response {
        int status;
        QByteArray body;
        QByteArray contentType = "application/json";
    };

    void serve(QTcpSocket *socket);
    Response respond(const QByteArray &method, const QByteArray &target, const QByteArray &authorization,
                     const QByteArray &body, const QHostAddress &peer, const QByteArray &deviceName = {});
    /// Answers a phone looking for computers on the network, or returns empty for anything else.
    QByteArray discoveryReply(const QByteArray &datagram, const QHostAddress &peer) const;
    QJsonObject status();

    PlayerController *m_player = nullptr;
    QTcpServer m_server;
    QUdpSocket m_discovery;
    QString m_code;
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
    // A playing phone checks in every couple of seconds; when it stops, its strip goes away.
    QTimer m_phoneTimeout;
};
