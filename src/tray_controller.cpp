#include "tray_controller.h"

#ifdef Q_OS_WIN
#include <malloc.h>
#include <windows.h>
#elif defined(__GLIBC__)
#include <malloc.h>
#endif

#include <QAction>
#include <QCoreApplication>
#include <QCursor>
#include <QMenu>
#include <QSystemTrayIcon>

TrayController::TrayController(const QIcon &icon, QObject *parent) : QObject(parent) {
    if (!QSystemTrayIcon::isSystemTrayAvailable())
        return;

    m_tray = new QSystemTrayIcon(icon, this);
    m_menu = new QMenu;
    m_menu->setFixedWidth(210);
    m_menu->setStyleSheet("QMenu {"
                          " background: #1B1A18; color: #F5F0EC; border: 1px solid #35322E;"
                          " padding: 4px; font: 10pt 'IBM Plex Sans';"
                          "}"
                          "QMenu::item { padding: 7px 28px 7px 12px; border-radius: 5px; margin: 1px; }"
                          "QMenu::item:selected { background: #302D29; }"
                          "QMenu::separator { height: 1px; background: #3B3834; margin: 4px 8px; }");

    auto *showAction = m_menu->addAction("Show CassetteCat");
    auto *previousAction = m_menu->addAction("Previous");
    m_playPauseAction = m_menu->addAction("Play");
    auto *nextAction = m_menu->addAction("Next");
    m_menu->addSeparator();
    auto *quitAction = m_menu->addAction("Quit");

    connect(showAction, &QAction::triggered, this, &TrayController::showRequested);
    connect(previousAction, &QAction::triggered, this, &TrayController::previousRequested);
    connect(m_playPauseAction, &QAction::triggered, this, &TrayController::playPauseRequested);
    connect(nextAction, &QAction::triggered, this, &TrayController::nextRequested);
    connect(quitAction, &QAction::triggered, this, &TrayController::quitRequested);
    connect(m_tray, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick) {
            emit showRequested();
        }
    });

    m_tray->setToolTip(QCoreApplication::applicationName());
    m_tray->show();

    connect(m_tray, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
        if (reason != QSystemTrayIcon::Context || !m_menu)
            return;
        const QRect trayRect = m_tray->geometry();
        const QPoint anchor = trayRect.isValid() ? QPoint(trayRect.center().x(), trayRect.bottom()) : QCursor::pos();
        m_menu->popup(anchor);
    });
}

TrayController::~TrayController() {
    delete m_menu;
}

bool TrayController::available() const {
    return m_tray != nullptr;
}

void TrayController::setTrack(const QString &title, const QString &artist) {
    if (!m_tray)
        return;
    const QString app = QCoreApplication::applicationName();
    m_tray->setToolTip(title.isEmpty() ? app : app + '\n' + title + (artist.isEmpty() ? QString() : " - " + artist));
}

void TrayController::setPlaying(bool playing) {
    if (m_playPauseAction)
        m_playPauseAction->setText(playing ? "Pause" : "Play");
}

void TrayController::notifyHidden() {
    if (m_tray && QSystemTrayIcon::supportsMessages()) {
        m_tray->showMessage("CassetteCat", "CassetteCat is still available in the system tray.");
    }
}

void TrayController::releaseMemory() {
#ifdef Q_OS_WIN
    _heapmin();
    SetProcessWorkingSetSize(GetCurrentProcess(), static_cast<SIZE_T>(-1), static_cast<SIZE_T>(-1));
#elif defined(__GLIBC__)
    malloc_trim(0);
#endif
}

void TrayController::showNotification(const QString &title, const QString &message) {
    if (m_tray && QSystemTrayIcon::supportsMessages()) {
        m_tray->showMessage(title, message, QSystemTrayIcon::Information, 3500);
    }
}
