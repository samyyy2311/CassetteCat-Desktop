#pragma once

#include <QObject>
#include <QSettings>
#include <QUrl>
#include <QVariant>

class SettingsController final : public QObject
{
    Q_OBJECT

public:
    explicit SettingsController(QObject *parent = nullptr);

    Q_INVOKABLE void setValue(const QString &key, const QVariant &value);
    Q_INVOKABLE void setValues(const QVariantMap &values);
    Q_INVOKABLE QVariant value(const QString &key, const QVariant &defaultValue = QVariant()) const;
    Q_INVOKABLE void sync();

    Q_INVOKABLE bool exportTextFile(const QUrl &url, const QString &text);
    Q_INVOKABLE QString readTextFile(const QUrl &url) const;

private:
    mutable QSettings m_settings;
};
