#pragma once

#include <QAbstractNativeEventFilter>
#include <QObject>
#include <QString>
#include <QTimer>
#include <QVariantMap>

class GlobalShortcutController final : public QObject, public QAbstractNativeEventFilter
{
    Q_OBJECT
    Q_PROPERTY(bool supported READ supported CONSTANT)
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QVariantMap shortcuts READ shortcuts NOTIFY shortcutsChanged)

public:
    explicit GlobalShortcutController(QObject *parent = nullptr);
    ~GlobalShortcutController() override;

    bool supported() const;
    bool enabled() const;
    QString status() const;
    QVariantMap shortcuts() const;

    Q_INVOKABLE void setEnabled(bool enabled);
    Q_INVOKABLE bool setShortcut(const QString &action, const QString &shortcut);
    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override;

    static bool selfCheck();

signals:
    void enabledChanged();
    void statusChanged();
    void shortcutsChanged();
    void playPauseRequested();
    void nextRequested();
    void previousRequested();
    void favoriteRequested();
    void searchRequested();
    void miniPlayerRequested();
    void accessHintsRequested(bool visible);
    void accessKeyRequested(const QString &key);

private:
    bool registerShortcuts();
    void unregisterShortcuts();
    void setStatus(const QString &status);

    bool m_enabled = false;
    bool m_altPressed = false;
    bool m_accessHintsVisible = false;
    QTimer m_altHoldTimer;
    QString m_status;
    QVariantMap m_shortcuts;
};
