#pragma once

#include <QAudioDevice>
#include <QAudioFormat>
#include <QMutex>
#include <QObject>
#include <QThread>

#include <array>
#include <deque>
#include <vector>

class QAudioBuffer;
class QAudioBufferOutput;
class QAudioSink;

/// Mixes the media players' decoded audio, applies the equalizer and volume, and plays it on one audio device.
/// Each player decodes in real time into its own short queue here, so the next song can start while the previous
/// one's last samples are still playing, which removes the gap between tracks. The device is fed from its own
/// thread, so a busy interface can't leave it without audio.
class AudioPipeline final : public QObject {
    Q_OBJECT
  public:
    static constexpr int kBandCount = 10;
    /// Centre frequencies of the graphic equalizer, the same ten bands AutoEq profiles use.
    static constexpr std::array<int, kBandCount> kBandHz = {31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000};

    explicit AudioPipeline(QObject *parent = nullptr);
    ~AudioPipeline() override;

    /// The format every source delivers and the device plays.
    static QAudioFormat format();
    /// A buffer output for one media player; its audio is mixed in at the gain set with setGain().
    QAudioBufferOutput *addSource();
    void setGain(QAudioBufferOutput *source, float gain);
    /// Drops audio queued from \p source, after a seek or a new song that shouldn't follow on.
    void clear(QAudioBufferOutput *source);

    void setDevice(const QAudioDevice &device);
    QAudioDevice device() const;
    /// Pausing stops the device at once instead of letting queued audio play out.
    void setPaused(bool paused);

    /// Gains in dB for each band, plus a preamp applied before the bands.
    void setEqualizer(bool enabled, const std::array<float, kBandCount> &bandsDb, float preampDb);

    /// Reports the RMS level of each buffer \p source delivers, before gain, as it arrives.
    void setMeteredSource(QAudioBufferOutput *source);

    /// Runs the mixer and equalizer on generated signals without a device.
    static bool selfCheck();

  signals:
    void levelReceived(double rms);

  private:
    class Feed;
    struct Biquad {
        float b0 = 1, b1 = 0, b2 = 0, a1 = 0, a2 = 0;
        std::array<float, 2> z1{}, z2{};
        float process(float x, int channel);
    };
    struct Source {
        QAudioBufferOutput *output = nullptr;
        std::deque<float> samples;
        float gain = 1.0f;
        // Waits for a little audio before mixing in, so the queue never starts out empty.
        bool primed = false;
    };

    void append(QAudioBufferOutput *output, const QAudioBuffer &buffer);
    void restartSink();
    /// Mixes \p frames frames into \p out; the mutex must be held.
    void mix(float *out, qint64 frames);

    mutable QMutex m_mutex;
    std::vector<Source> m_sources;
    std::array<Biquad, kBandCount> m_bands;
    float m_preamp = 1.0f;
    bool m_equalizerOn = false;
    QAudioBufferOutput *m_metered = nullptr;
    QAudioDevice m_device;
    bool m_paused = true;
    QThread m_audioThread;
    // Lives on the audio thread; the device and incoming audio are handled in its context.
    QObject m_audioContext;
    // Created, used and destroyed on the audio thread only.
    QAudioSink *m_sink = nullptr;
    Feed *m_feed = nullptr;
};
