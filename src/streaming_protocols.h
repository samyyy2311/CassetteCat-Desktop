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

// An address with no scheme gets http:// on a home network and https:// otherwise; a typed http:// is kept anywhere.
QString normalizeServerUrl(const QString &raw, int defaultPort = 0);
// Plain HTTP to a server that isn't on a home network, which the app asks about before sending a password.
bool isUnencryptedPublicUrl(const QString &raw);
// A host on the home network: a private or loopback address, or a name only a home network answers for.
bool isPrivateOrLocalHost(const QString &host);
QString withoutTrailingSlashes(QString url);
QString md5Hex(const QString &input);
QString randomSalt();
QUrl subsonicUrl(const QString &base, const QString &endpoint, const QString &username, const QString &token,
                 const QString &salt, const QList<QPair<QString, QString>> &extra = {});
QJsonArray jsonArrayTolerant(const QJsonObject &object, const char *key);
QJsonObject parseSubsonicBody(const QByteArray &body);
QVariantMap subsonicTrackMap(const QJsonObject &song, const QString &albumName, const QString &albumCover);
QString jellyfinAuthHeader(const QString &deviceId, const QString &accessToken);
QVariantMap jellyfinTrackMap(const QJsonObject &item);

} // namespace streaming::protocol
