#include "app_settings.h"

#include "app_paths.h"

#include <QFile>
#include <QSaveFile>

SettingsController::SettingsController(QObject *parent)
    : QObject(parent)
    , m_settings(settingsFilePath(), QSettings::IniFormat)
{
}

void SettingsController::setValue(const QString &key, const QVariant &value)
{
    m_settings.setValue(key, value);
    m_settings.sync();
}

void SettingsController::setValues(const QVariantMap &values)
{
    for (auto it = values.cbegin(); it != values.cend(); ++it) {
        m_settings.setValue(it.key(), it.value());
    }
    m_settings.sync();
}

QVariant SettingsController::value(const QString &key, const QVariant &defaultValue) const
{
    return m_settings.value(key, defaultValue);
}

void SettingsController::sync()
{
    m_settings.sync();
}

bool SettingsController::exportTextFile(const QUrl &url, const QString &text)
{
    const QString path = url.toLocalFile();
    if (path.isEmpty()) return false;
    QSaveFile output(path);
    if (!output.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
    if (output.write(text.toUtf8()) < 0) return false;
    return output.commit();
}

QString SettingsController::readTextFile(const QUrl &url) const
{
    const QString path = url.toLocalFile();
    if (path.isEmpty()) return {};
    QFile input(path);
    if (!input.open(QIODevice::ReadOnly | QIODevice::Text)) return {};
    return QString::fromUtf8(input.readAll());
}
