#pragma once

#include <QByteArray>
#include <QString>

QString saveCachedImage(const QByteArray &image, const QString &key, bool png, const QString &category);
