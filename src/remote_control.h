#pragma once

#include <QByteArray>
#include <QElapsedTimer>
#include <QJsonObject>
#include <QObject>
#include <QString>
#include <QTcpServer>

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
    Q_PROPERTY(int repeatMode MEMBER m_repeatMode)

  public:
    explicit RemoteControlServer(PlayerController *player, QObject *parent = nullptr);

    bool enabled() const;
    void setEnabled(bool enabled);
    QString code() const;
    void setCode(const QString &code);
    /// Returns "ip:port" for the phone to connect to, or empty while stopped.
    QString address() const;
    Q_INVOKABLE void regenerateCode();

    /// Verifies pairing, routing and the status payload without opening sockets.
    static bool selfCheck();

  signals:
    void enabledChanged();
    void codeChanged();
    void addressChanged();
    void playRequested();
    void pauseRequested();
    void nextRequested();
    void previousRequested();
    void shuffleToggleRequested();
    void repeatCycleRequested();
    void volumeRequested(double volume);
    void seekRequested(qint64 positionMs);

  private:
    struct Response {
        int status;
        QByteArray body;
    };

    void serve(QTcpSocket *socket);
    Response respond(const QByteArray &method, const QByteArray &path, const QByteArray &authorization,
                     const QByteArray &body, const QHostAddress &peer);
    QJsonObject status() const;

    PlayerController *m_player = nullptr;
    QTcpServer m_server;
    QString m_code;
    bool m_enabled = false;
    int m_repeatMode = 0;
    int m_failedAttempts = 0;
    QElapsedTimer m_lockedSince;
};
