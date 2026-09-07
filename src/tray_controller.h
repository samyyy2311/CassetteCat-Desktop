#pragma once

#include <QObject>
#include <QIcon>

class QAction;
class QMenu;
class QSystemTrayIcon;

class TrayController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available CONSTANT)

public:
    explicit TrayController(const QIcon &icon, QObject *parent = nullptr);
    ~TrayController() override;

    bool available() const;

    Q_INVOKABLE void setTrack(const QString &title, const QString &artist);
    Q_INVOKABLE void setPlaying(bool playing);
    Q_INVOKABLE void notifyHidden();
    Q_INVOKABLE void showNotification(const QString &title, const QString &message);

signals:
    void showRequested();
    void playPauseRequested();
    void nextRequested();
    void previousRequested();
    void quitRequested();

private:
    QSystemTrayIcon *m_tray = nullptr;
    QMenu *m_menu = nullptr;
    QAction *m_playPauseAction = nullptr;
};
