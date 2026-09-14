#include "credential_vault.h"

#include <QCoreApplication>
#include <QStringList>
#include <QUuid>

#include <iostream>

namespace {

const QStringList kCredentialKeys = {
    QStringLiteral("jellyfin"),
    QStringLiteral("subsonic"),
    QStringLiteral("scrobble/listenbrainz_token"),
    QStringLiteral("scrobble/librefm_session_key"),
};

int roundTripProbe()
{
    CredentialVault vault;
    const QString suffix = QUuid::createUuid().toString(QUuid::WithoutBraces);
    QStringList storedKeys;

    for (const QString &baseKey : kCredentialKeys) {
        const QString key = QStringLiteral("__selfcheck__/%1/%2").arg(baseKey, suffix);
        const QString value = QStringLiteral("probe-%1-%2").arg(baseKey, suffix);
        if (!vault.saveSecret(key, value)) {
            std::cerr << "vault save failed for " << baseKey.toStdString() << '\n';
            for (const QString &storedKey : storedKeys) vault.clearSecret(storedKey);
            return 1;
        }
        storedKeys.append(key);
        if (vault.loadSecret(key) != value) {
            std::cerr << "vault roundtrip failed for " << baseKey.toStdString() << '\n';
            for (const QString &storedKey : storedKeys) vault.clearSecret(storedKey);
            return 1;
        }
    }

    for (const QString &key : storedKeys) {
        if (!vault.clearSecret(key) || !vault.loadSecret(key).isEmpty()) {
            std::cerr << "vault clear failed\n";
            return 1;
        }
    }
    return 0;
}

int unavailableProbe()
{
    CredentialVault vault;
    const QString key = QStringLiteral("__selfcheck__/unavailable/%1")
                            .arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    const QString value = QStringLiteral("probe-unavailable");

    if (vault.saveSecret(key, value)) {
        vault.clearSecret(key);
        std::cerr << "vault unexpectedly stored a credential without Secret Service\n";
        return 1;
    }
    if (!vault.loadSecret(key).isEmpty()) {
        std::cerr << "vault unexpectedly loaded a credential without Secret Service\n";
        return 1;
    }
    if (vault.clearSecret(key)) {
        std::cerr << "vault unexpectedly cleared a credential without Secret Service\n";
        return 1;
    }
    return 0;
}

} // namespace

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    const QStringList args = app.arguments();
    return args.contains(QStringLiteral("--expect-unavailable")) ? unavailableProbe() : roundTripProbe();
}
