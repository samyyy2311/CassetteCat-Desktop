#pragma once

#include <QObject>
#include <QString>
#include <QUrl>
#include <QVariantMap>

class QAudioBufferOutput;
class QMediaDevices;
class QAudioOutput;
class QMediaPlayer;
class QQuickWindow;
class StreamingController;

class PlayerController final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap currentTrack READ currentTrack NOTIFY currentTrackChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY isPlayingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString formattedPosition READ formattedPosition NOTIFY positionChanged)
    Q_PROPERTY(QString formattedDuration READ formattedDuration NOTIFY durationChanged)
    Q_PROPERTY(float volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(QVariantList audioOutputs READ audioOutputs NOTIFY audioOutputsChanged)
    Q_PROPERTY(QString audioDeviceId READ audioDeviceId NOTIFY audioDeviceChanged)
    Q_PROPERTY(bool shuffleEnabled READ shuffleEnabled WRITE setShuffleEnabled NOTIFY shuffleEnabledChanged)
    Q_PROPERTY(qreal audioLevel READ audioLevel NOTIFY audioLevelChanged)
    Q_PROPERTY(bool audioMeterEnabled READ audioMeterEnabled WRITE setAudioMeterEnabled NOTIFY audioMeterEnabledChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString currentLyrics READ currentLyrics NOTIFY currentLyricsChanged)
    Q_PROPERTY(QString replayGainMode READ replayGainMode WRITE setReplayGainMode NOTIFY replayGainModeChanged)
  public:
    /// Creates a player backed by \p streaming for authenticated remote tracks.
    explicit PlayerController(QObject *parent = nullptr, StreamingController *streaming = nullptr);
    /// Runs deterministic checks for core playback behavior.
    static bool selfCheck();

    QVariantMap currentTrack() const;
    QString currentLyrics() const;
    bool isPlaying() const;
    bool shuffleEnabled() const;
    qreal audioLevel() const;
    bool audioMeterEnabled() const;
    void setAudioMeterEnabled(bool enabled);
    qint64 position() const;
    qint64 duration() const;
    QString formattedPosition() const;
    QString formattedDuration() const;
    /// Returns the user-selected base volume before ReplayGain adjustment.
    float volume() const;
    QVariantList audioOutputs() const;
    QString audioDeviceId() const;
    QString error() const;
    /// Returns the active ReplayGain mode.
    QString replayGainMode() const;

    Q_INVOKABLE QString getLyrics(const QString &filePath) const;
    Q_INVOKABLE void setCurrentLyrics(const QString &lyrics);
    Q_INVOKABLE void setShuffleEnabled(bool enabled);
    Q_INVOKABLE void toggleShuffle();
    /// Sets the base player volume while respecting the configured ceiling.
    Q_INVOKABLE void setVolume(float vol);
    /// Selects track, album, or disabled ReplayGain processing.
    Q_INVOKABLE void setReplayGainMode(const QString &mode);
    Q_INVOKABLE bool setAudioDevice(const QString &id);
    Q_INVOKABLE void restoreTrack(const QVariantMap &track, qint64 positionMs = 0);
    Q_INVOKABLE bool playTrack(const QVariantMap &track);
    Q_INVOKABLE void togglePlay();
    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void seek(qint64 positionMs);
    Q_INVOKABLE void setWindowAlwaysOnTop(QQuickWindow *win, bool onTop);
    Q_INVOKABLE void updateCurrentTrackArtwork(const QString &artworkPath);
    /// Replaces the current track metadata with \p track.
    Q_INVOKABLE void updateCurrentTrackMetadata(const QVariantMap &track);
    /// Requests playback of \p tracks beginning at \p startIndex.
    Q_INVOKABLE void requestPlayback(const QVariantList &tracks, int startIndex = 0);

  signals:
    /// Announces a request to replace the playback queue.
    void playbackRequested(const QVariantList &tracks, int startIndex);
    void currentTrackChanged();
    void currentLyricsChanged();
    void isPlayingChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void audioOutputsChanged();
    void audioDeviceChanged();
    void shuffleEnabledChanged();
    void audioLevelChanged();
    void audioMeterEnabledChanged();
    void errorChanged();
    /// Announces that the ReplayGain mode changed.
    void replayGainModeChanged();
    void trackEnded();

  private:
    // Local files resolve to file URLs; remote tracks resolve to an
    // authenticated stream URL built in C++ so secrets never reach QML.
    // Returns an empty URL when a remote track cannot be resolved.
    QUrl resolveMediaSource(const QVariantMap &track) const;
    /// Loads \p track into the media player without starting playback.
    bool loadTrack(const QVariantMap &track);
    void openDeferredSource();
    void setAudioLevel(qreal level);
    /// Applies ReplayGain and the configured ceiling to the audio output.
    void applyEffectiveVolume();

    QAudioOutput *m_audioOutput = nullptr;
    QMediaDevices *m_mediaDevices = nullptr;
    QAudioBufferOutput *m_bufferOutput = nullptr;
    QMediaPlayer *m_player = nullptr;
    StreamingController *m_streaming = nullptr;
    QVariantMap m_currentTrack;
    QString m_currentLyrics;
    bool m_isPlaying = false;
    bool m_shuffleEnabled = false;
    qreal m_audioLevel = 0.0;
    qint64 m_position = 0;
    qint64 m_duration = 0;
    qint64 m_pendingRestorePositionMs = 0;
    // Media for the loaded track that has not been handed to the backend yet.
    QUrl m_deferredSource;
    QString m_error;
    bool m_pauseExpected = false;
    QString m_replayGainMode = QStringLiteral("off");
    float m_currentReplayGainDb = 0.0f;
    float m_baseVolume = 1.0f;
};
