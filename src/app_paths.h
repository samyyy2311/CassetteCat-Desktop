#pragma once

#include <QString>

QString settingsFilePath();
/// Returns the writable path used for the current debug log.
QString debugLogFilePath();
/// Returns the canonical application log path.
QString logFilePath();
/// Returns the path to the persistent library cache.
QString libraryCacheFilePath();
