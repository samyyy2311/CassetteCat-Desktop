#pragma once

#include <QString>
#include <QVariantList>

/// The audio files the library reads, as QDir name filters.
QStringList audioFileFilters();
QVariantList scanTracks(const QString &folder);
bool scanSelfCheck();
