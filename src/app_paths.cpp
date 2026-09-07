#include "app_paths.h"

#include <QDir>
#include <QStandardPaths>

QString settingsFilePath()
{
    const QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir().mkpath(configDir);
    return QDir(configDir).filePath("settings.ini");
}
