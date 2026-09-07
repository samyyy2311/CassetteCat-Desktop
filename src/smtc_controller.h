#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>

class PlayerController;

class SmtcController final : public QObject
{
    Q_OBJECT

public:
    explicit SmtcController(PlayerController *player, QObject *parent = nullptr);
    ~SmtcController() override;

    void initialize(quintptr hwnd);
    void updateTrack(const QString &title, const QString &artist, const QString &album, const QString &artworkPath);
    void updatePlaybackStatus(bool isPlaying);
    void updateTimeline(qint64 positionMs, qint64 durationMs);

signals:
    void playRequested();
    void pauseRequested();
    void nextRequested();
    void previousRequested();
    void seekRequested(qint64 positionMs);

private slots:
    void onTrackChanged();
    void onPlayingChanged();
    void onPositionChanged();

private:
    class Private;
    Private *d = nullptr;
    PlayerController *m_player = nullptr;
};
