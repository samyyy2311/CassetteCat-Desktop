#include "player_controller.h"

#include "app_paths.h"
#include "audio_metadata.h"
#include "streaming.h"

#include <QAudioBuffer>
#include <QAudioBufferOutput>
#include <QAudioFormat>
#include <QAudioOutput>
#include <QBuffer>
#include <QDataStream>
#include <QEventLoop>
#include <QMediaPlayer>
#include <QQuickWindow>
#include <QSettings>
#include <QTimer>

#ifdef _WIN32
#include <windows.h>
#endif

#include <algorithm>
#include <cmath>

namespace {

bool isNetworkStream(const QUrl &url)
{
    return url.scheme() == QStringLiteral("http") || url.scheme() == QStringLiteral("https");
}

}

PlayerController::PlayerController(QObject *parent, StreamingController *streaming)
    : QObject(parent)
    , m_streaming(streaming)
    , m_audioOutput(new QAudioOutput(this))
    , m_bufferOutput(new QAudioBufferOutput(this))
    , m_player(new QMediaPlayer(this))
{
    m_player->setAudioOutput(m_audioOutput);
    m_audioOutput->setVolume(1.0f);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState state) {
        const bool playing = (state == QMediaPlayer::PlayingState);
        if (m_isPlaying != playing) {
            m_isPlaying = playing;
            emit isPlayingChanged();
        }
        if (!playing) setAudioLevel(0.0);
    });

    connect(m_bufferOutput, &QAudioBufferOutput::audioBufferReceived, this, [this](const QAudioBuffer &buffer) {
        if (!audioMeterEnabled()) return;
        const int sampleCount = buffer.sampleCount();
        if (sampleCount <= 0) return;

        double sum = 0.0;
        if (buffer.format().sampleFormat() == QAudioFormat::Float) {
            const auto *samples = buffer.constData<float>();
            for (int i = 0; i < sampleCount; ++i) sum += samples[i] * samples[i];
        } else if (buffer.format().sampleFormat() == QAudioFormat::Int16) {
            const auto *samples = buffer.constData<qint16>();
            for (int i = 0; i < sampleCount; ++i) {
                const double sample = samples[i] / 32768.0;
                sum += sample * sample;
            }
        } else {
            return;
        }
        setAudioLevel(std::clamp(std::sqrt(sum / sampleCount) * 3.0, 0.0, 1.0));
    });

    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
        if (status == QMediaPlayer::EndOfMedia) {
            emit trackEnded();
        }
    });

    connect(m_player, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error, const QString &message) {
        if (m_error == message) return;
        m_error = message;
        emit errorChanged();
    });

    connect(m_player, &QMediaPlayer::positionChanged, this, [this](qint64 pos) {
        m_position = pos;
        emit positionChanged();
    });

    connect(m_player, &QMediaPlayer::durationChanged, this, [this](qint64 dur) {
        m_duration = dur;
        emit durationChanged();
    });
}

QVariantMap PlayerController::currentTrack() const { return m_currentTrack; }
QString PlayerController::currentLyrics() const { return m_currentLyrics; }
bool PlayerController::isPlaying() const { return m_isPlaying; }
bool PlayerController::shuffleEnabled() const { return m_shuffleEnabled; }
qreal PlayerController::audioLevel() const { return m_audioLevel; }
bool PlayerController::audioMeterEnabled() const { return m_player->audioBufferOutput() != nullptr; }
qint64 PlayerController::position() const { return m_position; }
qint64 PlayerController::duration() const { return m_duration; }
QString PlayerController::formattedPosition() const { return formatDuration(static_cast<int>(m_position / 1000)); }
QString PlayerController::formattedDuration() const { return formatDuration(static_cast<int>(m_duration / 1000)); }
float PlayerController::volume() const { return m_audioOutput ? m_audioOutput->volume() : 1.0f; }
QString PlayerController::error() const { return m_error; }

void PlayerController::setAudioMeterEnabled(bool enabled)
{
    if (enabled == audioMeterEnabled()) return;
    m_player->setAudioBufferOutput(enabled ? m_bufferOutput : nullptr);
    if (!enabled) setAudioLevel(0.0);
    emit audioMeterEnabledChanged();
}

bool PlayerController::selfCheck()
{
    QBuffer source;
    PlayerController player;
    if (player.audioMeterEnabled()) return false;
    if (!isNetworkStream(QUrl(QStringLiteral("https://radio.example/live")))) return false;
    if (isNetworkStream(QUrl::fromLocalFile(QStringLiteral("C:/music/track.flac")))) return false;

    QAudioFormat format;
    format.setSampleRate(48000);
    format.setChannelCount(1);
    format.setSampleFormat(QAudioFormat::Float);
    QAudioBuffer buffer(2, format);
    buffer.data<float>()[0] = 0.25f;
    buffer.data<float>()[1] = -0.25f;

    player.m_bufferOutput->audioBufferReceived(buffer);
    if (player.audioLevel() != 0.0) return false;
    for (int i = 0; i < 3; ++i) {
        player.setAudioMeterEnabled(true);
        player.m_bufferOutput->audioBufferReceived(buffer);
        if (!player.audioMeterEnabled() || qAbs(player.audioLevel() - 0.75) > 0.001) return false;
        player.setAudioMeterEnabled(false);
        player.m_bufferOutput->audioBufferReceived(buffer);
        if (player.audioMeterEnabled() || player.audioLevel() != 0.0) return false;
    }
    if (player.m_player->audioOutput() != player.m_audioOutput) return false;

    QByteArray pcm(128000, '\x20');
    QByteArray wave;
    QDataStream stream(&wave, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    stream.writeRawData("RIFF", 4);
    stream << quint32(36 + pcm.size());
    stream.writeRawData("WAVEfmt ", 8);
    stream << quint32(16) << quint16(1) << quint16(1) << quint32(8000)
           << quint32(16000) << quint16(2) << quint16(16);
    stream.writeRawData("data", 4);
    stream << quint32(pcm.size());
    stream.writeRawData(pcm.constData(), pcm.size());

    source.setData(wave);
    source.open(QIODevice::ReadOnly);

    const auto waitFor = [](auto condition) {
        QEventLoop loop;
        QTimer poll;
        QObject::connect(&poll, &QTimer::timeout, &loop, [&] {
            if (condition()) loop.quit();
        });
        poll.start(20);
        QTimer::singleShot(3000, &loop, &QEventLoop::quit);
        loop.exec();
        return condition();
    };

    player.m_audioOutput->setMuted(true);
    player.m_player->setSourceDevice(&source, QUrl("meter-check.wav"));
    player.m_player->play();
    if (!waitFor([&] { return player.position() > 100; })) return false;
    player.setAudioMeterEnabled(true);
    if (!waitFor([&] { return player.audioLevel() > 0.1; })) return false;
    const qint64 position = player.position();
    player.setAudioMeterEnabled(false);
    if (!waitFor([&] { return player.position() > position + 100; })) return false;
    return player.audioLevel() == 0.0 && player.error().isEmpty()
        && player.m_player->audioOutput() == player.m_audioOutput;
}

QString PlayerController::getLyrics(const QString &filePath) const
{
    if (StreamingController::isRemotePath(filePath)) {
        return {};
    }
    return extractEmbeddedLyrics(filePath);
}

void PlayerController::setCurrentLyrics(const QString &lyrics)
{
    if (m_currentLyrics == lyrics) return;
    m_currentLyrics = lyrics;
    emit currentLyricsChanged();
}

void PlayerController::setShuffleEnabled(bool enabled)
{
    if (m_shuffleEnabled != enabled) {
        m_shuffleEnabled = enabled;
        emit shuffleEnabledChanged();
    }
}

void PlayerController::toggleShuffle()
{
    setShuffleEnabled(!m_shuffleEnabled);
}

void PlayerController::setVolume(float vol)
{
    if (m_audioOutput) {
        float clamped = std::clamp(vol, 0.0f, 1.0f);
        QSettings limitSettings(settingsFilePath(), QSettings::IniFormat);
        if (limitSettings.value("player/volumeLimitEnabled", false).toBool()) {
            const int maxPercent = std::clamp(limitSettings.value("player/maxVolumePercent", 80).toInt(), 10, 100);
            clamped = std::min(clamped, maxPercent / 100.0f);
        }
        if (m_audioOutput->volume() != clamped) {
            m_audioOutput->setVolume(clamped);
            emit volumeChanged();
        }
    }
}

void PlayerController::restoreTrack(const QVariantMap &track, qint64 positionMs)
{
    if (!loadTrack(track)) return;
    m_player->pause();
    if (positionMs > 0) {
        m_player->setPosition(positionMs);
        m_position = positionMs;
        emit positionChanged();
    }
}

void PlayerController::playTrack(const QVariantMap &track)
{
    if (!loadTrack(track)) return;
    m_player->play();
}

bool PlayerController::loadTrack(const QVariantMap &track)
{
    const QString filePath = track.value("filePath").toString();
    if (filePath.isEmpty()) return false;
    const QUrl mediaSource = resolveMediaSource(track);
    if (mediaSource.isEmpty()) return false;

    m_currentTrack = track;
    if (!m_error.isEmpty()) {
        m_error.clear();
        emit errorChanged();
    }
    if (m_currentTrack.value("artworkUrl").toString().isEmpty()
        && !StreamingController::isRemotePath(filePath)) {
        // ponytail: load embedded artwork only for the current track; add async thumbnailing if browsing embedded art needs it.
        m_currentTrack.insert("artworkUrl", extractEmbeddedArtwork(filePath, 1024));
    }
    m_currentLyrics = track.value("lyrics").toString();
    if (m_currentLyrics.isEmpty() && !StreamingController::isRemotePath(filePath)) {
        m_currentLyrics = extractEmbeddedLyrics(filePath);
    }
    emit currentTrackChanged();
    emit currentLyricsChanged();

    m_position = 0;
    emit positionChanged();
    m_player->setSource(mediaSource);
    m_player->setActiveVideoTrack(-1);
    return true;
}

void PlayerController::togglePlay()
{
    if (m_player->playbackState() == QMediaPlayer::PlayingState) {
        m_player->pause();
    } else if (m_player->playbackState() == QMediaPlayer::PausedState) {
        m_player->play();
    } else if (!m_currentTrack.isEmpty()) {
        playTrack(m_currentTrack);
    }
}

void PlayerController::pause()
{
    m_player->pause();
}

void PlayerController::stop()
{
    m_player->stop();
}

void PlayerController::seek(qint64 positionMs)
{
    m_player->setPosition(positionMs);
}

void PlayerController::setWindowAlwaysOnTop(QQuickWindow *win, bool onTop)
{
#ifdef _WIN32
    if (win) {
        HWND hwnd = reinterpret_cast<HWND>(win->winId());
        if (hwnd) {
            SetWindowPos(hwnd, onTop ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        }
    }
#else
    Q_UNUSED(win);
    Q_UNUSED(onTop);
#endif
}

QUrl PlayerController::resolveMediaSource(const QVariantMap &track) const
{
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
        QSettings settings(settingsFilePath(), QSettings::IniFormat);
        if (settings.value("network/offlineBlackout", false).toBool()) return {};
        return url;
    }
    return QUrl::fromLocalFile(filePath);
}

void PlayerController::setAudioLevel(qreal level)
{
    if (qAbs(m_audioLevel - level) < 0.01) return;
    m_audioLevel = level;
    emit audioLevelChanged();
}
