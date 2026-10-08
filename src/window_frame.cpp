#include "window_frame.h"

#include <QCoreApplication>
#include <QQuickItem>
#include <QQuickWindow>

#ifdef Q_OS_WIN
#include <windows.h>
#include <windowsx.h>
#endif

WindowFrame::WindowFrame(QObject *parent) : QObject(parent) {
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

void WindowFrame::setHovered(bool hovered) {
    if (m_hovered == hovered)
        return;
    m_hovered = hovered;
    emit maximizeHoveredChanged();
}

bool WindowFrame::overButton(int x, int y) const {
#ifdef Q_OS_WIN
    if (!m_button || !m_button->isVisible() || !m_button->window())
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
    // The whole window is client area, so the frame Windows needs for snapping stays invisible. A maximized window
    // overhangs the screen by its frame, which is cut off here.
    case WM_NCCALCSIZE: {
        if (!msg->wParam)
            return false;
        if (IsZoomed(hwnd)) {
            const UINT dpi = GetDpiForWindow(hwnd);
            const int padding = GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
            const int frameX = GetSystemMetricsForDpi(SM_CXFRAME, dpi) + padding;
            const int frameY = GetSystemMetricsForDpi(SM_CYFRAME, dpi) + padding;
            RECT &client = reinterpret_cast<NCCALCSIZE_PARAMS *>(msg->lParam)->rgrc[0];
            client.left += frameX;
            client.top += frameY;
            client.right -= frameX;
            client.bottom -= frameY;
        }
        *result = 0;
        return true;
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
