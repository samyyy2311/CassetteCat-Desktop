#pragma once

#include <QByteArray>
#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QPair>
#include <QString>
#include <QUrl>
#include <QVariantMap>

namespace streaming::protocol {

QString normalizeServerUrl(const QString &raw, int defaultPort = 0);
QString md5Hex(const QString &input);
QString randomSalt();
QUrl subsonicUrl(const QString &base, const QString &endpoint, const QString &username,
                 const QString &token, const QString &salt,
                 const QList<QPair<QString, QString>> &extra = {});
QJsonArray jsonArrayTolerant(const QJsonObject &object, const char *key);
QJsonObject parseSubsonicBody(const QByteArray &body);
QVariantMap subsonicTrackMap(const QJsonObject &song, const QString &albumName, const QString &albumCover);
QString jellyfinAuthHeader(const QString &deviceId, const QString &accessToken);
QVariantMap jellyfinTrackMap(const QJsonObject &item);

} // namespace streaming::protocol
