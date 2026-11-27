#include "global_shortcut_controller.h"
#include "self_check.h"

#include <QCoreApplication>
#include <QGuiApplication>
#include <QKeyEvent>
#include <QWindow>
#include <QStringList>
#include <iterator>

namespace {

enum ShortcutId { PlayPause = 1, Previous, Next, Favorite, Search, MiniPlayer };

struct Shortcut {
    int id;
    const char *action;
    // Matches the row label in Settings so status messages name what the user sees.
    const char *label;
};

constexpr Shortcut shortcutDefinitions[] = {
    {PlayPause, "playPause", QT_TRANSLATE_NOOP("GlobalShortcutController", "Play / Pause")},
    {Previous, "previous", QT_TRANSLATE_NOOP("GlobalShortcutController", "Previous Track")},
    {Next, "next", QT_TRANSLATE_NOOP("GlobalShortcutController", "Next Track")},
    {Favorite, "favorite", QT_TRANSLATE_NOOP("GlobalShortcutController", "Toggle Favorite")},
    {Search, "search", QT_TRANSLATE_NOOP("GlobalShortcutController", "Focus Search")},
    {MiniPlayer, "miniPlayer", QT_TRANSLATE_NOOP("GlobalShortcutController", "Toggle Mini Player")}};

#ifdef CASSETTECAT_HAVE_DBUS
// Ctrl or Alt with one key, as the portal reads it.
bool isPortalShortcut(const QString &shortcut) {
    QStringList parts = shortcut.split(QLatin1Char('+'), Qt::SkipEmptyParts);
    // "Ctrl++" splits to just "Ctrl"; its key is the plus, as the portal trigger reads it.
    if (shortcut.endsWith(QStringLiteral("++")))
        parts.append(QStringLiteral("Plus"));
    static const QStringList modifiers{QStringLiteral("Ctrl"), QStringLiteral("Alt"), QStringLiteral("Shift")};
    return parts.size() >= 2 && !modifiers.contains(parts.constLast()) &&
           (parts.contains(QStringLiteral("Ctrl")) || parts.contains(QStringLiteral("Alt")));
}

bool takenByAnother(const QVariantMap &shortcuts, const QString &action, const QString &shortcut) {
    for (auto it = shortcuts.cbegin(); it != shortcuts.cend(); ++it) {
        if (it.key() != action && it.value().toString() == shortcut)
            return true;
    }
    return false;
}
#endif

} // namespace

#ifdef CASSETTECAT_HAVE_DBUS
#include "portal_shortcuts.h"
#endif

#ifdef Q_OS_WIN
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

namespace {

UINT modifierFor(const QString &token) {
    if (token.compare("Ctrl", Qt::CaseInsensitive) == 0 || token.compare("Control", Qt::CaseInsensitive) == 0)
        return MOD_CONTROL;
    if (token.compare("Alt", Qt::CaseInsensitive) == 0)
        return MOD_ALT;
    if (token.compare("Shift", Qt::CaseInsensitive) == 0)
        return MOD_SHIFT;
    return 0;
}

// Splits a shortcut into its modifiers and one key; a repeated modifier or a second key makes it invalid.
bool splitShortcut(const QStringList &parts, UINT &modifiers, QString &keyText) {
    for (const QString &part : parts) {
        const QString token = part.trimmed();
        const UINT modifier = modifierFor(token);
        if (modifier && (modifiers & modifier))
            return false;
        if (modifier)
            modifiers |= modifier;
        else if (keyText.isEmpty())
            keyText = token;
        else
            return false;
    }
    return true;
}

// The virtual key for a key's name, or 0 for one that can't be a global shortcut.
UINT virtualKey(const QString &keyText) {
    if (keyText.size() == 1 && keyText.at(0).isLetterOrNumber())
        return keyText.at(0).toUpper().unicode();
    static const std::pair<const char *, UINT> namedKeys[] = {
        {"Space", VK_SPACE},   {"Left", VK_LEFT},   {"Right", VK_RIGHT},     {"Up", VK_UP},
        {"Down", VK_DOWN},     {"=", VK_OEM_PLUS},  {"Equal", VK_OEM_PLUS},  {"+", VK_OEM_PLUS},
        {"Plus", VK_OEM_PLUS}, {"-", VK_OEM_MINUS}, {"Minus", VK_OEM_MINUS},
    };
    for (const auto &[name, key] : namedKeys) {
        if (keyText.compare(QLatin1String(name), Qt::CaseInsensitive) == 0)
            return key;
    }
    // Some keyboard layouts name the =/+ key after the character it types there.
    if (keyText == QStringLiteral("»"))
        return VK_OEM_PLUS;
    if (!keyText.startsWith('F', Qt::CaseInsensitive))
        return 0;
    bool ok = false;
    const int number = keyText.mid(1).toInt(&ok);
    return ok && number >= 1 && number <= 24 ? VK_F1 + number - 1 : 0;
}

bool parseShortcut(const QString &text, UINT *modifiers, UINT *key) {
    QString normalized = text.trimmed();
    if (normalized.endsWith("++")) {
        const QString prefix = normalized.left(normalized.size() - 2);
        if (prefix.endsWith('+'))
            return false;
        normalized = prefix + "+Plus";
    }

    const QStringList parts = normalized.split('+', Qt::SkipEmptyParts);
    if (parts.size() < 2)
        return false;
    UINT parsedModifiers = 0;
    QString keyText;
    if (!splitShortcut(parts, parsedModifiers, keyText))
        return false;
    if (!(parsedModifiers & (MOD_CONTROL | MOD_ALT)) || keyText.isEmpty())
        return false;
    const UINT parsedKey = virtualKey(keyText);
    if (!parsedKey)
        return false;
    *modifiers = parsedModifiers;
    *key = parsedKey;
    return true;
}

int shortcutId(const QString &action) {
    for (const auto &entry : shortcutDefinitions) {
        if (action == QLatin1String(entry.action))
            return entry.id;
    }
    return 0;
}

// Whether another action already uses this key combination.
bool takenByAnother(const QVariantMap &shortcuts, const QString &action, UINT modifiers, UINT key) {
    for (const auto &entry : shortcutDefinitions) {
        const QString otherAction = QString::fromLatin1(entry.action);
        UINT otherModifiers = 0;
        UINT otherKey = 0;
        if (otherAction != action &&
            parseShortcut(shortcuts.value(otherAction).toString(), &otherModifiers, &otherKey) &&
            modifiers == otherModifiers && key == otherKey)
            return true;
    }
    return false;
}

QString normalizedShortcut(UINT modifiers, UINT key) {
    QStringList parts;
    if (modifiers & MOD_CONTROL)
        parts << "Ctrl";
    if (modifiers & MOD_ALT)
        parts << "Alt";
    if (modifiers & MOD_SHIFT)
        parts << "Shift";
    if (key == VK_SPACE)
        parts << "Space";
    else if (key == VK_LEFT)
        parts << "Left";
    else if (key == VK_RIGHT)
        parts << "Right";
    else if (key == VK_UP)
        parts << "Up";
    else if (key == VK_DOWN)
        parts << "Down";
    else if (key == VK_OEM_PLUS)
        parts << ((modifiers & MOD_SHIFT) ? "Plus" : "Equal");
    else if (key == VK_OEM_MINUS)
        parts << "-";
    else if (key >= VK_F1 && key <= VK_F24)
        parts << ("F" + QString::number(key - VK_F1 + 1));
    else
        parts << QChar(key);
    return parts.join('+');
}

} // namespace
#endif

GlobalShortcutController::GlobalShortcutController(QObject *parent) : QObject(parent) {
    m_shortcuts = {{"playPause", "Ctrl+Alt+Space"}, {"previous", "Ctrl+Alt+Left"}, {"next", "Ctrl+Alt+Right"},
                   {"favorite", "Ctrl+Alt+F"},      {"search", "Ctrl+Alt+S"},      {"miniPlayer", "Ctrl+Alt+M"}};
    m_altHoldTimer.setSingleShot(true);
    m_altHoldTimer.setInterval(500);
    connect(&m_altHoldTimer, &QTimer::timeout, this, [this] {
        if (!m_altAlone)
            return;
        m_hintsShownByHold = true;
        setAccessHintsVisible(true);
    });
    QCoreApplication::instance()->installNativeEventFilter(this);
    QCoreApplication::instance()->installEventFilter(this);
#ifdef CASSETTECAT_HAVE_DBUS
    if (PortalShortcuts::available()) {
        m_portal = new PortalShortcuts(this);
        connect(m_portal, &PortalShortcuts::activated, this, [this](const QString &action) {
            for (const auto &entry : shortcutDefinitions)
                if (action == QLatin1String(entry.action))
                    trigger(entry.id);
        });
        connect(m_portal, &PortalShortcuts::bound, this, [this](int count) {
            setStatus(count > 0 ? tr("Global shortcuts are active") : tr("No shortcuts were allowed"));
        });
        // Turned down in the desktop's dialog, or the desktop couldn't set them up.
        connect(m_portal, &PortalShortcuts::failed, this, [this] {
            m_enabled = false;
            emit enabledChanged();
            setStatus(tr("Global shortcuts weren't allowed"));
        });
    }
#endif
    if (supported())
        setStatus(tr("Global shortcuts are off"));
    else
        setStatus(tr("Global shortcuts are not available on this platform"));
}

bool GlobalShortcutController::trigger(int id) {
    switch (id) {
    case PlayPause:
        emit playPauseRequested();
        return true;
    case Previous:
        emit previousRequested();
        return true;
    case Next:
        emit nextRequested();
        return true;
    case Favorite:
        emit favoriteRequested();
        return true;
    case Search:
        emit searchRequested();
        return true;
    case MiniPlayer:
        emit miniPlayerRequested();
        return true;
    default:
        return false;
    }
}

GlobalShortcutController::~GlobalShortcutController() {
    unregisterShortcuts();
    QCoreApplication::instance()->removeNativeEventFilter(this);
}

bool GlobalShortcutController::supported() const {
#ifdef Q_OS_WIN
    return true;
#else
    return m_portal != nullptr;
#endif
}

bool GlobalShortcutController::enabled() const {
    return m_enabled;
}

QString GlobalShortcutController::status() const {
    return m_status;
}

QVariantMap GlobalShortcutController::shortcuts() const {
    return m_shortcuts;
}

void GlobalShortcutController::setEnabled(bool enabled) {
    if (enabled == m_enabled)
        return;
    if (enabled && !registerShortcuts())
        return;
    if (!enabled) {
        unregisterShortcuts();
        setStatus(tr("Global shortcuts are off"));
    }

    m_enabled = enabled;
    emit enabledChanged();
}

#ifdef Q_OS_WIN
// Puts the previous shortcut back when the new one can't be registered, such as one another app already holds.
bool GlobalShortcutController::registerOrRestore(const QString &action, const QString &previous) {
    if (registerShortcuts() && m_registeredIds.contains(shortcutId(action)))
        return true;
    m_shortcuts.insert(action, previous);
    registerShortcuts();
    return false;
}
#endif

bool GlobalShortcutController::setShortcut(const QString &action, const QString &shortcut) {
#ifdef Q_OS_WIN
    if (!m_shortcuts.contains(action))
        return false;

    UINT modifiers = 0;
    UINT key = 0;
    if (!parseShortcut(shortcut, &modifiers, &key)) {
        setStatus(tr("Use Ctrl or Alt with a letter, number, arrow, Space, F key, or supported punctuation"));
        return false;
    }
    if (takenByAnother(m_shortcuts, action, modifiers, key)) {
        setStatus(tr("Each shortcut must use a different key combination"));
        return false;
    }

    const QString normalized = normalizedShortcut(modifiers, key);
    const QString previous = m_shortcuts.value(action).toString();
    if (previous == normalized)
        return true;

    m_shortcuts.insert(action, normalized);
    if (m_enabled && !registerOrRestore(action, previous))
        return false;
    emit shortcutsChanged();
    return true;
#elif defined(CASSETTECAT_HAVE_DBUS)
    if (!m_portal || !m_shortcuts.contains(action))
        return false;
    if (!isPortalShortcut(shortcut)) {
        setStatus(tr("Use Ctrl or Alt with a letter, number, arrow, Space, F key, or supported punctuation"));
        return false;
    }
    if (takenByAnother(m_shortcuts, action, shortcut)) {
        setStatus(tr("Each shortcut must use a different key combination"));
        return false;
    }
    if (m_shortcuts.value(action).toString() == shortcut)
        return true;
    m_shortcuts.insert(action, shortcut);
    if (m_enabled)
        registerShortcuts();
    emit shortcutsChanged();
    return true;
#else
    Q_UNUSED(action);
    Q_UNUSED(shortcut);
    return false;
#endif
}

// Alt shows the letters that open each page, as Windows apps do, on every platform: holding it shows them after a
// moment and tapping it shows or hides them. They stay up until a letter, Esc, a click or another key.
bool GlobalShortcutController::eventFilter(QObject *watched, QEvent *event) {
    // A key event goes to the window and then on to its items; the window's copy is the one that counts.
    if (!qobject_cast<QWindow *>(watched))
        return false;
    switch (event->type()) {
    case QEvent::KeyPress: {
        const auto *key = static_cast<QKeyEvent *>(event);
        if (key->key() == Qt::Key_Alt) {
            // Some Linux setups report Alt's own press without Alt among the modifiers.
            if (!key->isAutoRepeat() && (key->modifiers() & ~Qt::AltModifier) == Qt::NoModifier) {
                m_altAlone = true;
                m_hintsShownByHold = false;
                m_altHoldTimer.start();
            }
            return false;
        }
        m_altAlone = false;
        m_altHoldTimer.stop();
        if (!m_accessHintsVisible)
            return false;
        setAccessHintsVisible(false);
        if (key->key() >= Qt::Key_A && key->key() <= Qt::Key_Z) {
            emit accessKeyRequested(QString(QChar(u'A' + (key->key() - Qt::Key_A))));
            return true;
        }
        return key->key() == Qt::Key_Escape;
    }
    case QEvent::KeyRelease:
        if (static_cast<QKeyEvent *>(event)->key() == Qt::Key_Alt) {
            m_altHoldTimer.stop();
            if (m_altAlone && !m_hintsShownByHold)
                setAccessHintsVisible(!m_accessHintsVisible);
            m_altAlone = false;
        }
        return false;
    case QEvent::MouseButtonPress:
    case QEvent::WindowDeactivate:
        m_altAlone = false;
        m_altHoldTimer.stop();
        setAccessHintsVisible(false);
        return false;
    default:
        return false;
    }
}

void GlobalShortcutController::setAccessHintsVisible(bool visible) {
    if (m_accessHintsVisible == visible)
        return;
    m_accessHintsVisible = visible;
    emit accessHintsRequested(visible);
}

bool GlobalShortcutController::nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) {
#ifdef Q_OS_WIN
    if (eventType != "windows_generic_MSG")
        return false;
    const auto *msg = static_cast<MSG *>(message);
    if (msg->message != WM_HOTKEY)
        return false;

    if (!trigger(int(msg->wParam)))
        return false;
    if (result)
        *result = 0;
    return true;
#else
    Q_UNUSED(eventType);
    Q_UNUSED(message);
    Q_UNUSED(result);
    return false;
#endif
}

bool GlobalShortcutController::registerShortcuts() {
#ifdef Q_OS_WIN
    unregisterShortcuts();
    int registeredCount = 0;
    QStringList conflicts;

    for (const auto &shortcut : shortcutDefinitions) {
        UINT modifiers = 0;
        UINT key = 0;
        const QString shortcutStr = m_shortcuts.value(QString::fromLatin1(shortcut.action)).toString();
        if (!parseShortcut(shortcutStr, &modifiers, &key)) {
            conflicts << tr(shortcut.label);
            continue;
        }
        if (RegisterHotKey(nullptr, shortcut.id, modifiers | MOD_NOREPEAT, key)) {
            m_registeredIds.insert(shortcut.id);
            registeredCount++;
        } else {
            conflicts << tr(shortcut.label);
        }
    }

    if (registeredCount == 0) {
        setStatus(tr("Unavailable: another application is using these shortcuts"));
        return false;
    }

    if (!conflicts.isEmpty()) {
        setStatus(
            tr("Active, but %n shortcut(s) unavailable: %1", "", int(conflicts.size())).arg(conflicts.join(", ")));
    } else {
        setStatus(tr("Global shortcuts are active"));
    }
    return true;
#elif defined(CASSETTECAT_HAVE_DBUS)
    if (!m_portal) {
        setStatus(tr("Global shortcuts are not available on this platform"));
        return false;
    }
    // The desktop may ask first, so the result comes later, through bound() or failed().
    QList<QPair<QString, QPair<QString, QString>>> shortcuts;
    for (const auto &entry : shortcutDefinitions) {
        const QString action = QString::fromLatin1(entry.action);
        shortcuts.append(
            {action, {tr(entry.label), PortalShortcuts::portalTrigger(m_shortcuts.value(action).toString())}});
    }
    m_portal->bind(shortcuts);
    setStatus(tr("Waiting for the desktop to allow the shortcuts"));
    return true;
#else
    setStatus(tr("Global shortcuts are not available on this platform"));
    return false;
#endif
}

bool GlobalShortcutController::selfCheck() {
    SelfCheck check("Global shortcuts");
#ifdef Q_OS_WIN
    UINT modifiers = 0;
    UINT key = 0;
    const auto keyFor = [&](const QString &shortcut) {
        key = 0;
        return parseShortcut(shortcut, &modifiers, &key) ? key : 0;
    };
    check.expect(keyFor("Ctrl+Alt+Space") == VK_SPACE, "reads a key");
    check.expect(modifiers == (MOD_CONTROL | MOD_ALT), "reads its modifiers");
    check.expect(!parseShortcut("Space", &modifiers, &key), "needs a modifier");
    check.expect(!parseShortcut("Ctrl+Alt+", &modifiers, &key), "needs a key");
    check.expect(keyFor("Ctrl+Equal") == VK_OEM_PLUS, "reads Equal");
    check.expect(keyFor("Ctrl++") == VK_OEM_PLUS, "reads +");
    check.expect(keyFor("Ctrl+Shift+Plus") == VK_OEM_PLUS, "reads Plus");
    check.expect(keyFor(QStringLiteral("Ctrl+»")) == VK_OEM_PLUS, "reads a layout's own name for +");
    check.expect(keyFor("Ctrl+-") == VK_OEM_MINUS, "reads -");
    check.expect(normalizedShortcut(MOD_CONTROL, VK_OEM_PLUS) == "Ctrl+Equal", "names Equal");
    check.expect(normalizedShortcut(MOD_CONTROL | MOD_SHIFT, VK_OEM_PLUS) == "Ctrl+Shift+Plus", "names Plus");
    check.expect(normalizedShortcut(MOD_CONTROL, VK_OEM_MINUS) == "Ctrl+-", "names -");
#elif defined(CASSETTECAT_HAVE_DBUS)
    check.expect(PortalShortcuts::portalTrigger("Ctrl+Alt+Space") == "CTRL+ALT+space", "portal space");
    check.expect(PortalShortcuts::portalTrigger("Ctrl+Alt+Left") == "CTRL+ALT+Left", "portal arrow");
    check.expect(PortalShortcuts::portalTrigger("Ctrl+Shift+F") == "CTRL+SHIFT+f", "portal letter");
    check.expect(PortalShortcuts::portalTrigger("Ctrl++") == "CTRL+plus", "portal plus");
    check.expect(PortalShortcuts::portalTrigger("Alt+F5") == "ALT+F5", "portal function key");
#endif
    return check.passed();
}

void GlobalShortcutController::unregisterShortcuts() {
#ifdef Q_OS_WIN
    for (int id : m_registeredIds) {
        UnregisterHotKey(nullptr, id);
    }
    m_registeredIds.clear();
#elif defined(CASSETTECAT_HAVE_DBUS)
    if (m_portal)
        m_portal->close();
#endif
}

void GlobalShortcutController::setStatus(const QString &status) {
    if (m_status == status)
        return;
    m_status = status;
    emit statusChanged();
}
