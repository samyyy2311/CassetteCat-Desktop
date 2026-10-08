#include "remote_tls.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QSaveFile>
#include <QSslCertificate>
#include <QSslKey>
#include <QStandardPaths>

#include <functional>
#include <memory>
#include <openssl/bn.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/x509.h>

namespace {
constexpr long kValiditySeconds = 20L * 365 * 24 * 60 * 60;

QString identityPath(const QString &name) {
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    QDir().mkpath(dir);
    return QDir(dir).filePath(name);
}

QByteArray pem(const std::function<int(BIO *)> &write) {
    std::unique_ptr<BIO, decltype(&BIO_free)> bio(BIO_new(BIO_s_mem()), BIO_free);
    if (!bio || write(bio.get()) != 1)
        return {};
    char *data = nullptr;
    const long size = BIO_get_mem_data(bio.get(), &data);
    return QByteArray(data, static_cast<qsizetype>(size));
}

// An RSA key, which every platform's TLS stack can serve with, and a self-signed certificate for it, as PEM.
bool makeIdentity(QByteArray &certificatePem, QByteArray &keyPem) {
    std::unique_ptr<EVP_PKEY, decltype(&EVP_PKEY_free)> key(
        EVP_PKEY_Q_keygen(nullptr, nullptr, "RSA", static_cast<size_t>(2048)), EVP_PKEY_free);
    std::unique_ptr<X509, decltype(&X509_free)> certificate(X509_new(), X509_free);
    if (!key || !certificate)
        return false;
    X509_set_version(certificate.get(), 2);
    std::unique_ptr<BIGNUM, decltype(&BN_free)> serial(BN_new(), BN_free);
    if (!serial || BN_rand(serial.get(), 127, BN_RAND_TOP_ANY, BN_RAND_BOTTOM_ANY) != 1 ||
        !BN_to_ASN1_INTEGER(serial.get(), X509_get_serialNumber(certificate.get())))
        return false;
    X509_gmtime_adj(X509_getm_notBefore(certificate.get()), -60 * 60);
    X509_gmtime_adj(X509_getm_notAfter(certificate.get()), kValiditySeconds);
    X509_NAME *name = X509_get_subject_name(certificate.get());
    X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC, reinterpret_cast<const unsigned char *>("CassetteCat"), -1, -1,
                               0);
    if (X509_set_issuer_name(certificate.get(), name) != 1 || X509_set_pubkey(certificate.get(), key.get()) != 1 ||
        X509_sign(certificate.get(), key.get(), EVP_sha256()) == 0)
        return false;
    certificatePem = pem([&](BIO *bio) { return PEM_write_bio_X509(bio, certificate.get()); });
    keyPem =
        pem([&](BIO *bio) { return PEM_write_bio_PrivateKey(bio, key.get(), nullptr, nullptr, 0, nullptr, nullptr); });
    return !certificatePem.isEmpty() && !keyPem.isEmpty();
}

bool save(const QString &path, const QByteArray &data, QFileDevice::Permissions permissions) {
    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly) || file.write(data) != data.size() || !file.commit())
        return false;
    return QFile::setPermissions(path, permissions);
}
} // namespace

QSslConfiguration remoteTlsConfiguration() {
    const QString certificatePath = identityPath(QStringLiteral("remote_certificate.pem"));
    const QString keyPath = identityPath(QStringLiteral("remote_key.pem"));

    QSslCertificate certificate;
    QSslKey key;
    QFile certificateFile(certificatePath);
    QFile keyFile(keyPath);
    if (certificateFile.open(QIODevice::ReadOnly) && keyFile.open(QIODevice::ReadOnly)) {
        certificate = QSslCertificate(certificateFile.readAll(), QSsl::Pem);
        key = QSslKey(keyFile.readAll(), QSsl::Rsa, QSsl::Pem);
    }
    // Phones pin this certificate, so a new one is made only when there is none to keep.
    if (certificate.isNull() || key.isNull()) {
        QByteArray certificatePem;
        QByteArray keyPem;
        if (!makeIdentity(certificatePem, keyPem) ||
            !save(keyPath, keyPem, QFileDevice::ReadOwner | QFileDevice::WriteOwner) ||
            !save(certificatePath, certificatePem, QFileDevice::ReadOwner | QFileDevice::WriteOwner)) {
            qWarning() << "Phone remote could not create its TLS certificate";
            return {};
        }
        certificate = QSslCertificate(certificatePem, QSsl::Pem);
        key = QSslKey(keyPem, QSsl::Rsa, QSsl::Pem);
    }

    QSslConfiguration configuration = QSslConfiguration::defaultConfiguration();
    configuration.setLocalCertificate(certificate);
    configuration.setPrivateKey(key);
    configuration.setProtocol(QSsl::TlsV1_2OrLater);
    configuration.setPeerVerifyMode(QSslSocket::VerifyNone);
    return configuration;
}
