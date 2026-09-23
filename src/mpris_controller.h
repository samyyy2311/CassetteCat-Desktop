#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>

class PlayerController;

class MprisController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int repeatMode READ repeatMode WRITE setRepeatMode NOTIFY repeatModeChanged)

public:
    explicit MprisController(PlayerController *player, QObject *parent = nullptr);
    ~MprisController() override;

    void initialize();
    static bool selfCheck();

    int repeatMode() const;
    Q_INVOKABLE void setRepeatMode(int mode);

    static QVariantMap buildMetadata(const QVariantMap &track, qint64 durationMs);
    static QString playbackStatusString(bool isPlaying, bool hasTrack);
    static QString loopStatusString(int repeatMode);
    static int loopStatusToRepeatMode(const QString &loopStatus);

signals:
    void playRequested();
    void pauseRequested();
    void playPauseRequested();
    void nextRequested();
    void previousRequested();
    void seekRequested(qint64 positionMs);
    void raiseRequested();
    void quitRequested();
    void openUriRequested(const QString &uri);
    void repeatModeChanged(int mode);

private slots:
    void onTrackChanged();
    void onPlayingChanged();
    void onVolumeChanged();
    void onShuffleChanged();
    void onPositionChanged();

private:
    PlayerController *m_player = nullptr;
    int m_repeatMode = 0;
    void *m_backend = nullptr;
};
