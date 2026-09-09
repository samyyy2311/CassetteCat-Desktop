#include "global_shortcut_controller.h"

#include <QCoreApplication>
#include <QGuiApplication>
#include <QStringList>
#include <iterator>

#ifdef Q_OS_WIN
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

namespace {

enum ShortcutId {
    PlayPause = 1,
    Previous,
    Next,
    Favorite,
    Search,
    MiniPlayer
};

struct Shortcut {
    int id;
    const char *action;
};

constexpr Shortcut shortcutDefinitions[] = {
    { PlayPause, "playPause" },
    { Previous, "previous" },
    { Next, "next" },
    { Favorite, "favorite" },
    { Search, "search" },
    { MiniPlayer, "miniPlayer" }
};

bool parseShortcut(const QString &text, UINT *modifiers, UINT *key)
{
    const QStringList parts = text.split('+', Qt::SkipEmptyParts);
    if (parts.size() < 2) return false;

    UINT parsedModifiers = 0;
    QString keyText;
    for (const QString &part : parts) {
        const QString token = part.trimmed();
        if (token.compare("Ctrl", Qt::CaseInsensitive) == 0 || token.compare("Control", Qt::CaseInsensitive) == 0) {
            if (parsedModifiers & MOD_CONTROL) return false;
            parsedModifiers |= MOD_CONTROL;
        } else if (token.compare("Alt", Qt::CaseInsensitive) == 0) {
            if (parsedModifiers & MOD_ALT) return false;
            parsedModifiers |= MOD_ALT;
        } else if (token.compare("Shift", Qt::CaseInsensitive) == 0) {
            if (parsedModifiers & MOD_SHIFT) return false;
            parsedModifiers |= MOD_SHIFT;
        } else if (keyText.isEmpty()) {
            keyText = token;
        } else {
            return false;
        }
    }
    if (!(parsedModifiers & (MOD_CONTROL | MOD_ALT)) || keyText.isEmpty()) return false;

    UINT parsedKey = 0;
    if (keyText.size() == 1 && keyText.at(0).isLetterOrNumber()) {
        parsedKey = keyText.at(0).toUpper().unicode();
    } else if (keyText.compare("Space", Qt::CaseInsensitive) == 0) {
        parsedKey = VK_SPACE;
    } else if (keyText.compare("Left", Qt::CaseInsensitive) == 0) {
        parsedKey = VK_LEFT;
    } else if (keyText.compare("Right", Qt::CaseInsensitive) == 0) {
        parsedKey = VK_RIGHT;
    } else if (keyText.compare("Up", Qt::CaseInsensitive) == 0) {
        parsedKey = VK_UP;
    } else if (keyText.compare("Down", Qt::CaseInsensitive) == 0) {
        parsedKey = VK_DOWN;
    } else if (keyText.startsWith('F', Qt::CaseInsensitive)) {
        bool ok = false;
        const int number = keyText.mid(1).toInt(&ok);
        if (!ok || number < 1 || number > 24) return false;
        parsedKey = VK_F1 + number - 1;
    } else {
        return false;
    }
    *modifiers = parsedModifiers;
    *key = parsedKey;
    return true;
}

QString normalizedShortcut(UINT modifiers, UINT key)
{
    QStringList parts;
    if (modifiers & MOD_CONTROL) parts << "Ctrl";
    if (modifiers & MOD_ALT) parts << "Alt";
    if (modifiers & MOD_SHIFT) parts << "Shift";
    if (key == VK_SPACE) parts << "Space";
    else if (key == VK_LEFT) parts << "Left";
    else if (key == VK_RIGHT) parts << "Right";
    else if (key == VK_UP) parts << "Up";
    else if (key == VK_DOWN) parts << "Down";
    else if (key >= VK_F1 && key <= VK_F24) parts << ("F" + QString::number(key - VK_F1 + 1));
    else parts << QChar(key);
    return parts.join('+');
}

}
#endif

GlobalShortcutController::GlobalShortcutController(QObject *parent)
    : QObject(parent)
{
    m_shortcuts = {
        { "playPause", "Ctrl+Alt+Space" },
        { "previous", "Ctrl+Alt+Left" },
        { "next", "Ctrl+Alt+Right" },
        { "favorite", "Ctrl+Alt+F" },
        { "search", "Ctrl+Alt+S" },
        { "miniPlayer", "Ctrl+Alt+M" }
    };
    m_altHoldTimer.setSingleShot(true);
    m_altHoldTimer.setInterval(500);
    connect(&m_altHoldTimer, &QTimer::timeout, this, [this] {
        if (!m_altPressed || QGuiApplication::applicationState() != Qt::ApplicationActive) return;
        m_accessHintsVisible = true;
        emit accessHintsRequested(true);
    });
    QCoreApplication::instance()->installNativeEventFilter(this);
#ifdef Q_OS_WIN
    setStatus("Global shortcuts are off");
#else
    setStatus("Global shortcuts are not available on this platform");
#endif
}

GlobalShortcutController::~GlobalShortcutController()
{
    unregisterShortcuts();
    QCoreApplication::instance()->removeNativeEventFilter(this);
}

bool GlobalShortcutController::supported() const
{
#ifdef Q_OS_WIN
    return true;
#else
    return false;
#endif
}

bool GlobalShortcutController::enabled() const
{
    return m_enabled;
}

QString GlobalShortcutController::status() const
{
    return m_status;
}

QVariantMap GlobalShortcutController::shortcuts() const
{
    return m_shortcuts;
}

void GlobalShortcutController::setEnabled(bool enabled)
{
    if (enabled == m_enabled) return;
    if (enabled && !registerShortcuts()) return;
    if (!enabled) unregisterShortcuts();

    m_enabled = enabled;
    setStatus(enabled
        ? "Global shortcuts are on"
        : "Global shortcuts are off");
    emit enabledChanged();
}

bool GlobalShortcutController::setShortcut(const QString &action, const QString &shortcut)
{
#ifdef Q_OS_WIN
    if (!m_shortcuts.contains(action)) return false;

    UINT modifiers = 0;
    UINT key = 0;
    if (!parseShortcut(shortcut, &modifiers, &key)) {
        setStatus("Use Ctrl or Alt with a letter, number, arrow, Space, or F key");
        return false;
    }
    for (const auto &entry : shortcutDefinitions) {
        const QString otherAction = QString::fromLatin1(entry.action);
        if (otherAction == action) continue;
        UINT otherModifiers = 0;
        UINT otherKey = 0;
        if (parseShortcut(m_shortcuts.value(otherAction).toString(), &otherModifiers, &otherKey)
            && modifiers == otherModifiers && key == otherKey) {
            setStatus("Each shortcut must use a different key combination");
            return false;
        }
    }

    const QString normalized = normalizedShortcut(modifiers, key);
    if (m_shortcuts.value(action).toString() == normalized) return true;

    const QVariantMap previous = m_shortcuts;
    m_shortcuts.insert(action, normalized);
    if (m_enabled) {
        unregisterShortcuts();
        if (!registerShortcuts()) {
            m_shortcuts = previous;
            registerShortcuts();
            return false;
        }
        setStatus("Global shortcuts are on");
    }
    emit shortcutsChanged();
    return true;
#else
    Q_UNUSED(action);
    Q_UNUSED(shortcut);
    setStatus("Global shortcuts are not available on this platform");
    return false;
#endif
}

bool GlobalShortcutController::nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result)
{
#ifdef Q_OS_WIN
    if (eventType != "windows_generic_MSG") return false;
    const auto *msg = static_cast<MSG *>(message);
    if (msg->message == WM_SYSKEYDOWN && msg->wParam == VK_MENU) {
        if (m_altPressed) return false;
        m_altPressed = true;
        if (m_accessHintsVisible) {
            m_accessHintsVisible = false;
            emit accessHintsRequested(false);
            return false;
        }
        m_altHoldTimer.start();
        return false;
    }
    if (msg->message == WM_SYSKEYUP && msg->wParam == VK_MENU) {
        m_altPressed = false;
        m_altHoldTimer.stop();
        return false;
    }
    if (m_accessHintsVisible && (msg->message == WM_KEYDOWN || msg->message == WM_SYSKEYDOWN)) {
        const UINT key = msg->wParam;
        if (key >= 'A' && key <= 'Z') {
            emit accessKeyRequested(QString(QChar(key)));
            if (result) *result = 0;
            return true;
        }
    }
    if (msg->message != WM_HOTKEY) return false;

    switch (msg->wParam) {
    case PlayPause: emit playPauseRequested(); break;
    case Previous: emit previousRequested(); break;
    case Next: emit nextRequested(); break;
    case Favorite: emit favoriteRequested(); break;
    case Search: emit searchRequested(); break;
    case MiniPlayer: emit miniPlayerRequested(); break;
    default: return false;
    }
    if (result) *result = 0;
    return true;
#else
    Q_UNUSED(eventType);
    Q_UNUSED(message);
    Q_UNUSED(result);
    return false;
#endif
}

bool GlobalShortcutController::registerShortcuts()
{
#ifdef Q_OS_WIN
    for (const auto &shortcut : shortcutDefinitions) {
        UINT modifiers = 0;
        UINT key = 0;
        if (!parseShortcut(m_shortcuts.value(QString::fromLatin1(shortcut.action)).toString(), &modifiers, &key)
            || !RegisterHotKey(nullptr, shortcut.id, modifiers | MOD_NOREPEAT, key)) {
            unregisterShortcuts();
            setStatus("Unavailable: another app is using one of these shortcuts");
            return false;
        }
    }
    return true;
#else
    setStatus("Global shortcuts are not available on this platform");
    return false;
#endif
}

bool GlobalShortcutController::selfCheck()
{
#ifdef Q_OS_WIN
    UINT modifiers = 0;
    UINT key = 0;
    return parseShortcut("Ctrl+Alt+Space", &modifiers, &key)
        && modifiers == (MOD_CONTROL | MOD_ALT)
        && key == VK_SPACE
        && !parseShortcut("Space", &modifiers, &key)
        && !parseShortcut("Ctrl+Alt+", &modifiers, &key);
#else
    return true;
#endif
}

void GlobalShortcutController::unregisterShortcuts()
{
#ifdef Q_OS_WIN
    for (const auto &shortcut : shortcutDefinitions) UnregisterHotKey(nullptr, shortcut.id);
#endif
}

void GlobalShortcutController::setStatus(const QString &status)
{
    if (m_status == status) return;
    m_status = status;
    emit statusChanged();
}
