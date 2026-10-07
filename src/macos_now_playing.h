#pragma once

#include <QString>

#include <functional>

/// macOS Now Playing: the media keys, AirPods and Control Centre controls, and the track shown in the menu bar.
namespace MacNowPlaying {

struct Commands {
    std::function<void()> play;
    std::function<void()> pause;
    std::function<void()> togglePlayPause;
    std::function<void()> next;
    std::function<void()> previous;
    std::function<void(qint64 positionMs)> seek;
};

/// Starts receiving remote commands; call once.
void initialize(Commands commands);
/// Shows \p title and its details, or clears Now Playing when \p title is empty.
void setTrack(const QString &title, const QString &artist, const QString &album, const QString &artworkPath);
void setPlaying(bool playing);
/// Reports the position; macOS advances it on its own, so it is only resent after a seek or a duration change.
void setTimeline(qint64 positionMs, qint64 durationMs);

} // namespace MacNowPlaying
