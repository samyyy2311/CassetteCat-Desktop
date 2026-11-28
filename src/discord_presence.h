#pragma once

#include <QByteArray>
#include <QJsonObject>
#include <QHash>
#include <QLocalSocket>
#include <QNetworkAccessManager>
#include <QObject>
#include <QPointer>
#include <QStringList>
#include <QTimer>
#include <QVariantMap>

class PlayerController;

/// Shows the playing song on the user's Discord profile through the local Discord client.
class DiscordPresence final : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)

  public:
    explicit DiscordPresence(PlayerController *player, QObject *parent = nullptr);
    ~DiscordPresence() override;

    bool enabled() const;
    void setEnabled(bool enabled);

    /// Builds the Discord activity for \p track, or an empty object when nothing should be shown.
    /// \p artworkUrl is a public image of the cover; the app logo is shown without one.
    static QJsonObject activityFor(const QVariantMap &track, bool playing, qint64 positionMs, qint64 durationMs,
                                   qint64 nowMs, const QString &artworkUrl = {});
    /// Verifies the activity and the IPC exchange against a local stand-in for Discord.
    static bool selfCheck();

  signals:
    void enabledChanged();

  private:
    void connectToNextCandidate();
    void readFrames();
    void scheduleUpdate();
    void sendActivity();
    void sendFrame(quint32 opcode, const QJsonObject &payload);
    // Finds a public picture of the track's cover, as Discord can't show the files' own art.
    void lookUpArtwork(const QVariantMap &track);

    PlayerController *m_player = nullptr;
    QLocalSocket m_socket;
    QTimer m_retryTimer;
    QTimer m_updateTimer;
    QByteArray m_buffer;
    QStringList m_candidates;
    qsizetype m_candidate = 0;
    bool m_enabled = false;
    bool m_ready = false;
    qint64 m_lastSentMs = 0;
    qint64 m_sentStartMs = 0;
    QNetworkAccessManager m_net;
    // Cover image URLs by artist and album; empty when none was found, so it isn't looked up again.
    QHash<QString, QString> m_artwork;
    QString m_artworkLookup;
    // The lookup in flight, stopped when Discord is turned off so nothing more goes out.
    QPointer<QNetworkReply> m_artworkReply;
    // The song whose cover couldn't be looked up, shown with the logo instead of being asked for again and again.
    QString m_artworkFailed;
};
