#include "portal_shortcuts.h"

#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusMetaType>
#include <QDBusPendingCall>

namespace {

const QString portalService = QStringLiteral("org.freedesktop.portal.Desktop");
const QString portalPath = QStringLiteral("/org/freedesktop/portal/desktop");
const QString shortcutsInterface = QStringLiteral("org.freedesktop.portal.GlobalShortcuts");
const QString requestInterface = QStringLiteral("org.freedesktop.portal.Request");

struct PortalShortcut {
    QString id;
    QVariantMap properties;
};

QDBusArgument &operator<<(QDBusArgument &argument, const PortalShortcut &shortcut) {
    argument.beginStructure();
    argument << shortcut.id << shortcut.properties;
    argument.endStructure();
    return argument;
}

const QDBusArgument &operator>>(const QDBusArgument &argument, PortalShortcut &shortcut) {
    argument.beginStructure();
    argument >> shortcut.id >> shortcut.properties;
    argument.endStructure();
    return argument;
}

} // namespace

Q_DECLARE_METATYPE(PortalShortcut)

PortalShortcuts::PortalShortcuts(QObject *parent) : QObject(parent) {
    qDBusRegisterMetaType<PortalShortcut>();
    qDBusRegisterMetaType<QList<PortalShortcut>>();
    QDBusConnection::sessionBus().connect(
        portalService, portalPath, shortcutsInterface, QStringLiteral("Activated"), this,
        SLOT(onActivated(QDBusObjectPath, QString, qulonglong, QVariantMap)));
}

bool PortalShortcuts::available() {
    QDBusMessage get = QDBusMessage::createMethodCall(portalService, portalPath,
                                                      QStringLiteral("org.freedesktop.DBus.Properties"),
                                                      QStringLiteral("Get"));
    get << shortcutsInterface << QStringLiteral("version");
    const QDBusMessage reply = QDBusConnection::sessionBus().call(get, QDBus::Block, 2000);
    return reply.type() == QDBusMessage::ReplyMessage;
}

QString PortalShortcuts::portalTrigger(const QString &shortcut) {
    QStringList parts = shortcut.split(QLatin1Char('+'), Qt::SkipEmptyParts);
    if (shortcut.endsWith(QStringLiteral("++")))
        parts.append(QStringLiteral("plus"));
    QStringList trigger;
    for (int i = 0; i < parts.size(); ++i) {
        const QString part = parts.at(i);
        if (i < parts.size() - 1) {
            trigger << (part == QStringLiteral("Ctrl") ? QStringLiteral("CTRL") : part.toUpper());
            continue;
        }
        // The key itself is an XKB key name: lower case for letters and space, as named for the rest.
        if (part.size() == 1)
            trigger << (part == QStringLiteral("-") ? QStringLiteral("minus") : part.toLower());
        else if (part == QStringLiteral("Space") || part == QStringLiteral("Plus") || part == QStringLiteral("Equal"))
            trigger << part.toLower();
        else
            trigger << part;
    }
    return trigger.join(QLatin1Char('+'));
}

QString PortalShortcuts::requestPath(const QString &token) const {
    QString sender = QDBusConnection::sessionBus().baseService().mid(1);
    sender.replace(QLatin1Char('.'), QLatin1Char('_'));
    return portalPath + QStringLiteral("/request/") + sender + QLatin1Char('/') + token;
}

void PortalShortcuts::bind(const QList<QPair<QString, QPair<QString, QString>>> &shortcuts) {
    m_pending = shortcuts;
    // A session's shortcuts are bound once, so changed ones go to a new session.
    close();
    // The reply comes as a signal on a request object, so it's listened for before the call can answer.
    const QString token = QStringLiteral("cassettecat%1").arg(++m_tokenCount);
    QDBusConnection::sessionBus().connect(portalService, requestPath(token), requestInterface,
                                          QStringLiteral("Response"), this, SLOT(onSessionCreated(uint, QVariantMap)));
    QDBusMessage create = QDBusMessage::createMethodCall(portalService, portalPath, shortcutsInterface,
                                                         QStringLiteral("CreateSession"));
    create << QVariantMap{{QStringLiteral("handle_token"), token},
                          {QStringLiteral("session_handle_token"), QStringLiteral("cassettecat")}};
    QDBusConnection::sessionBus().asyncCall(create);
}

void PortalShortcuts::onSessionCreated(uint response, const QVariantMap &results) {
    if (response != 0) {
        emit failed();
        return;
    }
    m_session = QDBusObjectPath(results.value(QStringLiteral("session_handle")).toString());
    sendBind();
}

void PortalShortcuts::sendBind() {
    QList<PortalShortcut> list;
    for (const auto &entry : m_pending)
        list.append({entry.first, {{QStringLiteral("description"), entry.second.first},
                                   {QStringLiteral("preferred_trigger"), entry.second.second}}});
    const QString token = QStringLiteral("cassettecat%1").arg(++m_tokenCount);
    QDBusConnection::sessionBus().connect(portalService, requestPath(token), requestInterface,
                                          QStringLiteral("Response"), this, SLOT(onShortcutsBound(uint, QVariantMap)));
    QDBusMessage bind = QDBusMessage::createMethodCall(portalService, portalPath, shortcutsInterface,
                                                       QStringLiteral("BindShortcuts"));
    bind << QVariant::fromValue(m_session) << QVariant::fromValue(list) << QString()
         << QVariantMap{{QStringLiteral("handle_token"), token}};
    QDBusConnection::sessionBus().asyncCall(bind);
}

void PortalShortcuts::onShortcutsBound(uint response, const QVariantMap &results) {
    if (response != 0) {
        emit failed();
        return;
    }
    QList<PortalShortcut> granted;
    results.value(QStringLiteral("shortcuts")).value<QDBusArgument>() >> granted;
    emit bound(int(granted.size()));
}

void PortalShortcuts::onActivated(const QDBusObjectPath &session, const QString &shortcutId, qulonglong,
                                  const QVariantMap &) {
    if (session == m_session)
        emit activated(shortcutId);
}

void PortalShortcuts::close() {
    if (m_session.path().isEmpty())
        return;
    QDBusConnection::sessionBus().asyncCall(QDBusMessage::createMethodCall(
        portalService, m_session.path(), QStringLiteral("org.freedesktop.portal.Session"), QStringLiteral("Close")));
    m_session = QDBusObjectPath();
}
