#include "app_paths.h"

#include <QDir>
#include <QStandardPaths>

QString settingsFilePath()
{
    const QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir().mkpath(configDir);
    return QDir(configDir).filePath("settings.ini");
}

QString debugLogFilePath()
{
    const QString logDir = QDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation))
                               .filePath("logs");
    QDir().mkpath(logDir);
    return QDir(logDir).filePath("debug.log");
}

QString logFilePath()
{
    return debugLogFilePath();
}
