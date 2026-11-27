#include "app_paths.h"

#include <QDir>
#include <QFile>
#include <QStandardPaths>

QString settingsFilePath() {
#ifdef Q_OS_MACOS
    // ~/Library/Preferences is for the system's own preference plists; an app's files go in Application Support.
    // Settings saved there by earlier versions are copied across once, and stay in use if the copy fails.
    const QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    QDir().mkpath(configDir);
    const QString settings = QDir(configDir).filePath("settings.ini");
    const QString earlier =
        QDir(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)).filePath("settings.ini");
    if (!QFile::exists(settings) && QFile::exists(earlier) && !QFile::copy(earlier, settings))
        return earlier;
    return settings;
#else
    const QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
#endif
    QDir().mkpath(configDir);
    return QDir(configDir).filePath("settings.ini");
}

QString debugLogFilePath() {
    const QString logDir =
        QDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation)).filePath("logs");
    QDir().mkpath(logDir);
    return QDir(logDir).filePath("debug.log");
}

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

QString phoneBackupFilePath() {
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    QDir().mkpath(dataDir);
    return QDir(dataDir).filePath("phone_backup.json");
}
