#include "window_frame.h"

#include <QCoreApplication>
#include <QQuickItem>
#include <QQuickWindow>

#ifdef Q_OS_WIN
#include <windows.h>
#include <windowsx.h>
#include <dwmapi.h>
#endif

#ifdef CASSETTECAT_HAVE_DBUS
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusVariant>
#include <QDir>
#include <QSettings>
#endif

WindowFrame::WindowFrame(QObject *parent) : QObject(parent), m_linuxButtons(readLinuxButtons()) {
#ifdef Q_OS_WIN
    QCoreApplication::instance()->installNativeEventFilter(this);
#endif
}

WindowFrame::~WindowFrame() {
#ifdef Q_OS_WIN
    QCoreApplication::instance()->removeNativeEventFilter(this);
#endif
}

void WindowFrame::setMaximizeButton(QQuickItem *button) {
    m_button = button;
}

bool WindowFrame::maximizeHovered() const {
    return m_hovered;
}

qreal WindowFrame::maximizedMargin() const {
    return m_maximizedMargin;
}

QStringList WindowFrame::linuxButtons() const {
    return m_linuxButtons;
}

bool WindowFrame::roundButtons() const {
#ifdef CASSETTECAT_HAVE_DBUS
    const QString desktop = qEnvironmentVariable("XDG_CURRENT_DESKTOP").toUpper();
    return !desktop.contains(QLatin1String("KDE")) && !desktop.contains(QLatin1String("XFCE")) &&
           !desktop.contains(QLatin1String("LXQT"));
#else
    return false;
#endif
}

QStringList WindowFrame::readLinuxButtons() {
#ifdef CASSETTECAT_HAVE_DBUS
    const QStringList usual{QStringLiteral("minimize"), QStringLiteral("maximize"), QStringLiteral("close")};
    QString layout;
    if (qEnvironmentVariable("XDG_CURRENT_DESKTOP").toUpper().contains(QLatin1String("KDE"))) {
        // KDE keeps its buttons in KWin's settings as letters: I minimizes, A maximizes, X closes.
        const QSettings kwin(QDir::homePath() + QStringLiteral("/.config/kwinrc"), QSettings::IniFormat);
        const QString right = kwin.value(QStringLiteral("org.kde.kdecoration2/ButtonsOnRight"), QStringLiteral("IAX")).toString();
        const QString left = kwin.value(QStringLiteral("org.kde.kdecoration2/ButtonsOnLeft")).toString();
        const auto names = [](const QString &letters) {
            QStringList list;
            for (const QChar letter : letters)
                list << (letter == QLatin1Char('I') ? QStringLiteral("minimize")
                         : letter == QLatin1Char('A') ? QStringLiteral("maximize")
                         : letter == QLatin1Char('X') ? QStringLiteral("close") : QString());
            return list.join(QLatin1Char(','));
        };
        layout = names(left) + QLatin1Char(':') + names(right);
    } else {
        // GNOME's setting, which GTK desktops such as Cinnamon, MATE and Budgie answer for too, read through the
        // desktop portal so it also reaches a Flatpak: "appmenu:close", for one.
        QDBusMessage read = QDBusMessage::createMethodCall(
            QStringLiteral("org.freedesktop.portal.Desktop"), QStringLiteral("/org/freedesktop/portal/desktop"),
            QStringLiteral("org.freedesktop.portal.Settings"), QStringLiteral("ReadOne"));
        read << QStringLiteral("org.gnome.desktop.wm.preferences") << QStringLiteral("button-layout");
        const QDBusMessage reply = QDBusConnection::sessionBus().call(read, QDBus::Block, 2000);
        if (reply.type() == QDBusMessage::ReplyMessage && !reply.arguments().isEmpty()) {
            QVariant value = reply.arguments().constFirst();
            while (value.canConvert<QDBusVariant>())
                value = value.value<QDBusVariant>().variant();
            layout = value.toString();
        }
    }
    if (!layout.contains(QLatin1Char(':')))
        return usual;
    QStringList buttons;
    // Buttons set for the left go on the right too, after the others, rather than over the sidebar.
    const QStringList sides = layout.split(QLatin1Char(':'));
    for (const QString &name : (sides.value(1) + QLatin1Char(',') + sides.value(0)).split(QLatin1Char(','))) {
        const QString button = name.trimmed();
        if (usual.contains(button) && !buttons.contains(button))
            buttons << button;
    }
    return buttons.isEmpty() ? usual : buttons;
#else
    return {};
#endif
}

void WindowFrame::setMaximizedMargin(qreal margin) {
    if (qFuzzyCompare(m_maximizedMargin, margin))
        return;
    m_maximizedMargin = margin;
    emit maximizedMarginChanged();
}

void WindowFrame::setHovered(bool hovered) {
    if (m_hovered == hovered)
        return;
    m_hovered = hovered;
    emit maximizeHoveredChanged();
}

bool WindowFrame::overButton(int x, int y) const {
#ifdef Q_OS_WIN
    if (!m_button || !m_button->isVisible() || !m_button->isEnabled() || !m_button->window())
        return false;
    POINT point{x, y};
    ScreenToClient(reinterpret_cast<HWND>(m_button->window()->winId()), &point);
    const qreal ratio = m_button->window()->devicePixelRatio();
    const QRectF rect = m_button->mapRectToScene(QRectF(0, 0, m_button->width(), m_button->height()));
    return rect.contains(point.x / ratio, point.y / ratio);
#else
    Q_UNUSED(x);
    Q_UNUSED(y);
    return false;
#endif
}

bool WindowFrame::nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) {
#ifdef Q_OS_WIN
    if (eventType != "windows_generic_MSG" || !m_button || !m_button->window())
        return false;
    const MSG *msg = static_cast<const MSG *>(message);
    const HWND hwnd = reinterpret_cast<HWND>(m_button->window()->winId());
    if (msg->hwnd != hwnd)
        return false;
    switch (msg->message) {
    // The whole window is client area, so the frame Windows needs for snapping stays invisible.
    case WM_NCCALCSIZE:
        if (!msg->wParam)
            return false;
        *result = 0;
        return true;
    // Windows places a maximized sizable window past the screen edges by its frame, whatever Qt asks for.
    case WM_SIZE: {
        int overhang = 0;
        MONITORINFO monitor{sizeof(monitor)};
        RECT frame;
        if (msg->wParam == SIZE_MAXIMIZED && GetWindowRect(hwnd, &frame) &&
            GetMonitorInfo(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &monitor))
            overhang = monitor.rcWork.left - frame.left;
        setMaximizedMargin(overhang / m_button->window()->devicePixelRatio());
        // Windows 11 keeps a frameless window's rounded corners when it's maximized, so square them while it fills
        // the screen.
        const DWORD corners = msg->wParam == SIZE_MAXIMIZED ? 1 /* DWMWCP_DONOTROUND */ : 2 /* DWMWCP_ROUND */;
        DwmSetWindowAttribute(hwnd, 33 /* DWMWA_WINDOW_CORNER_PREFERENCE */, &corners, sizeof(corners));
        return false;
    }
    case WM_NCHITTEST:
        if (overButton(GET_X_LPARAM(msg->lParam), GET_Y_LPARAM(msg->lParam))) {
            *result = HTMAXBUTTON;
            return true;
        }
        return false;
    case WM_NCMOUSEMOVE:
        if (msg->wParam == HTMAXBUTTON) {
            TRACKMOUSEEVENT track{sizeof(track), TME_LEAVE | TME_NONCLIENT, hwnd, 0};
            TrackMouseEvent(&track);
        }
        setHovered(msg->wParam == HTMAXBUTTON);
        return false;
    case WM_NCMOUSELEAVE:
    case WM_MOUSEMOVE:
        setHovered(false);
        return false;
    // Qt filters input messages before dispatching them, without a result. Swallowing them there keeps Windows from
    // drawing its own button or maximizing on press.
    case WM_NCLBUTTONDOWN:
    case WM_NCLBUTTONDBLCLK:
        return msg->wParam == HTMAXBUTTON;
    case WM_NCLBUTTONUP:
        if (msg->wParam != HTMAXBUTTON)
            return false;
        emit maximizeClicked();
        return true;
    default:
        return false;
    }
#else
    Q_UNUSED(eventType);
    Q_UNUSED(message);
    Q_UNUSED(result);
    return false;
#endif
}
