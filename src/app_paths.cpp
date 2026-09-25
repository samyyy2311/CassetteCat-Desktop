#include "app_paths.h"

#include <QDir>
#include <QStandardPaths>

QString settingsFilePath() {
    const QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir().mkpath(configDir);
    return QDir(configDir).filePath("settings.ini");
}

/// @copydoc debugLogFilePath
QString debugLogFilePath() {
    const QString logDir =
        QDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation)).filePath("logs");
    QDir().mkpath(logDir);
    return QDir(logDir).filePath("debug.log");
}

/// @copydoc logFilePath
QString logFilePath() {
    return debugLogFilePath();
}

QString libraryCacheFilePath() {
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    QDir().mkpath(cacheDir);
    return QDir(cacheDir).filePath("library_cache.json");
}

QString listeningLogFilePath() {
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    QDir().mkpath(dataDir);
    return QDir(dataDir).filePath("listening_log.jsonl");
}
