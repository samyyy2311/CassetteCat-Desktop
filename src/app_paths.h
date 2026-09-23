#pragma once

#include <QString>

QString settingsFilePath();
/// Returns the writable path used for the current debug log.
QString debugLogFilePath();
/// Returns the canonical application log path.
QString logFilePath();
