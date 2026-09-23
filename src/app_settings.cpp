#include "app_settings.h"

#include "app_paths.h"

#include <QClipboard>
#include <QDebug>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QProcess>
#include <QSaveFile>
#include <QTextStream>
#include <QMutexLocker>

namespace {

QVariant coerceSettingsValue(const QVariant &val, const QVariant &defaultValue)
{
    if (!val.isValid()) {
        return defaultValue;
    }

    if (defaultValue.isValid() && !defaultValue.isNull()) {
        switch (defaultValue.typeId()) {
        case QMetaType::Bool: {
            if (val.typeId() == QMetaType::QString) {
                const QString s = val.toString().trimmed();
                if (s.compare(QLatin1String("true"), Qt::CaseInsensitive) == 0 || s == QLatin1String("1"))
                    return true;
                if (s.compare(QLatin1String("false"), Qt::CaseInsensitive) == 0 || s == QLatin1String("0"))
                    return false;
            }
            return val.toBool();
        }
        case QMetaType::Int:
            return val.toInt();
        case QMetaType::Double:
            return val.toDouble();
        case QMetaType::Float:
            return val.toFloat();
        case QMetaType::LongLong:
            return val.toLongLong();
        case QMetaType::ULongLong:
            return val.toULongLong();
        case QMetaType::QString:
            return val.toString();
        case QMetaType::QStringList:
            return val.toStringList();
        case QMetaType::QVariantList:
            return val.toList();
        default:
            break;
        }
    } else if (val.typeId() == QMetaType::QString) {
        const QString s = val.toString().trimmed();
        if (s.compare(QLatin1String("true"), Qt::CaseInsensitive) == 0)
            return true;
        if (s.compare(QLatin1String("false"), Qt::CaseInsensitive) == 0)
            return false;
    }

    return val;
}

} // namespace

SettingsController::SettingsController(QObject *parent)
    : QObject(parent)
    , m_settings(settingsFilePath(), QSettings::IniFormat)
{
    s_instance = this;
    m_settings.sync();
}

SettingsController::~SettingsController()
{
    if (s_instance == this) {
        s_instance = nullptr;
    }
    sync();
}

SettingsController *SettingsController::instance()
{
    return s_instance;
}

QVariant SettingsController::globalValue(const QString &key, const QVariant &defaultValue)
{
    if (s_instance) {
        return s_instance->value(key, defaultValue);
    }
    QSettings settings(settingsFilePath(), QSettings::IniFormat);
    return coerceSettingsValue(settings.value(key, defaultValue), defaultValue);
}

void SettingsController::setGlobalValue(const QString &key, const QVariant &value)
{
    if (s_instance) {
        s_instance->setValue(key, value);
        return;
    }
    QSettings settings(settingsFilePath(), QSettings::IniFormat);
    settings.setValue(key, value);
    settings.sync();
}

void SettingsController::setValue(const QString &key, const QVariant &value)
{
    QMutexLocker locker(&m_mutex);
    m_settings.setValue(key, value);
    m_settings.sync();
}

void SettingsController::setValues(const QVariantMap &values)
{
    QMutexLocker locker(&m_mutex);
    for (auto it = values.cbegin(); it != values.cend(); ++it) {
        m_settings.setValue(it.key(), it.value());
    }
    m_settings.sync();
}

QVariant SettingsController::value(const QString &key, const QVariant &defaultValue) const
{
    QMutexLocker locker(&m_mutex);
    return coerceSettingsValue(m_settings.value(key, defaultValue), defaultValue);
}

void SettingsController::sync()
{
    QMutexLocker locker(&m_mutex);
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

void SettingsController::copyToClipboard(const QString &text)
{
    if (auto *cb = QGuiApplication::clipboard()) {
        cb->setText(text);
    }
}

void SettingsController::showInFolder(const QString &filePath)
{
    if (filePath.isEmpty()) return;
    const QString native = QDir::toNativeSeparators(filePath);
#if defined(Q_OS_WIN)
    QProcess::startDetached("explorer.exe", {"/select,", native});
#else
    QDesktopServices::openUrl(QUrl::fromLocalFile(QFileInfo(filePath).absolutePath()));
#endif
}

QString SettingsController::getLogFilePath() const
{
    return logFilePath();
}

QString SettingsController::readRecentLogs(int maxLines) const
{
    if (maxLines <= 0) {
        return QString();
    }
    QFile file(logFilePath());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QStringLiteral("No logs available.");
    }
    const qint64 fileSize = file.size();
    if (fileSize == 0) {
        return QString();
    }
    const qint64 stepSize = qMax<qint64>(64 * 1024, static_cast<qint64>(maxLines) * 512);
    qint64 endOffset = fileSize;
    qint64 offset = qMax<qint64>(0, fileSize - stepSize);

    QStringList lines;
    while (true) {
        file.seek(offset);
        QTextStream in(&file);
        if (offset > 0) {
            in.readLine();
        }
        QStringList chunkLines;
        while (in.pos() < endOffset && !in.atEnd()) {
            chunkLines.append(in.readLine());
        }
        for (int i = chunkLines.size() - 1; i >= 0; --i) {
            lines.prepend(chunkLines.at(i));
        }
        if (lines.size() > maxLines) {
            lines = lines.mid(lines.size() - maxLines);
        }
        if (lines.size() >= maxLines || offset == 0) {
            break;
        }
        endOffset = offset;
        offset = qMax<qint64>(0, offset - stepSize);
    }

    return lines.join('\n');
}

void SettingsController::clearLogs()
{
    QFile file(logFilePath());
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.close();
    }
}

void SettingsController::openLogFile()
{
    const QString path = logFilePath();
    if (QFileInfo::exists(path)) {
        QDesktopServices::openUrl(QUrl::fromLocalFile(path));
    }
}

