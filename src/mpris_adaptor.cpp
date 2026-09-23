#include "mpris_adaptor.h"
#include "mpris_controller.h"
#include "player_controller.h"

#include <QCoreApplication>
#include <QDebug>
#include <algorithm>

#ifdef CASSETTECAT_HAVE_DBUS

/// @copydoc MediaPlayer2Adaptor::MediaPlayer2Adaptor
MediaPlayer2Adaptor::MediaPlayer2Adaptor(MprisController *parent)
    : QDBusAbstractAdaptor(parent)
    , m_controller(parent)
{
}

/// @copydoc MediaPlayer2Adaptor::canQuit
bool MediaPlayer2Adaptor::canQuit() const
{
    return true;
}

/// @copydoc MediaPlayer2Adaptor::canRaise
bool MediaPlayer2Adaptor::canRaise() const
{
    return true;
}

/// @copydoc MediaPlayer2Adaptor::canSetFullscreen
bool MediaPlayer2Adaptor::canSetFullscreen() const
{
    return false;
}

/// @copydoc MediaPlayer2Adaptor::hasTrackList
bool MediaPlayer2Adaptor::hasTrackList() const
{
    return false;
}

/// @copydoc MediaPlayer2Adaptor::identity
QString MediaPlayer2Adaptor::identity() const
{
    return QStringLiteral("CassetteCat");
}

/// @copydoc MediaPlayer2Adaptor::desktopEntry
QString MediaPlayer2Adaptor::desktopEntry() const
{
    return QStringLiteral("io.github.samyyy2311.CassetteCat");
}

/// @copydoc MediaPlayer2Adaptor::supportedUriSchemes
QStringList MediaPlayer2Adaptor::supportedUriSchemes() const
{
    return { QStringLiteral("file"), QStringLiteral("http"), QStringLiteral("https") };
}

/// @copydoc MediaPlayer2Adaptor::supportedMimeTypes
QStringList MediaPlayer2Adaptor::supportedMimeTypes() const
{
    return {
        QStringLiteral("audio/aac"),
        QStringLiteral("audio/flac"),
        QStringLiteral("audio/mpeg"),
        QStringLiteral("audio/mp4"),
        QStringLiteral("audio/ogg"),
        QStringLiteral("audio/opus"),
        QStringLiteral("audio/wav"),
        QStringLiteral("audio/x-aiff"),
        QStringLiteral("audio/x-m4a"),
        QStringLiteral("audio/x-ms-wma"),
        QStringLiteral("audio/x-wav")
    };
}

/// @copydoc MediaPlayer2Adaptor::Raise
void MediaPlayer2Adaptor::Raise()
{
    if (m_controller) emit m_controller->raiseRequested();
}

/// @copydoc MediaPlayer2Adaptor::Quit
void MediaPlayer2Adaptor::Quit()
{
    if (m_controller) emit m_controller->quitRequested();
}

/// @copydoc MediaPlayer2PlayerAdaptor::MediaPlayer2PlayerAdaptor
MediaPlayer2PlayerAdaptor::MediaPlayer2PlayerAdaptor(MprisController *parent, PlayerController *player)
    : QDBusAbstractAdaptor(parent)
    , m_controller(parent)
    , m_player(player)
{
}

/// @copydoc MediaPlayer2PlayerAdaptor::playbackStatus
QString MediaPlayer2PlayerAdaptor::playbackStatus() const
{
    const bool isPlaying = m_player && m_player->isPlaying();
    const bool hasTrack = m_player && !m_player->currentTrack().isEmpty();
    return MprisController::playbackStatusString(isPlaying, hasTrack);
}

/// @copydoc MediaPlayer2PlayerAdaptor::loopStatus
QString MediaPlayer2PlayerAdaptor::loopStatus() const
{
    const int mode = m_controller ? m_controller->repeatMode() : 0;
    return MprisController::loopStatusString(mode);
}

/// @copydoc MediaPlayer2PlayerAdaptor::setLoopStatus
void MediaPlayer2PlayerAdaptor::setLoopStatus(const QString &loopStatus)
{
    if (m_controller) {
        m_controller->setRepeatMode(MprisController::loopStatusToRepeatMode(loopStatus));
    }
}

/// @copydoc MediaPlayer2PlayerAdaptor::rate
double MediaPlayer2PlayerAdaptor::rate() const
{
    return 1.0;
}

/// @copydoc MediaPlayer2PlayerAdaptor::setRate
void MediaPlayer2PlayerAdaptor::setRate(double rate)
{
    Q_UNUSED(rate);
}

/// @copydoc MediaPlayer2PlayerAdaptor::shuffle
bool MediaPlayer2PlayerAdaptor::shuffle() const
{
    return m_player ? m_player->shuffleEnabled() : false;
}

/// @copydoc MediaPlayer2PlayerAdaptor::setShuffle
void MediaPlayer2PlayerAdaptor::setShuffle(bool shuffle)
{
    if (m_player) m_player->setShuffleEnabled(shuffle);
}

/// @copydoc MediaPlayer2PlayerAdaptor::metadata
QVariantMap MediaPlayer2PlayerAdaptor::metadata() const
{
    const QVariantMap track = m_player ? m_player->currentTrack() : QVariantMap();
    const qint64 dur = m_player ? m_player->duration() : 0;
    return MprisController::buildMetadata(track, dur);
}

/// @copydoc MediaPlayer2PlayerAdaptor::volume
double MediaPlayer2PlayerAdaptor::volume() const
{
    return m_player ? static_cast<double>(m_player->volume()) : 1.0;
}

/// @copydoc MediaPlayer2PlayerAdaptor::setVolume
void MediaPlayer2PlayerAdaptor::setVolume(double volume)
{
    if (m_player) {
        const float clamped = static_cast<float>(std::clamp(volume, 0.0, 1.0));
        m_player->setVolume(clamped);
    }
}

/// @copydoc MediaPlayer2PlayerAdaptor::position
qlonglong MediaPlayer2PlayerAdaptor::position() const
{
    return m_player ? (static_cast<qlonglong>(m_player->position()) * 1000) : 0;
}

/// @copydoc MediaPlayer2PlayerAdaptor::minimumRate
double MediaPlayer2PlayerAdaptor::minimumRate() const
{
    return 1.0;
}

/// @copydoc MediaPlayer2PlayerAdaptor::maximumRate
double MediaPlayer2PlayerAdaptor::maximumRate() const
{
    return 1.0;
}

/// @copydoc MediaPlayer2PlayerAdaptor::canGoNext
bool MediaPlayer2PlayerAdaptor::canGoNext() const
{
    return true;
}

/// @copydoc MediaPlayer2PlayerAdaptor::canGoPrevious
bool MediaPlayer2PlayerAdaptor::canGoPrevious() const
{
    return true;
}

/// @copydoc MediaPlayer2PlayerAdaptor::canPlay
bool MediaPlayer2PlayerAdaptor::canPlay() const
{
    return true;
}

/// @copydoc MediaPlayer2PlayerAdaptor::canPause
bool MediaPlayer2PlayerAdaptor::canPause() const
{
    return true;
}

/// @copydoc MediaPlayer2PlayerAdaptor::canSeek
bool MediaPlayer2PlayerAdaptor::canSeek() const
{
    return true;
}

/// @copydoc MediaPlayer2PlayerAdaptor::canControl
bool MediaPlayer2PlayerAdaptor::canControl() const
{
    return true;
}

/// @copydoc MediaPlayer2PlayerAdaptor::notifyPropertiesChanged
void MediaPlayer2PlayerAdaptor::notifyPropertiesChanged(const QVariantMap &changed)
{
    if (changed.isEmpty() || !QDBusConnection::sessionBus().isConnected()) return;
    QDBusMessage signal = QDBusMessage::createSignal(
        QStringLiteral("/org/mpris/MediaPlayer2"),
        QStringLiteral("org.freedesktop.DBus.Properties"),
        QStringLiteral("PropertiesChanged")
    );
    signal << QStringLiteral("org.mpris.MediaPlayer2.Player");
    signal << changed;
    signal << QStringList();
    QDBusConnection::sessionBus().send(signal);
}

/// @copydoc MediaPlayer2PlayerAdaptor::Next
void MediaPlayer2PlayerAdaptor::Next()
{
    if (m_controller) emit m_controller->nextRequested();
}

/// @copydoc MediaPlayer2PlayerAdaptor::Previous
void MediaPlayer2PlayerAdaptor::Previous()
{
    if (m_controller) emit m_controller->previousRequested();
}

/// @copydoc MediaPlayer2PlayerAdaptor::Pause
void MediaPlayer2PlayerAdaptor::Pause()
{
    if (m_player) m_player->pause();
}

/// @copydoc MediaPlayer2PlayerAdaptor::PlayPause
void MediaPlayer2PlayerAdaptor::PlayPause()
{
    if (m_player) m_player->togglePlay();
}

/// @copydoc MediaPlayer2PlayerAdaptor::Stop
void MediaPlayer2PlayerAdaptor::Stop()
{
    if (m_player) m_player->stop();
}

/// @copydoc MediaPlayer2PlayerAdaptor::Play
void MediaPlayer2PlayerAdaptor::Play()
{
    if (m_player) m_player->play();
}

/// @copydoc MediaPlayer2PlayerAdaptor::Seek
void MediaPlayer2PlayerAdaptor::Seek(qlonglong offsetUs)
{
    if (!m_player) return;
    const qint64 offsetMs = offsetUs / 1000;
    const qint64 durationMs = m_player->duration();
    const qint64 targetMs = (durationMs > 0)
        ? std::clamp(m_player->position() + offsetMs, 0LL, durationMs)
        : std::max(0LL, m_player->position() + offsetMs);
    m_player->seek(targetMs);
    emit Seeked(targetMs * 1000);
}

/// @copydoc MediaPlayer2PlayerAdaptor::SetPosition
void MediaPlayer2PlayerAdaptor::SetPosition(const QDBusObjectPath &trackId, qlonglong positionUs)
{
    Q_UNUSED(trackId);
    if (!m_player) return;
    const qint64 targetMs = std::max(0LL, static_cast<qint64>(positionUs / 1000));
    m_player->seek(targetMs);
    emit Seeked(targetMs * 1000);
}

/// @copydoc MediaPlayer2PlayerAdaptor::OpenUri
void MediaPlayer2PlayerAdaptor::OpenUri(const QString &uri)
{
    if (m_controller) emit m_controller->openUriRequested(uri);
}

struct LinuxMprisBackend {
    MediaPlayer2Adaptor *rootAdaptor = nullptr;
    MediaPlayer2PlayerAdaptor *playerAdaptor = nullptr;
    QString registeredServiceName;
};

/// @copydoc createLinuxMprisBackend
void *createLinuxMprisBackend(MprisController *controller, PlayerController *player)
{
    auto bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) {
        qWarning() << "[MPRIS] D-Bus session bus is not connected; MPRIS service unavailable.";
        return nullptr;
    }

    auto *backend = new LinuxMprisBackend();
    backend->rootAdaptor = new MediaPlayer2Adaptor(controller);
    backend->playerAdaptor = new MediaPlayer2PlayerAdaptor(controller, player);

    if (!bus.registerObject(QStringLiteral("/org/mpris/MediaPlayer2"), controller)) {
        qWarning() << "[MPRIS] Failed to register D-Bus object /org/mpris/MediaPlayer2:" << bus.lastError().message();
        delete backend;
        return nullptr;
    }

    QString serviceName = QStringLiteral("org.mpris.MediaPlayer2.CassetteCat");
    if (!bus.registerService(serviceName)) {
        const QString fallback = QStringLiteral("org.mpris.MediaPlayer2.CassetteCat.instance%1").arg(QCoreApplication::applicationPid());
        if (!bus.registerService(fallback)) {
            qWarning() << "[MPRIS] Failed to register service" << serviceName << "and fallback" << fallback << ":" << bus.lastError().message();
            bus.unregisterObject(QStringLiteral("/org/mpris/MediaPlayer2"));
            delete backend;
            return nullptr;
        }
        serviceName = fallback;
    }
    backend->registeredServiceName = serviceName;
    qInfo() << "[MPRIS] Registered D-Bus service:" << serviceName;

    return backend;
}

/// @copydoc destroyLinuxMprisBackend
void destroyLinuxMprisBackend(void *backend)
{
    auto *b = static_cast<LinuxMprisBackend *>(backend);
    if (!b) return;
    auto bus = QDBusConnection::sessionBus();
    if (bus.isConnected()) {
        if (!b->registeredServiceName.isEmpty()) {
            bus.unregisterService(b->registeredServiceName);
        }
        bus.unregisterObject(QStringLiteral("/org/mpris/MediaPlayer2"));
    }
    delete b;
}

/// @copydoc notifyLinuxMprisTrackChanged
void notifyLinuxMprisTrackChanged(void *backend)
{
    auto *b = static_cast<LinuxMprisBackend *>(backend);
    if (b && b->playerAdaptor) {
        b->playerAdaptor->notifyPropertiesChanged({{QStringLiteral("Metadata"), b->playerAdaptor->metadata()}});
    }
}

/// @copydoc notifyLinuxMprisPlayingChanged
void notifyLinuxMprisPlayingChanged(void *backend)
{
    auto *b = static_cast<LinuxMprisBackend *>(backend);
    if (b && b->playerAdaptor) {
        b->playerAdaptor->notifyPropertiesChanged({{QStringLiteral("PlaybackStatus"), b->playerAdaptor->playbackStatus()}});
    }
}

/// @copydoc notifyLinuxMprisVolumeChanged
void notifyLinuxMprisVolumeChanged(void *backend)
{
    auto *b = static_cast<LinuxMprisBackend *>(backend);
    if (b && b->playerAdaptor) {
        b->playerAdaptor->notifyPropertiesChanged({{QStringLiteral("Volume"), b->playerAdaptor->volume()}});
    }
}

/// @copydoc notifyLinuxMprisShuffleChanged
void notifyLinuxMprisShuffleChanged(void *backend)
{
    auto *b = static_cast<LinuxMprisBackend *>(backend);
    if (b && b->playerAdaptor) {
        b->playerAdaptor->notifyPropertiesChanged({{QStringLiteral("Shuffle"), b->playerAdaptor->shuffle()}});
    }
}

/// @copydoc notifyLinuxMprisLoopStatusChanged
void notifyLinuxMprisLoopStatusChanged(void *backend)
{
    auto *b = static_cast<LinuxMprisBackend *>(backend);
    if (b && b->playerAdaptor) {
        b->playerAdaptor->notifyPropertiesChanged({{QStringLiteral("LoopStatus"), b->playerAdaptor->loopStatus()}});
    }
}

#endif // CASSETTECAT_HAVE_DBUS
