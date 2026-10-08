#include "player_controller.h"

#include "app_paths.h"
#include "audio_pipeline.h"
#include "app_settings.h"
#include "audio_metadata.h"
#include "streaming.h"

#include <QAudioBuffer>
#include <QAudioBufferOutput>
#include <QAudioDevice>
#include <QAudioFormat>
#include <QMediaDevices>
#include <QBuffer>
#include <QDataStream>
#include <QElapsedTimer>
#include <QEventLoop>
#include <QFile>
#include <QMediaPlayer>
#include <QQuickWindow>
#include <QSettings>
#include <QTemporaryDir>
#include <QTimer>

#ifdef _WIN32
#include <windows.h>
#endif

#include <algorithm>
#include <cmath>
#include <utility>

namespace {

bool isNetworkStream(const QUrl &url) {
    return url.scheme() == QStringLiteral("http") || url.scheme() == QStringLiteral("https");
}

} // namespace

PlayerController::PlayerController(QObject *parent, StreamingController *streaming)
    : QObject(parent), m_streaming(streaming), m_pipeline(new AudioPipeline(this)),
      m_mediaDevices(new QMediaDevices(this)), m_player(new QMediaPlayer(this)) {
    m_player->setAudioBufferOutput(m_pipeline->addSource());
    m_pipeline->setMeteredSource(m_player->audioBufferOutput());
    m_replayGainMode = SettingsController::globalValue("player/replayGainMode", QStringLiteral("off")).toString();
    m_baseVolume = std::clamp(SettingsController::globalValue("player/volume", 1.0f).toFloat(), 0.0f, 1.0f);
    if (SettingsController::globalValue("player/volumeLimitEnabled", false).toBool()) {
        const int maxPercent =
            std::clamp(SettingsController::globalValue("player/maxVolumePercent", 80).toInt(), 10, 100);
        m_baseVolume = (std::min)(m_baseVolume, maxPercent / 100.0f);
    }
    applyEffectiveVolume();
    connect(m_mediaDevices, &QMediaDevices::audioOutputsChanged, this, [this] {
        emit audioOutputsChanged();
        emit audioDeviceChanged();
    });

    m_fadingPlayer = new QMediaPlayer(this);
    m_fadingPlayer->setAudioBufferOutput(m_pipeline->addSource());
    m_pipeline->setGain(m_fadingPlayer->audioBufferOutput(), 0.0f);
    connectPlayer(m_player);
    connectPlayer(m_fadingPlayer);
    setEqualizer(SettingsController::globalValue("player/equalizer").toMap());

    connect(m_pipeline, &AudioPipeline::levelReceived, this, [this](double rms) {
        if (m_meterEnabled)
            setAudioLevel(std::clamp(rms * 3.0, 0.0, 1.0));
    });

    m_fadeTimer = new QTimer(this);
    m_fadeTimer->setInterval(40);
    connect(m_fadeTimer, &QTimer::timeout, this, [this] {
        const float progress = std::min(1.0f, float(m_fadeClock.elapsed()) / float(std::max(1, m_activeFadeMs)));
        m_fadeIn = progress;
        applyEffectiveVolume();
        m_pipeline->setGain(m_fadingPlayer->audioBufferOutput(), m_fadingGain * m_baseVolume * (1.0f - progress));
        if (progress >= 1.0f)
            finishCrossfade();
    });
}

void PlayerController::connectPlayer(QMediaPlayer *player) {
    connect(player, &QMediaPlayer::playbackStateChanged, this, [this, player](QMediaPlayer::PlaybackState state) {
        if (player != m_player)
            return;
        const bool wasPlaying = m_isPlaying;
        const bool playing = (state == QMediaPlayer::PlayingState);
        qInfo().noquote() << "[PLAYER] state=" << static_cast<int>(state) << "positionMs=" << m_player->position()
                          << "track=" << m_currentTrack.value("filePath").toString();
        // Between two songs the player stops for a moment; that only counts as stopping if no song follows.
        const bool naturalEnd =
            state == QMediaPlayer::StoppedState && m_player->mediaStatus() == QMediaPlayer::EndOfMedia;
        if (playing)
            m_switchingTrack = false;
        if (!m_switchingTrack && !naturalEnd)
            setPlaying(playing);
        if (playing) {
            m_pipeline->setPaused(false);
        } else if (m_switchingTrack) {
            // The device keeps running, so the next song follows without the device stopping and starting.
        } else if (!naturalEnd) {
            m_pipeline->setPaused(true);
        } else {
            // At a song's natural end the queued audio plays out while the next song opens.
            QTimer::singleShot(1500, this, [this] {
                if (m_player->playbackState() != QMediaPlayer::PlayingState && !m_fadeTimer->isActive()) {
                    setPlaying(false);
                    m_pipeline->setPaused(true);
                }
            });
        }
        if (state == QMediaPlayer::StoppedState && !m_pauseExpected && !m_currentTrack.isEmpty()) {
            const QString stoppedTrackPath = m_currentTrack.value("filePath").toString();
            QTimer::singleShot(75, this, [this, stoppedTrackPath] {
                if (m_pauseExpected || m_currentTrack.value("filePath").toString() != stoppedTrackPath ||
                    m_player->playbackState() == QMediaPlayer::PlayingState ||
                    m_player->mediaStatus() == QMediaPlayer::EndOfMedia)
                    return;
                qWarning().noquote() << "[PLAYER] unexpected backend stop; resuming positionMs="
                                     << m_player->position();
                m_player->play();
            });
        }
        if (state == QMediaPlayer::PausedState && wasPlaying && !m_pauseExpected &&
            m_player->mediaStatus() != QMediaPlayer::EndOfMedia) {
            qWarning() << "[PLAYER] unexpected backend pause; resuming";
            QTimer::singleShot(0, m_player, &QMediaPlayer::play);
        }
        if (state == QMediaPlayer::PlayingState) {
            m_pauseExpected = false;
        }
        if (state == QMediaPlayer::PausedState)
            m_pauseExpected = false;
    });

    connect(player, &QMediaPlayer::mediaStatusChanged, this, [this, player](QMediaPlayer::MediaStatus status) {
        if (player != m_player)
            return;
        qInfo().noquote() << "[PLAYER] mediaStatus=" << static_cast<int>(status)
                          << "positionMs=" << m_player->position();
        if (status == QMediaPlayer::LoadedMedia || status == QMediaPlayer::BufferedMedia) {
            if (m_pendingRestorePositionMs > 0) {
                const qint64 targetPos = m_pendingRestorePositionMs;
                m_pendingRestorePositionMs = 0;
                m_player->setPosition(targetPos);
                m_position = targetPos;
                emit positionChanged();
            }
        }
        if (status == QMediaPlayer::EndOfMedia) {
            emit trackEnded();
        }
    });

    connect(player, &QMediaPlayer::errorOccurred, this, [this, player](QMediaPlayer::Error, const QString &message) {
        if (player != m_player)
            return;
        qWarning().noquote() << "[PLAYER] error positionMs=" << m_player->position() << message;
        if (m_switchingTrack) {
            m_switchingTrack = false;
            setPlaying(false);
            m_pipeline->setPaused(true);
        }
        if (m_error == message)
            return;
        m_error = message;
        emit errorChanged();
    });

    connect(player, &QMediaPlayer::positionChanged, this, [this, player](qint64 pos) {
        if (player != m_player)
            return;
        if (m_pendingRestorePositionMs > 0 && pos == 0) {
            return;
        }
        m_position = pos;
        emit positionChanged();
        if (m_crossfadeMs > 0 && !m_crossfadeReady && m_isPlaying && m_duration > 2 * m_crossfadeMs &&
            pos >= m_duration - m_crossfadeMs && !isNetworkStream(m_player->source())) {
            m_crossfadeReady = true;
            emit crossfadeReady();
        }
    });

    connect(player, &QMediaPlayer::durationChanged, this, [this, player](qint64 dur) {
        if (player != m_player)
            return;
        m_duration = dur;
        emit durationChanged();
    });
}

QVariantMap PlayerController::currentTrack() const {
    return m_currentTrack;
}
QString PlayerController::currentLyrics() const {
    return m_currentLyrics;
}
bool PlayerController::isPlaying() const {
    return m_isPlaying;
}
bool PlayerController::shuffleEnabled() const {
    return m_shuffleEnabled;
}
qreal PlayerController::audioLevel() const {
    return m_audioLevel;
}
bool PlayerController::audioMeterEnabled() const {
    return m_meterEnabled;
}
qint64 PlayerController::position() const {
    return m_position;
}
qint64 PlayerController::duration() const {
    return m_duration;
}
QString PlayerController::formattedPosition() const {
    return formatDuration(static_cast<int>(m_position / 1000));
}
QString PlayerController::formattedDuration() const {
    return formatDuration(static_cast<int>(m_duration / 1000));
}
float PlayerController::volume() const {
    return m_baseVolume;
}
QString PlayerController::replayGainMode() const {
    return m_replayGainMode;
}
QVariantList PlayerController::audioOutputs() const {
    QVariantList outputs;
    QVariantMap defaultDevice;
    defaultDevice.insert(QStringLiteral("value"), QString());
    defaultDevice.insert(QStringLiteral("label"), QStringLiteral("System Default"));
    outputs.append(defaultDevice);

    for (const QAudioDevice &device : QMediaDevices::audioOutputs()) {
        QVariantMap output;
        output.insert(QStringLiteral("value"), QString::fromLatin1(device.id().toHex()));
        output.insert(QStringLiteral("label"), device.description());
        outputs.append(output);
    }
    return outputs;
}

QString PlayerController::audioDeviceId() const {
    const QByteArray currentId = m_pipeline->device().id();
    if (currentId.isEmpty() || currentId == QMediaDevices::defaultAudioOutput().id()) {
        return QString();
    }
    return QString::fromLatin1(currentId.toHex());
}

bool PlayerController::setAudioDevice(const QString &id) {
    if (id.isEmpty()) {
        m_pipeline->setDevice(QMediaDevices::defaultAudioOutput());
        emit audioDeviceChanged();
        return true;
    }
    for (const QAudioDevice &device : QMediaDevices::audioOutputs()) {
        if (QString::fromLatin1(device.id().toHex()) != id)
            continue;
        m_pipeline->setDevice(device);
        emit audioDeviceChanged();
        return true;
    }
    return false;
}
QString PlayerController::error() const {
    return m_error;
}

void PlayerController::setAudioMeterEnabled(bool enabled) {
    if (enabled == audioMeterEnabled())
        return;
    m_meterEnabled = enabled;
    if (!enabled)
        setAudioLevel(0.0);
    emit audioMeterEnabledChanged();
}

bool PlayerController::selfCheck() {
    QBuffer source;
    PlayerController player;
    if (player.audioMeterEnabled())
        return false;
    if (!isNetworkStream(QUrl(QStringLiteral("https://radio.example/live"))))
        return false;
    if (isNetworkStream(QUrl::fromLocalFile(QStringLiteral("C:/music/track.flac"))))
        return false;

    if (!AudioPipeline::selfCheck())
        return false;
    emit player.m_pipeline->levelReceived(0.25);
    if (player.audioLevel() != 0.0)
        return false;
    for (int i = 0; i < 3; ++i) {
        player.setAudioMeterEnabled(true);
        emit player.m_pipeline->levelReceived(0.25);
        if (!player.audioMeterEnabled() || qAbs(player.audioLevel() - 0.75) > 0.001)
            return false;
        player.setAudioMeterEnabled(false);
        emit player.m_pipeline->levelReceived(0.25);
        if (player.audioMeterEnabled() || player.audioLevel() != 0.0)
            return false;
    }
    if (!player.m_player->audioBufferOutput() || !player.m_fadingPlayer->audioBufferOutput())
        return false;
    player.setReplayGainMode(QStringLiteral("track"));
    if (player.replayGainMode() != QStringLiteral("track"))
        return false;
    player.setReplayGainMode(QStringLiteral("album"));
    if (player.replayGainMode() != QStringLiteral("album"))
        return false;
    player.setReplayGainMode(QStringLiteral("off"));
    if (player.replayGainMode() != QStringLiteral("off"))
        return false;
    if (extractReplayGain(QString()) != 0.0f)
        return false;

    PlayerController restored;
    const QString restoredPath = QStringLiteral("C:/music/restored.flac");
    restored.restoreTrack({{"filePath", restoredPath}, {"durationSeconds", 200}}, 42000);
    if (!restored.m_player->source().isEmpty() || restored.position() != 42000 || restored.duration() != 200000)
        return false;
    restored.seek(50000);
    restored.openDeferredSource();
    if (restored.m_pendingRestorePositionMs != 50000 ||
        restored.m_player->source() != QUrl::fromLocalFile(restoredPath))
        return false;

    QByteArray pcm(128000, '\x20');
    QByteArray wave;
    QDataStream stream(&wave, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    stream.writeRawData("RIFF", 4);
    stream << quint32(36 + pcm.size());
    stream.writeRawData("WAVEfmt ", 8);
    stream << quint32(16) << quint16(1) << quint16(1) << quint32(8000) << quint32(16000) << quint16(2) << quint16(16);
    stream.writeRawData("data", 4);
    stream << quint32(pcm.size());
    stream.writeRawData(pcm.constData(), pcm.size());

    // TagLib cannot open a QTemporaryFile path on Windows, so the file goes in a temporary folder.
    const QTemporaryDir waveDir;
    QFile waveFile(waveDir.filePath("format-check.wav"));
    if (!waveFile.open(QIODevice::WriteOnly) || waveFile.write(wave) != wave.size())
        return false;
    waveFile.close();
    const QVariantMap waveFormat = readAudioFormat(waveFile.fileName());
    if (waveFormat.value("label") != "16-bit · 8 kHz · WAV" || waveFormat.value("badgeLabel") != "Lossless" ||
        waveFormat.value("isHiRes").toBool())
        return false;

    source.setData(wave);
    source.open(QIODevice::ReadOnly);

    const auto waitFor = [](auto condition) {
        QEventLoop loop;
        QTimer poll;
        QObject::connect(&poll, &QTimer::timeout, &loop, [&] {
            if (condition())
                loop.quit();
        });
        poll.start(20);
        QTimer::singleShot(3000, &loop, &QEventLoop::quit);
        loop.exec();
        return condition();
    };

    player.m_baseVolume = 0.0f;
    player.applyEffectiveVolume();
    player.m_player->setSourceDevice(&source, QUrl("meter-check.wav"));
    player.m_player->play();
    if (!waitFor([&] { return player.position() > 100; }))
        return false;
    player.setAudioMeterEnabled(true);
    if (!waitFor([&] { return player.audioLevel() > 0.1; }))
        return false;
    const qint64 position = player.position();
    int crossfadeSignals = 0;
    connect(&player, &PlayerController::crossfadeReady, [&] { ++crossfadeSignals; });
    player.m_crossfadeMs = 2000;
    player.m_player->setPosition(6500);
    if (!waitFor([&] { return crossfadeSignals == 1 && player.position() > 7000; }) || crossfadeSignals != 1)
        return false;
    player.m_player->setPosition(position);
    player.setAudioMeterEnabled(false);
    if (!waitFor([&] { return player.position() > position + 100; }))
        return false;
    return player.audioLevel() == 0.0 && player.error().isEmpty();
}

QString PlayerController::getLyrics(const QString &filePath) const {
    if (StreamingController::isRemotePath(filePath)) {
        return {};
    }
    return extractEmbeddedLyrics(filePath);
}

void PlayerController::setCurrentLyrics(const QString &lyrics) {
    if (m_currentLyrics == lyrics)
        return;
    m_currentLyrics = lyrics;
    emit currentLyricsChanged();
}

void PlayerController::setShuffleEnabled(bool enabled) {
    if (m_shuffleEnabled != enabled) {
        m_shuffleEnabled = enabled;
        emit shuffleEnabledChanged();
    }
}

void PlayerController::toggleShuffle() {
    setShuffleEnabled(!m_shuffleEnabled);
}

void PlayerController::setVolume(float vol) {
    float clamped = std::clamp(vol, 0.0f, 1.0f);
    if (SettingsController::globalValue("player/volumeLimitEnabled", false).toBool()) {
        const int maxPercent =
            std::clamp(SettingsController::globalValue("player/maxVolumePercent", 80).toInt(), 10, 100);
        clamped = (std::min)(clamped, maxPercent / 100.0f);
    }
    const bool changed = !qFuzzyCompare(m_baseVolume, clamped);
    m_baseVolume = clamped;
    applyEffectiveVolume();
    if (changed) {
        emit volumeChanged();
    }
}

void PlayerController::applyEffectiveVolume() {
    m_pipeline->setGain(m_player->audioBufferOutput(), effectiveVolume() * m_fadeIn);
}

float PlayerController::effectiveVolume() const {
    float factor = 1.0f;
    if (m_replayGainMode != QStringLiteral("off") && !qFuzzyIsNull(m_currentReplayGainDb)) {
        factor = std::pow(10.0f, m_currentReplayGainDb / 20.0f);
        factor = std::clamp(factor, 0.05f, 2.0f);
    }
    float maxCeiling = 1.0f;
    if (SettingsController::globalValue("player/volumeLimitEnabled", false).toBool()) {
        const int maxPercent =
            std::clamp(SettingsController::globalValue("player/maxVolumePercent", 80).toInt(), 10, 100);
        maxCeiling = maxPercent / 100.0f;
    }
    return std::clamp(m_baseVolume * factor, 0.0f, maxCeiling);
}

void PlayerController::finishCrossfade() {
    m_fadeTimer->stop();
    m_fadingPlayer->stop();
    m_fadingPlayer->setSource(QUrl());
    m_pipeline->setGain(m_fadingPlayer->audioBufferOutput(), 0.0f);
    m_pipeline->clear(m_fadingPlayer->audioBufferOutput());
    m_fadeIn = 1.0f;
    applyEffectiveVolume();
}

void PlayerController::setReplayGainMode(const QString &mode) {
    if (m_replayGainMode == mode)
        return;
    m_replayGainMode = mode;
    const QString filePath = m_currentTrack.value("filePath").toString();
    if (m_replayGainMode != QStringLiteral("off") && !filePath.isEmpty() &&
        !StreamingController::isRemotePath(filePath)) {
        m_currentReplayGainDb = extractReplayGain(filePath, m_replayGainMode == QStringLiteral("album"));
    } else {
        m_currentReplayGainDb = 0.0f;
    }
    applyEffectiveVolume();
    emit replayGainModeChanged();
}

void PlayerController::setEqualizer(const QVariantMap &settings) {
    const auto clampDb = [](const QVariant &value) { return std::clamp(value.toFloat(), -12.0f, 12.0f); };
    const QVariantList requested = settings.value("bands").toList();
    std::array<float, AudioPipeline::kBandCount> bands{};
    QVariantList saved;
    for (int i = 0; i < AudioPipeline::kBandCount; ++i) {
        bands[i] = requested.size() == AudioPipeline::kBandCount ? clampDb(requested[i]) : 0.0f;
        saved.append(bands[i]);
    }
    const bool enabled = settings.value("enabled").toBool();
    const float preamp = clampDb(settings.value("preamp"));
    m_pipeline->setEqualizer(enabled, bands, preamp);
    const QVariantMap normalized{{"enabled", enabled},
                                 {"preset", settings.value("preset", QStringLiteral("Flat")).toString()},
                                 {"preamp", preamp},
                                 {"bands", saved}};
    if (normalized == m_equalizer)
        return;
    m_equalizer = normalized;
    SettingsController::setGlobalValue("player/equalizer", m_equalizer);
    emit equalizerChanged();
}

void PlayerController::restoreTrack(const QVariantMap &track, qint64 positionMs) {
    // Opening media costs tens of MB in the backend, so a restored track waits until playback is requested.
    if (!loadTrack(track))
        return;
    // stop() keeps the previous file open; clearing the source releases it until playback starts.
    m_player->setSource(QUrl());
    m_pendingRestorePositionMs = positionMs;
    m_position = positionMs;
    emit positionChanged();
    m_duration = track.value("durationSeconds").toLongLong() * 1000;
    emit durationChanged();
}

bool PlayerController::playTrack(const QVariantMap &track) {
    // The next track fades in on the other player while this one plays out: over the crossfade at a track's natural
    // end, and briefly when the song is changed mid-play so the switch isn't a hard cut.
    constexpr int songChangeFadeMs = 300;
    const bool playing = m_player->playbackState() == QMediaPlayer::PlayingState;
    const bool naturalEnd = m_crossfadeReady && m_crossfadeMs > 0 && m_position >= m_duration - m_crossfadeMs;
    const bool crossfade = playing && !isNetworkStream(m_player->source());
    m_activeFadeMs = naturalEnd ? m_crossfadeMs : songChangeFadeMs;
    if (m_fadeTimer->isActive())
        finishCrossfade();
    if (crossfade) {
        // The outgoing track keeps its own ReplayGain but follows volume changes made during the fade.
        m_fadingGain = m_baseVolume > 0.0f ? effectiveVolume() * m_fadeIn / m_baseVolume : 1.0f;
        std::swap(m_player, m_fadingPlayer);
        m_pipeline->setMeteredSource(m_player->audioBufferOutput());
        m_fadeIn = 0.0f;
    }
    m_pendingRestorePositionMs = 0;
    m_switchingTrack = m_isPlaying;
    if (!loadTrack(track)) {
        m_switchingTrack = false;
        if (crossfade) {
            std::swap(m_player, m_fadingPlayer);
            m_pipeline->setMeteredSource(m_player->audioBufferOutput());
            m_pipeline->setGain(m_fadingPlayer->audioBufferOutput(), 0.0f);
            m_fadeIn = 1.0f;
            applyEffectiveVolume();
        }
        return false;
    }
    openDeferredSource();
    m_pauseExpected = false;
    m_player->play();
    if (crossfade) {
        m_fadeClock.start();
        m_fadeTimer->start();
    }
    return true;
}

bool PlayerController::loadTrack(const QVariantMap &track) {
    const QString filePath = track.value("filePath").toString();
    if (filePath.isEmpty())
        return false;
    const QUrl mediaSource = resolveMediaSource(track);
    if (mediaSource.isEmpty())
        return false;

    m_currentTrack = track;
    m_crossfadeReady = false;
    if (!m_error.isEmpty()) {
        m_error.clear();
        emit errorChanged();
    }
    if (m_currentTrack.value("artworkUrl").toString().isEmpty() && !StreamingController::isRemotePath(filePath)) {
        // ponytail: load embedded artwork only for the current track; add async thumbnailing if browsing embedded art
        // needs it.
        m_currentTrack.insert("artworkUrl", extractEmbeddedArtwork(filePath, kFullArtworkSize));
    }
    m_currentLyrics = track.value("lyrics").toString();
    if (m_currentLyrics.isEmpty() && !StreamingController::isRemotePath(filePath)) {
        m_currentLyrics = extractEmbeddedLyrics(filePath);
    }
    m_audioFormat = mediaSource.isLocalFile() ? readAudioFormat(filePath) : QVariantMap();
    emit currentTrackChanged();
    emit currentLyricsChanged();

    m_position = 0;
    emit positionChanged();
    if (m_replayGainMode != QStringLiteral("off") && !StreamingController::isRemotePath(filePath)) {
        m_currentReplayGainDb = extractReplayGain(filePath, m_replayGainMode == QStringLiteral("album"));
    } else {
        m_currentReplayGainDb = 0.0f;
    }
    applyEffectiveVolume();
    // After a natural end the last of the previous song is still queued; the new one follows it without a gap.
    if (m_player->mediaStatus() != QMediaPlayer::EndOfMedia)
        m_pipeline->clear(m_player->audioBufferOutput());
    m_pauseExpected = true;
    m_player->stop();
    m_deferredSource = mediaSource;
    return true;
}

void PlayerController::openDeferredSource() {
    if (m_deferredSource.isEmpty())
        return;
    m_player->setSource(std::exchange(m_deferredSource, QUrl()));
    m_player->setActiveVideoTrack(-1);
}

void PlayerController::togglePlay() {
    if (!m_deferredSource.isEmpty()) {
        play();
    } else if (m_player->playbackState() == QMediaPlayer::PlayingState) {
        qInfo().noquote() << "[PLAYER] pause source=toggle positionMs=" << m_player->position();
        if (m_fadeTimer->isActive())
            finishCrossfade();
        m_pauseExpected = true;
        m_player->pause();
    } else if (m_player->playbackState() == QMediaPlayer::PausedState) {
        m_player->play();
    } else if (!m_currentTrack.isEmpty()) {
        playTrack(m_currentTrack);
    }
}

void PlayerController::play() {
    if (!m_deferredSource.isEmpty()) {
        m_pauseExpected = false;
        openDeferredSource();
    }
    if (m_player->playbackState() != QMediaPlayer::PlayingState)
        m_player->play();
}

void PlayerController::pause() {
    qInfo().noquote() << "[PLAYER] pause requested positionMs=" << m_player->position();
    m_switchingTrack = false;
    if (m_fadeTimer->isActive())
        finishCrossfade();
    m_pauseExpected = true;
    m_player->pause();
}

void PlayerController::stop() {
    if (m_fadeTimer->isActive())
        finishCrossfade();
    m_switchingTrack = false;
    m_pauseExpected = true;
    m_player->stop();
    m_pipeline->clear(m_player->audioBufferOutput());
    // Stopping between two songs changes no player state, so it is reported here.
    setPlaying(false);
    m_pipeline->setPaused(true);
}

void PlayerController::setPlaying(bool playing) {
    if (!playing)
        setAudioLevel(0.0);
    if (m_isPlaying == playing)
        return;
    m_isPlaying = playing;
#ifdef _WIN32
    SetThreadExecutionState(ES_CONTINUOUS | (playing ? ES_SYSTEM_REQUIRED : 0));
#endif
    emit isPlayingChanged();
}

void PlayerController::seek(qint64 positionMs) {
    // The backend drops a seek made while the file is still opening, so it is applied once loaded.
    if (!m_deferredSource.isEmpty() || m_player->mediaStatus() == QMediaPlayer::LoadingMedia) {
        m_pendingRestorePositionMs = positionMs;
        m_position = positionMs;
        emit positionChanged();
        return;
    }
    m_pendingRestorePositionMs = 0;
    m_pipeline->clear(m_player->audioBufferOutput());
    m_player->setPosition(positionMs);
}

void PlayerController::setWindowAlwaysOnTop(QQuickWindow *win, bool onTop) {
#ifdef _WIN32
    if (win) {
        HWND hwnd = reinterpret_cast<HWND>(win->winId());
        if (hwnd) {
            SetWindowPos(hwnd, onTop ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0,
                         SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        }
    }
#else
    Q_UNUSED(win);
    Q_UNUSED(onTop);
#endif
}

QUrl PlayerController::resolveMediaSource(const QVariantMap &track) const {
    const QString filePath = track.value("filePath").toString();
    const QString remoteId = track.value("remoteId").toString();
    if (!remoteId.isEmpty() && m_streaming) {
        return m_streaming->streamSourceFor(track.value("source").toString(), remoteId);
    }
    if (StreamingController::isRemotePath(filePath)) {
        return {};
    }
    const QUrl url(filePath);
    if (isNetworkStream(url)) {
        if (SettingsController::globalValue("network/offlineBlackout", false).toBool())
            return {};
        return url;
    }
    return QUrl::fromLocalFile(filePath);
}

void PlayerController::setAudioLevel(qreal level) {
    if (qAbs(m_audioLevel - level) < 0.01)
        return;
    m_audioLevel = level;
    emit audioLevelChanged();
}

void PlayerController::updateCurrentTrackArtwork(const QString &artworkPath) {
    if (m_currentTrack.isEmpty())
        return;
    m_currentTrack.insert("artworkUrl", artworkPath);
    emit currentTrackChanged();
}

void PlayerController::updateCurrentTrackMetadata(const QVariantMap &track) {
    if (m_currentTrack.isEmpty() || track.value("filePath") != m_currentTrack.value("filePath"))
        return;
    m_currentTrack = track;
    setCurrentLyrics(track.value("lyrics").toString());
    emit currentTrackChanged();
}

void PlayerController::requestPlayback(const QVariantList &tracks, int startIndex) {
    emit playbackRequested(tracks, startIndex);
}
