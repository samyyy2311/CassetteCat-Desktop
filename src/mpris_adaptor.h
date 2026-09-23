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
    explicit MediaPlayer2Adaptor(MprisController *parent);

    bool canQuit() const;
    bool canRaise() const;
    bool canSetFullscreen() const;
    bool hasTrackList() const;
    QString identity() const;
    QString desktopEntry() const;
    QStringList supportedUriSchemes() const;
    QStringList supportedMimeTypes() const;

  public slots:
    void Raise();
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
    explicit MediaPlayer2PlayerAdaptor(MprisController *parent, PlayerController *player);

    QString playbackStatus() const;
    QString loopStatus() const;
    void setLoopStatus(const QString &loopStatus);
    double rate() const;
    void setRate(double rate);
    bool shuffle() const;
    void setShuffle(bool shuffle);
    QVariantMap metadata() const;
    double volume() const;
    void setVolume(double volume);
    qlonglong position() const;
    double minimumRate() const;
    double maximumRate() const;
    bool canGoNext() const;
    bool canGoPrevious() const;
    bool canPlay() const;
    bool canPause() const;
    bool canSeek() const;
    bool canControl() const;

    void notifyPropertiesChanged(const QVariantMap &changed);

  public slots:
    void Next();
    void Previous();
    void Pause();
    void PlayPause();
    void Stop();
    void Play();
    void Seek(qlonglong offsetUs);
    void SetPosition(const QDBusObjectPath &trackId, qlonglong positionUs);
    void OpenUri(const QString &uri);

  signals:
    void Seeked(qlonglong Position);

  private:
    MprisController *m_controller = nullptr;
    PlayerController *m_player = nullptr;
};

void *createLinuxMprisBackend(MprisController *controller, PlayerController *player);
void destroyLinuxMprisBackend(void *backend);
void notifyLinuxMprisTrackChanged(void *backend);
void notifyLinuxMprisPlayingChanged(void *backend);
void notifyLinuxMprisVolumeChanged(void *backend);
void notifyLinuxMprisShuffleChanged(void *backend);
void notifyLinuxMprisLoopStatusChanged(void *backend);

#else

inline void *createLinuxMprisBackend(MprisController *, PlayerController *) {
    return nullptr;
}
inline void destroyLinuxMprisBackend(void *) {}
inline void notifyLinuxMprisTrackChanged(void *) {}
inline void notifyLinuxMprisPlayingChanged(void *) {}
inline void notifyLinuxMprisVolumeChanged(void *) {}
inline void notifyLinuxMprisShuffleChanged(void *) {}
inline void notifyLinuxMprisLoopStatusChanged(void *) {}

#endif // CASSETTECAT_HAVE_DBUS
