#pragma once

#include <QObject>
#include <QRecursiveMutex>
#include <QSettings>
#include <QUrl>
#include <QVariant>

class SettingsController final : public QObject {
    Q_OBJECT

  public:
    explicit SettingsController(QObject *parent = nullptr);
    ~SettingsController() override;

    static SettingsController *instance();
    static QVariant globalValue(const QString &key, const QVariant &defaultValue = QVariant());
    static void setGlobalValue(const QString &key, const QVariant &value);
    static bool selfCheck();

    Q_INVOKABLE void setValue(const QString &key, const QVariant &value);
    Q_INVOKABLE void setValues(const QVariantMap &values);
    Q_INVOKABLE QVariant value(const QString &key, const QVariant &defaultValue = QVariant()) const;
    Q_INVOKABLE void sync();

    Q_INVOKABLE bool exportTextFile(const QUrl &url, const QString &text);
    Q_INVOKABLE QString readTextFile(const QUrl &url) const;
    Q_INVOKABLE void copyToClipboard(const QString &text);
    Q_INVOKABLE void showInFolder(const QString &filePath);
    /// Returns the file path used for application diagnostics.
    Q_INVOKABLE QString getLogFilePath() const;
    /// Returns at most the newest \p maxLines lines from the debug log.
    Q_INVOKABLE QString readRecentLogs(int maxLines = 150) const;
    /// Truncates the current log and removes its rotated predecessor.
    Q_INVOKABLE void clearLogs();
    /// Opens the current debug log with the platform default handler.
    Q_INVOKABLE void openLogFile();

  private:
    static inline SettingsController *s_instance = nullptr;
    mutable QRecursiveMutex m_mutex;
    mutable QSettings m_settings;
};
