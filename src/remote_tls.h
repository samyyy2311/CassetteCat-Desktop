#pragma once

#include <QSslConfiguration>

/// The phone remote's TLS identity: a self-signed certificate made on first use and kept in the app's data folder.
/// Phones pin it when they pair. Returns a null configuration when it can neither be loaded nor made.
QSslConfiguration remoteTlsConfiguration();
