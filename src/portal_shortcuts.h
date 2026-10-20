#pragma once

#include <QDBusObjectPath>
#include <QObject>
#include <QVariantMap>

// App-wide shortcuts on Linux through the desktop portal, which is how Wayland desktops let an app hear keys while
// it isn't focused. The desktop asks the user to approve the shortcuts and may let them pick other keys.
class PortalShortcuts final : public QObject {
    Q_OBJECT

  public:
    explicit PortalShortcuts(QObject *parent = nullptr);

    static bool available();
    // Asks for these shortcuts, as (action, (description, preferred trigger)), replacing any bound before.
    void bind(const QList<QPair<QString, QPair<QString, QString>>> &shortcuts);
    void close();

    // "Ctrl+Alt+Space" as the portal writes triggers, "CTRL+ALT+space".
    static QString portalTrigger(const QString &shortcut);

  signals:
    void bound(int count);
    void failed();
    void activated(const QString &action);

  private slots:
    void onSessionCreated(uint response, const QVariantMap &results);
    void onShortcutsBound(uint response, const QVariantMap &results);
    void onActivated(const QDBusObjectPath &session, const QString &shortcutId, qulonglong timestamp,
                     const QVariantMap &options);

  private:
    QString requestPath(const QString &token) const;
    void sendBind();

    QDBusObjectPath m_session;
    QList<QPair<QString, QPair<QString, QString>>> m_pending;
    int m_tokenCount = 0;
};
