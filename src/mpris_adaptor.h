#pragma once

class MprisController;
class PlayerController;

#ifdef CASSETTECAT_HAVE_DBUS

#include <QDBusAbstractAdaptor>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QStringList>
#include <QVariantMap>

class MediaPlayer2Adaptor final : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.mpris.MediaPlayer2")
    Q_PROPERTY(bool CanQuit READ canQuit)
    Q_PROPERTY(bool CanRaise READ canRaise)
    Q_PROPERTY(bool CanSetFullscreen READ canSetFullscreen)
    Q_PROPERTY(bool HasTrackList READ hasTrackList)
    Q_PROPERTY(QString Identity READ identity)
    Q_PROPERTY(QString DesktopEntry READ desktopEntry)
    Q_PROPERTY(QStringList SupportedUriSchemes READ supportedUriSchemes)
    Q_PROPERTY(QStringList SupportedMimeTypes READ supportedMimeTypes)

  public:
    /// Creates the root MPRIS adaptor and forwards requests to \p parent.
    explicit MediaPlayer2Adaptor(MprisController *parent);

    /// Reports whether remote clients may request application shutdown.
    bool canQuit() const;
    /// Reports whether remote clients may raise the application window.
    bool canRaise() const;
    /// Reports whether the application supports fullscreen control.
    bool canSetFullscreen() const;
    /// Reports whether the application exposes an MPRIS track list.
    bool hasTrackList() const;
    /// Returns the player name advertised over MPRIS.
    QString identity() const;
    /// Returns the desktop entry advertised over MPRIS.
    QString desktopEntry() const;
    /// Returns the URI schemes accepted by the player.
    QStringList supportedUriSchemes() const;
    /// Returns the MIME types accepted by the player.
    QStringList supportedMimeTypes() const;

  public slots:
    /// Requests that the application bring its main window forward.
    void Raise();
    /// Requests that the application shut down.
    void Quit();

  private:
    MprisController *m_controller = nullptr;
};

class MediaPlayer2PlayerAdaptor final : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.mpris.MediaPlayer2.Player")
    Q_PROPERTY(QString PlaybackStatus READ playbackStatus)
    Q_PROPERTY(QString LoopStatus READ loopStatus WRITE setLoopStatus)
    Q_PROPERTY(double Rate READ rate WRITE setRate)
    Q_PROPERTY(bool Shuffle READ shuffle WRITE setShuffle)
    Q_PROPERTY(QVariantMap Metadata READ metadata)
    Q_PROPERTY(double Volume READ volume WRITE setVolume)
    Q_PROPERTY(qlonglong Position READ position)
    Q_PROPERTY(double MinimumRate READ minimumRate)
    Q_PROPERTY(double MaximumRate READ maximumRate)
    Q_PROPERTY(bool CanGoNext READ canGoNext)
    Q_PROPERTY(bool CanGoPrevious READ canGoPrevious)
    Q_PROPERTY(bool CanPlay READ canPlay)
    Q_PROPERTY(bool CanPause READ canPause)
    Q_PROPERTY(bool CanSeek READ canSeek)
    Q_PROPERTY(bool CanControl READ canControl)

  public:
    /// Creates the player adaptor backed by \p player and \p parent.
    explicit MediaPlayer2PlayerAdaptor(MprisController *parent, PlayerController *player);

    /// Returns the current MPRIS playback status.
    QString playbackStatus() const;
    /// Returns the current MPRIS loop status.
    QString loopStatus() const;
    /// Applies an MPRIS loop status to the application repeat mode.
    void setLoopStatus(const QString &loopStatus);
    /// Returns the current playback rate.
    double rate() const;
    /// Handles a requested playback rate.
    void setRate(double rate);
    /// Returns whether shuffle playback is enabled.
    bool shuffle() const;
    /// Enables or disables shuffle playback.
    void setShuffle(bool shuffle);
    /// Returns metadata for the current track.
    QVariantMap metadata() const;
    /// Returns the current player volume in the MPRIS range.
    double volume() const;
    /// Applies a volume value from an MPRIS client.
    void setVolume(double volume);
    /// Returns the current playback position in microseconds.
    qlonglong position() const;
    /// Returns the minimum supported playback rate.
    double minimumRate() const;
    /// Returns the maximum supported playback rate.
    double maximumRate() const;
    /// Reports whether advancing to the next track is supported.
    bool canGoNext() const;
    /// Reports whether returning to the previous track is supported.
    bool canGoPrevious() const;
    /// Reports whether playback can be started.
    bool canPlay() const;
    /// Reports whether playback can be paused.
    bool canPause() const;
    /// Reports whether seeking is supported.
    bool canSeek() const;
    /// Reports whether the player accepts MPRIS controls.
    bool canControl() const;

    /// Emits a D-Bus property-change notification for \p changed.
    void notifyPropertiesChanged(const QVariantMap &changed);

  public slots:
    /// Requests playback of the next track.
    void Next();
    /// Requests playback of the previous track.
    void Previous();
    /// Pauses playback.
    void Pause();
    /// Toggles between playing and paused states.
    void PlayPause();
    /// Stops playback.
    void Stop();
    /// Starts or resumes playback.
    void Play();
    /// Seeks by \p offsetUs microseconds relative to the current position.
    void Seek(qlonglong offsetUs);
    /// Seeks the current track to \p positionUs microseconds.
    void SetPosition(const QDBusObjectPath &trackId, qlonglong positionUs);
    /// Requests playback of \p uri.
    void OpenUri(const QString &uri);

  signals:
    /// Announces an absolute seek to \p Position microseconds.
    void Seeked(qlonglong Position);

  private:
    MprisController *m_controller = nullptr;
    PlayerController *m_player = nullptr;
};

/// Registers the Linux MPRIS backend and returns its opaque state.
void *createLinuxMprisBackend(MprisController *controller, PlayerController *player);
/// Unregisters and destroys an MPRIS \p backend.
void destroyLinuxMprisBackend(void *backend);
/// Publishes current-track metadata for an MPRIS \p backend.
void notifyLinuxMprisTrackChanged(void *backend);
/// Publishes playback-state changes for an MPRIS \p backend.
void notifyLinuxMprisPlayingChanged(void *backend);
/// Publishes volume changes for an MPRIS \p backend.
void notifyLinuxMprisVolumeChanged(void *backend);
/// Publishes shuffle changes for an MPRIS \p backend.
void notifyLinuxMprisShuffleChanged(void *backend);
/// Publishes repeat-mode changes for an MPRIS \p backend.
void notifyLinuxMprisLoopStatusChanged(void *backend);

#else

/// Returns an empty backend when D-Bus support is unavailable.
inline void *createLinuxMprisBackend(MprisController *, PlayerController *) {
    return nullptr;
}
/// No-op backend teardown used when D-Bus support is unavailable.
inline void destroyLinuxMprisBackend(void *) {}
/// No-op track notification used when D-Bus support is unavailable.
inline void notifyLinuxMprisTrackChanged(void *) {}
/// No-op playback notification used when D-Bus support is unavailable.
inline void notifyLinuxMprisPlayingChanged(void *) {}
/// No-op volume notification used when D-Bus support is unavailable.
inline void notifyLinuxMprisVolumeChanged(void *) {}
/// No-op shuffle notification used when D-Bus support is unavailable.
inline void notifyLinuxMprisShuffleChanged(void *) {}
/// No-op loop-status notification used when D-Bus support is unavailable.
inline void notifyLinuxMprisLoopStatusChanged(void *) {}

#endif // CASSETTECAT_HAVE_DBUS
