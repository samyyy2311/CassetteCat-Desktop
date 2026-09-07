#include "credential_vault.h"

#include <QRegularExpression>
#include <QDebug>

#ifdef _WIN32
#include <windows.h>
#include <wincred.h>
#endif

bool CredentialVault::saveSecret(const QString &key, const QString &secret)
{
#ifdef _WIN32
    if (key.isEmpty() || secret.isEmpty()) {
        return false;
    }
    const std::wstring target = (QString("CassetteCat/") + key).toStdWString();
    const std::wstring blob = secret.toStdWString();
    CREDENTIALW credential{};
    credential.Type = CRED_TYPE_GENERIC;
    credential.TargetName = const_cast<LPWSTR>(target.c_str());
    credential.CredentialBlobSize = static_cast<DWORD>(blob.size() * sizeof(wchar_t));
    credential.CredentialBlob = reinterpret_cast<LPBYTE>(const_cast<wchar_t *>(blob.c_str()));
    credential.Persist = CRED_PERSIST_LOCAL_MACHINE;
    if (CredWriteW(&credential, 0) != FALSE) {
        return true;
    }
    qWarning() << "Credential Manager write failed:" << GetLastError();
    return false;
#else
    Q_UNUSED(key);
    Q_UNUSED(secret);
    return false;
#endif
}

QString CredentialVault::loadSecret(const QString &key) const
{
#ifdef _WIN32
    if (key.isEmpty()) {
        return {};
    }
    const std::wstring target = (QString("CassetteCat/") + key).toStdWString();
    PCREDENTIALW credential = nullptr;
    if (CredReadW(target.c_str(), CRED_TYPE_GENERIC, 0, &credential) == FALSE) {
        return {};
    }
    const QString secret = QString::fromWCharArray(
        reinterpret_cast<const wchar_t *>(credential->CredentialBlob),
        credential->CredentialBlobSize / sizeof(wchar_t));
    CredFree(credential);
    return secret;
#else
    Q_UNUSED(key);
    return {};
#endif
}

bool CredentialVault::clearSecret(const QString &key)
{
#ifdef _WIN32
    if (key.isEmpty()) {
        return false;
    }
    const std::wstring target = (QString("CassetteCat/") + key).toStdWString();
    if (CredDeleteW(target.c_str(), CRED_TYPE_GENERIC, 0) != FALSE) {
        return true;
    }
    return GetLastError() == ERROR_NOT_FOUND;
#else
    Q_UNUSED(key);
    return false;
#endif
}

QString CredentialVault::redactSecrets(const QString &text)
{
    QString out = text;
    // Jellyfin Authorization header token.
    out.replace(QRegularExpression("(Token=\")[^\"]*(\")", QRegularExpression::CaseInsensitiveOption),
                "\\1[redacted]\\2");
    // Query parameters carrying auth material.
    out.replace(QRegularExpression("((?:^|[?&\\s])(?:api_key|access_token|token|t|s)=)[^&\\s\"]*",
                                   QRegularExpression::CaseInsensitiveOption), "\\1[redacted]");
    out.replace(QRegularExpression("((?:Authorization|X-Emby-Token):\\s*)[^\\r\\n]+",
                                   QRegularExpression::CaseInsensitiveOption), "\\1[redacted]");
    return out;
}
