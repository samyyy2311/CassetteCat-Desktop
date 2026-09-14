#pragma once

#include <QObject>
#include <QString>

// OS credential store wrapper.
// Windows uses Credential Manager and Linux uses Secret Service via libsecret.
// Secrets must not be persisted in QSettings or exposed to QML.
class CredentialVault final : public QObject {
    Q_OBJECT

  public:
    using QObject::QObject;

    Q_INVOKABLE bool saveSecret(const QString &key, const QString &secret);
    Q_INVOKABLE QString loadSecret(const QString &key) const;
    Q_INVOKABLE bool clearSecret(const QString &key);

    static QString redactSecrets(const QString &text);
};
