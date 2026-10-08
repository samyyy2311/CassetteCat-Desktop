#include "audio_pipeline.h"

#include <QAudioBuffer>
#include <QAudioBufferOutput>
#include <QAudioSink>
#include <QMediaDevices>

#include <algorithm>
#include <cmath>
#include <numbers>

namespace {
constexpr int kRate = 48000;
constexpr int kChannels = 2;
// Audio queued before a source joins the mix; covers opening the next song so tracks run on without a gap.
constexpr qint64 kPrimeFrames = kRate * 3 / 20;
// Players run on the system clock and the device on its own; more than this queued means the device is
// slower, so a frame is dropped now and then to stay in step.
constexpr qint64 kMaxQueuedFrames = kRate / 2;
// Without a working device nothing is played, so queues are capped instead of growing.
constexpr qint64 kMaxBufferedFrames = kRate * 2;
} // namespace

// The device reads its source on the thread the source lives on, so the mix is read through this device, which
// lives on the audio thread.
class AudioPipeline::Feed final : public QIODevice {
  public:
    explicit Feed(AudioPipeline *pipeline) : m_pipeline(pipeline) {
        open(QIODevice::ReadOnly);
    }

  protected:
    qint64 readData(char *data, qint64 maxSize) override {
        const qint64 frames = maxSize / qint64(sizeof(float) * kChannels);
        QMutexLocker lock(&m_pipeline->m_mutex);
        m_pipeline->mix(reinterpret_cast<float *>(data), frames);
        return frames * qint64(sizeof(float) * kChannels);
    }
    qint64 writeData(const char *, qint64) override {
        return -1;
    }
    qint64 bytesAvailable() const override {
        return format().bytesForDuration(80'000) + QIODevice::bytesAvailable();
    }

  private:
    AudioPipeline *m_pipeline;
};

float AudioPipeline::Biquad::process(float x, int channel) {
    const float y = b0 * x + z1[channel];
    z1[channel] = b1 * x - a1 * y + z2[channel];
    z2[channel] = b2 * x - a2 * y;
    return y;
}

AudioPipeline::AudioPipeline(QObject *parent) : QObject(parent), m_device(QMediaDevices::defaultAudioOutput()) {
    m_audioThread.setObjectName("Audio output");
    m_audioContext.moveToThread(&m_audioThread);
    m_audioThread.start(QThread::TimeCriticalPriority);
    restartSink();
}

AudioPipeline::~AudioPipeline() {
    QMetaObject::invokeMethod(
        &m_audioContext,
        [this] {
            delete m_sink;
            delete m_feed;
            m_sink = nullptr;
            m_feed = nullptr;
        },
        Qt::BlockingQueuedConnection);
    m_audioThread.quit();
    m_audioThread.wait();
}

QAudioFormat AudioPipeline::format() {
    QAudioFormat format;
    format.setSampleRate(kRate);
    format.setChannelCount(kChannels);
    format.setSampleFormat(QAudioFormat::Float);
    return format;
}

QAudioBufferOutput *AudioPipeline::addSource() {
    auto *output = new QAudioBufferOutput(format(), this);
    {
        QMutexLocker lock(&m_mutex);
        m_sources.push_back({output});
    }
    // Queued on this thread, like clear(), so audio from before a seek or a new song never arrives after it.
    connect(output, &QAudioBufferOutput::audioBufferReceived, this,
            [this, output](const QAudioBuffer &buffer) { append(output, buffer); });
    return output;
}

void AudioPipeline::setGain(QAudioBufferOutput *source, float gain) {
    QMutexLocker lock(&m_mutex);
    for (Source &s : m_sources)
        if (s.output == source)
            s.gain = gain;
}

void AudioPipeline::clear(QAudioBufferOutput *source) {
    QMutexLocker lock(&m_mutex);
    for (Source &s : m_sources) {
        if (s.output == source) {
            s.samples.clear();
            s.primed = false;
        }
    }
}

void AudioPipeline::append(QAudioBufferOutput *output, const QAudioBuffer &buffer) {
    if (buffer.format() != format())
        return;
    const float *data = buffer.constData<float>();
    const qint64 count = qint64(buffer.frameCount()) * kChannels;
    QMutexLocker lock(&m_mutex);
    if (output == m_metered && count > 0) {
        double sum = 0;
        for (qint64 i = 0; i < count; ++i)
            sum += double(data[i]) * data[i];
        emit levelReceived(std::sqrt(sum / double(count)));
    }
    for (Source &s : m_sources) {
        if (s.output != output)
            continue;
        s.samples.insert(s.samples.end(), data, data + count);
        const qint64 excess = qint64(s.samples.size()) - kMaxBufferedFrames * kChannels;
        if (excess > 0)
            s.samples.erase(s.samples.begin(), s.samples.begin() + excess);
        if (qint64(s.samples.size()) >= kPrimeFrames * kChannels)
            s.primed = true;
    }
}

void AudioPipeline::setMeteredSource(QAudioBufferOutput *source) {
    QMutexLocker lock(&m_mutex);
    m_metered = source;
}

void AudioPipeline::setDevice(const QAudioDevice &device) {
    if (device.id() == m_device.id())
        return;
    m_device = device;
    restartSink();
}

QAudioDevice AudioPipeline::device() const {
    return m_device;
}

void AudioPipeline::restartSink() {
    QMetaObject::invokeMethod(
        &m_audioContext,
        [this, device = m_device, paused = m_paused] {
            delete m_sink;
            if (!m_feed)
                m_feed = new Feed(this);
            m_sink = new QAudioSink(device, format());
            m_sink->setBufferSize(format().bytesForDuration(80'000));
            m_sink->start(m_feed);
            if (paused)
                m_sink->suspend();
        },
        Qt::BlockingQueuedConnection);
}

void AudioPipeline::setPaused(bool paused) {
    if (paused == m_paused)
        return;
    m_paused = paused;
    QMetaObject::invokeMethod(&m_audioContext, [this, paused] { paused ? m_sink->suspend() : m_sink->resume(); });
}

void AudioPipeline::setEqualizer(bool enabled, const std::array<float, kBandCount> &bandsDb, float preampDb) {
    std::array<Biquad, kBandCount> bands;
    for (int i = 0; i < kBandCount; ++i) {
        // Peaking filters an octave wide (Q 1.41), from the Audio EQ Cookbook.
        const double a = std::pow(10.0, bandsDb[i] / 40.0);
        const double w = 2 * std::numbers::pi * std::min(kBandHz[i], kRate / 2 - 1000) / kRate;
        const double alpha = std::sin(w) / (2 * 1.41);
        const double a0 = 1 + alpha / a;
        bands[i].b0 = float((1 + alpha * a) / a0);
        bands[i].b1 = float(-2 * std::cos(w) / a0);
        bands[i].b2 = float((1 - alpha * a) / a0);
        bands[i].a1 = bands[i].b1;
        bands[i].a2 = float((1 - alpha / a) / a0);
    }
    QMutexLocker lock(&m_mutex);
    // Keeping the filter state avoids a click when the curve changes while playing.
    for (int i = 0; i < kBandCount; ++i) {
        bands[i].z1 = m_bands[i].z1;
        bands[i].z2 = m_bands[i].z2;
    }
    m_bands = bands;
    m_preamp = float(std::pow(10.0, preampDb / 20.0));
    m_equalizerOn = enabled;
}

void AudioPipeline::mix(float *out, qint64 frames) {
    std::fill(out, out + frames * kChannels, 0.0f);
    for (Source &s : m_sources) {
        if (!s.primed)
            continue;
        if (qint64(s.samples.size()) > kMaxQueuedFrames * kChannels)
            s.samples.erase(s.samples.begin(), s.samples.begin() + kChannels);
        const qint64 available = std::min<qint64>(frames * kChannels, s.samples.size());
        for (qint64 i = 0; i < available; ++i)
            out[i] += s.samples[i] * s.gain;
        s.samples.erase(s.samples.begin(), s.samples.begin() + available);
    }
    for (qint64 f = 0; f < frames; ++f) {
        for (int c = 0; c < kChannels; ++c) {
            float &sample = out[f * kChannels + c];
            if (m_equalizerOn) {
                sample *= m_preamp;
                for (Biquad &band : m_bands)
                    sample = band.process(sample, c);
            }
            sample = std::clamp(sample, -1.0f, 1.0f);
        }
    }
}

bool AudioPipeline::selfCheck() {
    AudioPipeline pipeline;
    QAudioBufferOutput *a = pipeline.addSource();
    QAudioBufferOutput *b = pipeline.addSource();
    const auto feed = [&](QAudioBufferOutput *source, float value, qint64 frames) {
        QAudioBuffer buffer(int(frames), format());
        std::fill(buffer.data<float>(), buffer.data<float>() + frames * kChannels, value);
        pipeline.append(source, buffer);
    };
    std::vector<float> out(64 * kChannels);
    const auto mixOnce = [&] {
        QMutexLocker lock(&pipeline.m_mutex);
        pipeline.mix(out.data(), 64);
        return out[0];
    };

    // A source joins only once primed, and mixes at its gain.
    feed(a, 0.5f, kPrimeFrames / 2);
    const bool waitsForPrime = mixOnce() == 0.0f;
    feed(a, 0.5f, kPrimeFrames);
    pipeline.setGain(a, 0.5f);
    const bool appliesGain = std::abs(mixOnce() - 0.25f) < 1e-6f;
    // Two sources add up, as during a crossfade or the hand-over to the next song.
    feed(b, 0.2f, kPrimeFrames);
    const bool mixesSources = std::abs(mixOnce() - 0.45f) < 1e-6f;
    // Clearing a source drops its queue at once.
    pipeline.clear(b);
    const bool clears = std::abs(mixOnce() - 0.25f) < 1e-6f;

    // A flat equalizer leaves a 1 kHz tone alone; +12 dB at 1 kHz roughly quadruples it.
    const auto toneGain = [&](float bandDb) {
        std::array<float, kBandCount> bands{};
        bands[5] = bandDb;
        pipeline.setEqualizer(true, bands, 0.0f);
        pipeline.clear(a);
        pipeline.clear(b);
        pipeline.setGain(a, 0.05f);
        QAudioBuffer tone(kRate, format());
        float *samples = tone.data<float>();
        for (int f = 0; f < kRate; ++f)
            samples[f * 2] = samples[f * 2 + 1] = float(std::sin(2 * std::numbers::pi * 1000 * f / kRate));
        pipeline.append(a, tone);
        std::vector<float> mixed(size_t(kRate) * kChannels);
        QMutexLocker lock(&pipeline.m_mutex);
        pipeline.mix(mixed.data(), kRate);
        const float peak = *std::max_element(mixed.begin() + kRate, mixed.end());
        return peak / 0.05f;
    };
    const bool flatIsUnity = std::abs(toneGain(0.0f) - 1.0f) < 0.02f;
    const bool boostsBand = std::abs(toneGain(12.0f) - 3.98f) < 0.2f;
    return waitsForPrime && appliesGain && mixesSources && clears && flatIsUnity && boostsBand;
}
