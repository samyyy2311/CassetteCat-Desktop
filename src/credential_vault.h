#pragma once

#include <QObject>
#include <QString>

// OS credential store wrapper (Windows Credential Manager; stubs elsewhere).
// Single responsibility: save/load/clear secrets plus log redaction.
// Secrets never touch QSettings or QML; QML receives metadata only.
// Preserves exact behavior from streaming.h.
class CredentialVault final : public QObject
{
    Q_OBJECT

public:
    using QObject::QObject;

    Q_INVOKABLE bool saveSecret(const QString &key, const QString &secret);
    Q_INVOKABLE QString loadSecret(const QString &key) const;
    Q_INVOKABLE bool clearSecret(const QString &key);

    static QString redactSecrets(const QString &text);
};
