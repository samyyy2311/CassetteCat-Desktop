#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>

class PlayerController;

class MprisController final : public QObject {
    Q_OBJECT
    Q_PROPERTY(int repeatMode READ repeatMode WRITE setRepeatMode NOTIFY repeatModeChanged)

  public:
    /// Creates an MPRIS bridge for \p player.
    explicit MprisController(PlayerController *player, QObject *parent = nullptr);
    /// Releases any registered platform MPRIS backend.
    ~MprisController() override;

    /// Registers the platform MPRIS backend when available.
    void initialize();
    /// Verifies the platform-independent MPRIS conversions and metadata.
    static bool selfCheck();

    /// Returns the application's numeric repeat mode.
    int repeatMode() const;
    /// Applies \p mode and publishes the corresponding MPRIS loop status.
    Q_INVOKABLE void setRepeatMode(int mode);

    /// Converts a track map and duration into MPRIS metadata.
    static QVariantMap buildMetadata(const QVariantMap &track, qint64 durationMs);
    /// Maps player state to an MPRIS playback-status string.
    static QString playbackStatusString(bool isPlaying, bool hasTrack);
    /// Maps an application repeat mode to an MPRIS loop-status string.
    static QString loopStatusString(int repeatMode);
    /// Maps an MPRIS loop-status string to an application repeat mode.
    static int loopStatusToRepeatMode(const QString &loopStatus);

  signals:
    /// Requests that playback start or resume.
    void playRequested();
    /// Requests that playback pause.
    void pauseRequested();
    /// Requests that playback toggle between playing and paused.
    void playPauseRequested();
    /// Requests the next track.
    void nextRequested();
    /// Requests the previous track.
    void previousRequested();
    /// Requests an absolute seek to \p positionMs milliseconds.
    void seekRequested(qint64 positionMs);
    /// Requests that the main application window be raised.
    void raiseRequested();
    /// Requests that the application exit.
    void quitRequested();
    /// Requests playback of \p uri.
    void openUriRequested(const QString &uri);
    /// Announces a change to repeat \p mode.
    void repeatModeChanged(int mode);
    /// Requests volume change.
    void volumeRequested(double volume);
    /// Requests shuffle state change.
    void shuffleRequested(bool shuffle);

  private slots:
    /// Publishes metadata after the current track changes.
    void onTrackChanged();
    /// Publishes playback status after the playing state changes.
    void onPlayingChanged();
    /// Publishes volume after the player volume changes.
    void onVolumeChanged();
    /// Publishes shuffle state after it changes.
    void onShuffleChanged();
    /// Handles position updates that do not require a property signal.
    void onPositionChanged();

  private:
    PlayerController *m_player = nullptr;
    int m_repeatMode = 0;
    void *m_backend = nullptr;
};
