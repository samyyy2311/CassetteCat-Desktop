#include "macos_now_playing.h"

#include <QElapsedTimer>
#include <QUrl>

#import <AppKit/AppKit.h>
#import <MediaPlayer/MediaPlayer.h>

namespace {

MacNowPlaying::Commands commands;
bool playing = false;
qint64 reportedPositionMs = 0;
qint64 reportedDurationMs = 0;
QElapsedTimer sinceReport;

void updateInfo(void (^change)(NSMutableDictionary *info)) {
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *info =
        center.nowPlayingInfo ? [center.nowPlayingInfo mutableCopy] : [NSMutableDictionary dictionary];
    change(info);
    center.nowPlayingInfo = info;
}

void reportTimeline(qint64 positionMs, qint64 durationMs) {
    reportedPositionMs = positionMs;
    reportedDurationMs = durationMs;
    sinceReport.restart();
    updateInfo(^(NSMutableDictionary *info) {
      info[MPMediaItemPropertyPlaybackDuration] = @(durationMs / 1000.0);
      info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(positionMs / 1000.0);
      info[MPNowPlayingInfoPropertyPlaybackRate] = @(playing ? 1.0 : 0.0);
    });
}

void addHandler(MPRemoteCommand *command, std::function<void()> MacNowPlaying::Commands::*handler) {
    [command addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *) {
      (commands.*handler)();
      return MPRemoteCommandHandlerStatusSuccess;
    }];
}

} // namespace

void MacNowPlaying::initialize(Commands handlers) {
    commands = std::move(handlers);
    MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
    addHandler(center.playCommand, &Commands::play);
    addHandler(center.pauseCommand, &Commands::pause);
    addHandler(center.togglePlayPauseCommand, &Commands::togglePlayPause);
    addHandler(center.nextTrackCommand, &Commands::next);
    addHandler(center.previousTrackCommand, &Commands::previous);
    [center.changePlaybackPositionCommand
        addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
          const NSTimeInterval seconds = static_cast<MPChangePlaybackPositionCommandEvent *>(event).positionTime;
          commands.seek(static_cast<qint64>(seconds * 1000));
          return MPRemoteCommandHandlerStatusSuccess;
        }];
}

void MacNowPlaying::setTrack(const QString &title, const QString &artist, const QString &album,
                             const QString &artworkPath) {
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    if (title.trimmed().isEmpty()) {
        center.nowPlayingInfo = nil;
        center.playbackState = MPNowPlayingPlaybackStateStopped;
        return;
    }
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[MPMediaItemPropertyTitle] = title.toNSString();
    info[MPMediaItemPropertyArtist] = artist.toNSString();
    info[MPMediaItemPropertyAlbumTitle] = album.toNSString();
    const QUrl artworkUrl(artworkPath);
    const QString localArtwork = artworkUrl.isLocalFile() ? artworkUrl.toLocalFile() : artworkPath;
    if (NSImage *image = [[NSImage alloc] initWithContentsOfFile:localArtwork.toNSString()]) {
        info[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithBoundsSize:image.size
                                                                           requestHandler:^NSImage *(CGSize) {
                                                                             return image;
                                                                           }];
    }
    center.nowPlayingInfo = info;
    // A new song starts from zero until its first timeline report.
    reportedPositionMs = 0;
    reportedDurationMs = 0;
    sinceReport.restart();
}

void MacNowPlaying::setPlaying(bool isPlaying) {
    playing = isPlaying;
    [MPNowPlayingInfoCenter defaultCenter].playbackState =
        isPlaying ? MPNowPlayingPlaybackStatePlaying : MPNowPlayingPlaybackStatePaused;
    const qint64 elapsed = sinceReport.isValid() && playing ? sinceReport.elapsed() : 0;
    reportTimeline(reportedPositionMs + elapsed, reportedDurationMs);
}

void MacNowPlaying::setTimeline(qint64 positionMs, qint64 durationMs) {
    const qint64 expected = reportedPositionMs + (playing && sinceReport.isValid() ? sinceReport.elapsed() : 0);
    if (durationMs != reportedDurationMs || qAbs(positionMs - expected) > 1000)
        reportTimeline(positionMs, durationMs);
}
