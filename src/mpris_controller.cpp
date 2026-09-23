#include "mpris_controller.h"
#include "mpris_adaptor.h"
#include "player_controller.h"

#include <QFileInfo>
#include <QStringList>
#include <QUrl>

#ifdef CASSETTECAT_HAVE_DBUS
#include <QDBusObjectPath>
#endif

MprisController::MprisController(PlayerController *player, QObject *parent) : QObject(parent), m_player(player) {
    if (m_player) {
        connect(m_player, &PlayerController::currentTrackChanged, this, &MprisController::onTrackChanged);
        connect(m_player, &PlayerController::durationChanged, this, &MprisController::onTrackChanged);
        connect(m_player, &PlayerController::isPlayingChanged, this, &MprisController::onPlayingChanged);
        connect(m_player, &PlayerController::volumeChanged, this, &MprisController::onVolumeChanged);
        connect(m_player, &PlayerController::shuffleEnabledChanged, this, &MprisController::onShuffleChanged);
        connect(m_player, &PlayerController::positionChanged, this, &MprisController::onPositionChanged);
        connect(this, &MprisController::seekRequested, m_player, &PlayerController::seek);
    }
}

MprisController::~MprisController() {
    destroyLinuxMprisBackend(m_backend);
    m_backend = nullptr;
}

void MprisController::initialize() {
    if (!m_backend) {
        m_backend = createLinuxMprisBackend(this, m_player);
    }
}

int MprisController::repeatMode() const {
    return m_repeatMode;
}

void MprisController::setRepeatMode(int mode) {
    if (m_repeatMode == mode)
        return;
    m_repeatMode = mode;
    emit repeatModeChanged(mode);
    notifyLinuxMprisLoopStatusChanged(m_backend);
}

void MprisController::onTrackChanged() {
    notifyLinuxMprisTrackChanged(m_backend);
}

void MprisController::onPlayingChanged() {
    notifyLinuxMprisPlayingChanged(m_backend);
}

void MprisController::onVolumeChanged() {
    notifyLinuxMprisVolumeChanged(m_backend);
}

void MprisController::onShuffleChanged() {
    notifyLinuxMprisShuffleChanged(m_backend);
}

void MprisController::onPositionChanged() {}

QString MprisController::playbackStatusString(bool isPlaying, bool hasTrack) {
    if (isPlaying)
        return QStringLiteral("Playing");
    if (hasTrack)
        return QStringLiteral("Paused");
    return QStringLiteral("Stopped");
}

QString MprisController::loopStatusString(int repeatMode) {
    switch (repeatMode) {
    case 2:
        return QStringLiteral("Track");
    case 1:
        return QStringLiteral("Playlist");
    default:
        return QStringLiteral("None");
    }
}

int MprisController::loopStatusToRepeatMode(const QString &loopStatus) {
    if (loopStatus.compare(QLatin1String("Track"), Qt::CaseInsensitive) == 0)
        return 2;
    if (loopStatus.compare(QLatin1String("Playlist"), Qt::CaseInsensitive) == 0)
        return 1;
    return 0;
}

QVariantMap MprisController::buildMetadata(const QVariantMap &track, qint64 durationMs) {
    QVariantMap meta;
    if (track.isEmpty()) {
#ifdef CASSETTECAT_HAVE_DBUS
        meta.insert(QStringLiteral("mpris:trackid"),
                    QVariant::fromValue(QDBusObjectPath(QStringLiteral("/org/mpris/MediaPlayer2/TrackList/NoTrack"))));
#else
        meta.insert(QStringLiteral("mpris:trackid"), QStringLiteral("/org/mpris/MediaPlayer2/TrackList/NoTrack"));
#endif
        return meta;
    }

#ifdef CASSETTECAT_HAVE_DBUS
    meta.insert(QStringLiteral("mpris:trackid"),
                QVariant::fromValue(QDBusObjectPath(QStringLiteral("/org/mpris/MediaPlayer2/Track/Current"))));
#else
    meta.insert(QStringLiteral("mpris:trackid"), QStringLiteral("/org/mpris/MediaPlayer2/Track/Current"));
#endif

    const QString title = track.value(QStringLiteral("title")).toString().trimmed().isEmpty()
                              ? track.value(QStringLiteral("fileName")).toString()
                              : track.value(QStringLiteral("title")).toString();
    if (!title.isEmpty()) {
        meta.insert(QStringLiteral("xesam:title"), title);
    }

    const QString artist = track.value(QStringLiteral("artist")).toString().trimmed();
    if (!artist.isEmpty()) {
        const QStringList artistList{artist};
        meta.insert(QStringLiteral("xesam:artist"), artistList);
        meta.insert(QStringLiteral("xesam:albumArtist"), artistList);
    }

    const QString album = track.value(QStringLiteral("album")).toString().trimmed();
    if (!album.isEmpty()) {
        meta.insert(QStringLiteral("xesam:album"), album);
    }

    if (durationMs > 0) {
        meta.insert(QStringLiteral("mpris:length"), static_cast<qlonglong>(durationMs) * 1000);
    }

    const QString artworkUrl = track.value(QStringLiteral("artworkUrl")).toString().trimmed();
    if (!artworkUrl.isEmpty()) {
        if (artworkUrl.startsWith(QLatin1String("http://")) || artworkUrl.startsWith(QLatin1String("https://")) ||
            artworkUrl.startsWith(QLatin1String("file://"))) {
            meta.insert(QStringLiteral("mpris:artUrl"), artworkUrl);
        } else if (QFileInfo::exists(artworkUrl)) {
            meta.insert(QStringLiteral("mpris:artUrl"), QUrl::fromLocalFile(artworkUrl).toString());
        }
    }

    const QString filePath = track.value(QStringLiteral("filePath")).toString().trimmed();
    const QString streamUrl = track.value(QStringLiteral("streamUrl")).toString().trimmed();
    if (!filePath.isEmpty()) {
        meta.insert(QStringLiteral("xesam:url"), QUrl::fromLocalFile(filePath).toString());
    } else if (!streamUrl.isEmpty()) {
        meta.insert(QStringLiteral("xesam:url"), streamUrl);
    }

    return meta;
}

bool MprisController::selfCheck() {
    if (playbackStatusString(true, true) != QLatin1String("Playing"))
        return false;
    if (playbackStatusString(false, true) != QLatin1String("Paused"))
        return false;
    if (playbackStatusString(false, false) != QLatin1String("Stopped"))
        return false;

    if (loopStatusString(0) != QLatin1String("None") || loopStatusToRepeatMode(QStringLiteral("None")) != 0)
        return false;
    if (loopStatusString(1) != QLatin1String("Playlist") || loopStatusToRepeatMode(QStringLiteral("Playlist")) != 1)
        return false;
    if (loopStatusString(2) != QLatin1String("Track") || loopStatusToRepeatMode(QStringLiteral("Track")) != 2)
        return false;

    const QVariantMap emptyMeta = buildMetadata(QVariantMap(), 0);
#ifdef CASSETTECAT_HAVE_DBUS
    if (emptyMeta.value(QStringLiteral("mpris:trackid")).value<QDBusObjectPath>().path() !=
        QLatin1String("/org/mpris/MediaPlayer2/TrackList/NoTrack")) {
        return false;
    }
#else
    if (emptyMeta.value(QStringLiteral("mpris:trackid")).toString() !=
        QLatin1String("/org/mpris/MediaPlayer2/TrackList/NoTrack")) {
        return false;
    }
#endif

    QVariantMap sampleTrack;
    sampleTrack.insert(QStringLiteral("title"), QStringLiteral("Test Song"));
    sampleTrack.insert(QStringLiteral("artist"), QStringLiteral("Test Artist"));
    sampleTrack.insert(QStringLiteral("album"), QStringLiteral("Test Album"));
    sampleTrack.insert(QStringLiteral("filePath"), QStringLiteral("/music/test.flac"));
    sampleTrack.insert(QStringLiteral("artworkUrl"), QStringLiteral("https://example.com/cover.jpg"));

    const QVariantMap fullMeta = buildMetadata(sampleTrack, 120000);
#ifdef CASSETTECAT_HAVE_DBUS
    if (fullMeta.value(QStringLiteral("mpris:trackid")).value<QDBusObjectPath>().path() !=
        QLatin1String("/org/mpris/MediaPlayer2/Track/Current"))
        return false;
#else
    if (fullMeta.value(QStringLiteral("mpris:trackid")).toString() !=
        QLatin1String("/org/mpris/MediaPlayer2/Track/Current"))
        return false;
#endif
    if (fullMeta.value(QStringLiteral("xesam:title")).toString() != QLatin1String("Test Song"))
        return false;
    if (fullMeta.value(QStringLiteral("xesam:album")).toString() != QLatin1String("Test Album"))
        return false;
    if (fullMeta.value(QStringLiteral("xesam:artist")).toStringList() != QStringList{QStringLiteral("Test Artist")})
        return false;
    if (fullMeta.value(QStringLiteral("mpris:length")).toLongLong() != 120000000LL)
        return false;
    if (fullMeta.value(QStringLiteral("mpris:artUrl")).toString() != QLatin1String("https://example.com/cover.jpg"))
        return false;
    if (fullMeta.value(QStringLiteral("xesam:url")).toString() !=
        QUrl::fromLocalFile(QStringLiteral("/music/test.flac")).toString())
        return false;

    return true;
}
