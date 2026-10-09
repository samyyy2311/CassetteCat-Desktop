#ifdef CASSETTECAT_HAVE_LIBSECRET
#include <libsecret/secret.h>
#endif

#include "credential_vault.h"

#include <QCoreApplication>
#include <QDebug>
#include <QRegularExpression>

#ifdef _WIN32
#define NOMINMAX
#include <windows.h>
#include <wincred.h>
#endif

#ifdef __APPLE__
#include <Security/Security.h>
#endif

namespace {

#ifdef __APPLE__
// One generic password per key, under the app's own service name.
CFMutableDictionaryRef keychainQuery(const QString &key) {
    CFMutableDictionaryRef query =
        CFDictionaryCreateMutable(nullptr, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(query, kSecClass, kSecClassGenericPassword);
    CFDictionarySetValue(query, kSecAttrService, CFSTR("io.github.samyyy2311.CassetteCat"));
    const CFStringRef account = key.toCFString();
    CFDictionarySetValue(query, kSecAttrAccount, account);
    CFRelease(account);
    return query;
}
#endif

#ifdef CASSETTECAT_HAVE_LIBSECRET
const SecretSchema *credentialSchema() {
    static const SecretSchema schema = {
        "io.github.samyyy2311.CassetteCat.Credential",
        SECRET_SCHEMA_NONE,
        {
            {"key", SECRET_SCHEMA_ATTRIBUTE_STRING},
            {nullptr, static_cast<SecretSchemaAttributeType>(0)},
        },
    };
    return &schema;
}

void logSecretServiceError(const char *operation, GError *error) {
    if (!error) {
        return;
    }
    qWarning() << "Secret Service" << operation << "failed:" << error->message;
    g_error_free(error);
}
#endif

} // namespace

bool CredentialVault::saveSecret(const QString &key, const QString &secret) {
    if (key.isEmpty() || secret.isEmpty()) {
        return false;
    }

#ifdef _WIN32
    const std::wstring target = (QCoreApplication::applicationName() + '/' + key).toStdWString();
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
#elif defined(CASSETTECAT_HAVE_LIBSECRET)
    const QByteArray keyUtf8 = key.toUtf8();
    const QByteArray secretUtf8 = secret.toUtf8();
    const QByteArray labelUtf8 = (QStringLiteral("CassetteCat ") + key).toUtf8();
    GError *error = nullptr;
    const gboolean stored =
        secret_password_store_sync(credentialSchema(), SECRET_COLLECTION_DEFAULT, labelUtf8.constData(),
                                   secretUtf8.constData(), nullptr, &error, "key", keyUtf8.constData(), nullptr);
    if (error) {
        logSecretServiceError("write", error);
        return false;
    }
    return stored == TRUE;
#elif defined(__APPLE__)
    CFMutableDictionaryRef query = keychainQuery(key);
    const CFDataRef data = secret.toUtf8().toCFData();
    // Updating in place keeps the previous secret if the write fails.
    CFMutableDictionaryRef changes =
        CFDictionaryCreateMutable(nullptr, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(changes, kSecValueData, data);
    OSStatus status = SecItemUpdate(query, changes);
    CFRelease(changes);
    if (status == errSecItemNotFound) {
        CFDictionarySetValue(query, kSecValueData, data);
        status = SecItemAdd(query, nullptr);
    }
    CFRelease(data);
    CFRelease(query);
    if (status == errSecSuccess) {
        return true;
    }
    qWarning() << "Keychain write failed:" << status;
    return false;
#else
    Q_UNUSED(key);
    Q_UNUSED(secret);
    return false;
#endif
}

QString CredentialVault::loadSecret(const QString &key) const {
    if (key.isEmpty()) {
        return {};
    }

#ifdef _WIN32
    const std::wstring target = (QCoreApplication::applicationName() + '/' + key).toStdWString();
    PCREDENTIALW credential = nullptr;
    if (CredReadW(target.c_str(), CRED_TYPE_GENERIC, 0, &credential) == FALSE) {
        return {};
    }
    const QString secret = QString::fromWCharArray(reinterpret_cast<const wchar_t *>(credential->CredentialBlob),
                                                   credential->CredentialBlobSize / sizeof(wchar_t));
    CredFree(credential);
    return secret;
#elif defined(CASSETTECAT_HAVE_LIBSECRET)
    const QByteArray keyUtf8 = key.toUtf8();
    GError *error = nullptr;
    gchar *password =
        secret_password_lookup_sync(credentialSchema(), nullptr, &error, "key", keyUtf8.constData(), nullptr);
    if (error) {
        logSecretServiceError("read", error);
        return {};
    }
    if (!password) {
        return {};
    }
    const QString secret = QString::fromUtf8(password);
    secret_password_free(password);
    return secret;
#elif defined(__APPLE__)
    CFMutableDictionaryRef query = keychainQuery(key);
    CFDictionarySetValue(query, kSecReturnData, kCFBooleanTrue);
    CFDictionarySetValue(query, kSecMatchLimit, kSecMatchLimitOne);
    CFTypeRef result = nullptr;
    const OSStatus status = SecItemCopyMatching(query, &result);
    CFRelease(query);
    if (status != errSecSuccess || !result) {
        return {};
    }
    const QString secret = QString::fromUtf8(QByteArray::fromCFData(static_cast<CFDataRef>(result)));
    CFRelease(result);
    return secret;
#else
    Q_UNUSED(key);
    return {};
#endif
}

bool CredentialVault::clearSecret(const QString &key) {
    if (key.isEmpty()) {
        return false;
    }

#ifdef _WIN32
    const std::wstring target = (QCoreApplication::applicationName() + '/' + key).toStdWString();
    if (CredDeleteW(target.c_str(), CRED_TYPE_GENERIC, 0) != FALSE) {
        return true;
    }
    return GetLastError() == ERROR_NOT_FOUND;
#elif defined(CASSETTECAT_HAVE_LIBSECRET)
    const QByteArray keyUtf8 = key.toUtf8();
    GError *error = nullptr;
    secret_password_clear_sync(credentialSchema(), nullptr, &error, "key", keyUtf8.constData(), nullptr);
    if (error) {
        logSecretServiceError("delete", error);
        return false;
    }
    return true;
#elif defined(__APPLE__)
    CFMutableDictionaryRef query = keychainQuery(key);
    const OSStatus status = SecItemDelete(query);
    CFRelease(query);
    return status == errSecSuccess || status == errSecItemNotFound;
#else
    Q_UNUSED(key);
    return false;
#endif
}

QString CredentialVault::redactSecrets(const QString &text) {
    QString out = text;
    out.replace(QRegularExpression("(Token=\")[^\"]*(\")", QRegularExpression::CaseInsensitiveOption),
                "\\1[redacted]\\2");
    out.replace(QRegularExpression("((?:^|[?&\\s])(?:api_key|access_token|token|t|s)=)[^&\\s\"]*",
                                   QRegularExpression::CaseInsensitiveOption),
                "\\1[redacted]");
    out.replace(QRegularExpression("((?:Authorization|X-Emby-Token):\\s*)[^\\r\\n]+",
                                   QRegularExpression::CaseInsensitiveOption),
                "\\1[redacted]");
    return out;
}
