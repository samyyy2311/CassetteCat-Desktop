#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalServer>
#include <QLocalSocket>
#include <QDebug>
#include <QCoreApplication>
#include <QFile>
#include <QFileInfo>
#include <QApplication>
#include <QFont>
#include <QIcon>
#include <QMutex>
#include <QMutexLocker>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSurfaceFormat>
#include <QSize>
#include <QStandardPaths>
#include <QStringList>
#include <QThreadPool>
#include <QUrl>
#include <QVariantList>
#include <QThread>
#include <QLocale>
#include <QTranslator>
#include <cstring>
#include <iostream>
#include <optional>
#include <string>

#include <QFontDatabase>

#include "smtc_controller.h"
#include "mpris_controller.h"
#include "global_shortcut_controller.h"
#include "tray_controller.h"
#include "window_frame.h"

#include "app_paths.h"
#include "app_settings.h"
#include "audio_metadata.h"
#include "credential_vault.h"
#include "discord_presence.h"
#include "remote_control.h"
#include "image_cache.h"
#include "library_controller.h"
#include "library_scanner.h"
#include "player_controller.h"
#include "services_controller.h"
#include "streaming.h"
#ifdef Q_OS_WIN
#include <windows.h>
#include <dwmapi.h>
#include <shobjidl.h>
#include <propkey.h>
#include <propvarutil.h>
#include <appmodel.h>
#endif

namespace {

#ifdef CASSETTECAT_DEV_BUILD
constexpr auto kApplicationName = "CassetteCat Dev";
constexpr auto kInstanceServerName = "CassetteCat.Desktop.Dev.Instance";
#else
constexpr auto kApplicationName = "CassetteCat";
constexpr auto kInstanceServerName = "CassetteCat.Desktop.Instance";
#endif
constexpr qint64 kMaxDebugLogBytes = 1024 * 1024;
QMutex gDebugLogMutex;
QString gDebugLogPath;
qint64 gDebugLogBytes = 0;
#ifdef _WIN32
#ifdef CASSETTECAT_DEV_BUILD
constexpr auto kInstanceMutexName = L"CassetteCat.AudioEngine.Desktop.Dev.InstanceMutex";
constexpr auto kAppUserModelId = L"CassetteCat.AudioEngine.Desktop.Dev.App";
#else
// The installer checks this mutex to see whether the app is running.
constexpr auto kInstanceMutexName = L"CassetteCat.AudioEngine.Desktop.InstanceMutex";
constexpr auto kAppUserModelId = L"CassetteCat.AudioEngine.Desktop.App";
#endif
#endif

// MSIX installs come only from the Microsoft Store, which delivers their updates itself.
bool installedFromStore() {
#ifdef Q_OS_WIN
    UINT32 length = 0;
    return GetCurrentPackageFullName(&length, nullptr) == ERROR_INSUFFICIENT_BUFFER;
#else
    return false;
#endif
}

bool notifyRunningInstance(const QString &serverName, const QString &openPath = {}) {
    QLocalSocket socket;
    socket.connectToServer(serverName);
    if (!socket.waitForConnected(200)) {
        qWarning() << "Instance handoff connection failed:" << socket.errorString();
        return false;
    }
    QJsonObject request{{"action", "activate"}};
    if (!openPath.isEmpty())
        request.insert("path", openPath);
    socket.write(QJsonDocument(request).toJson(QJsonDocument::Compact));
    const bool written = socket.waitForBytesWritten(200);
    if (!written)
        qWarning() << "Instance handoff write failed:" << socket.errorString();
    return written;
}

enum class InstanceStartResult {
    Started,
    HandedOff,
    Unavailable,
};

InstanceStartResult startInstanceServer(QLocalServer &server, const QString &serverName, const QString &openPath = {}) {
#ifndef Q_OS_WIN
    server.setSocketOptions(QLocalServer::UserAccessOption);
#endif
    if (server.listen(serverName))
        return InstanceStartResult::Started;
    if (notifyRunningInstance(serverName, openPath))
        return InstanceStartResult::HandedOff;

    QLocalServer::removeServer(serverName);
    if (server.listen(serverName))
        return InstanceStartResult::Started;

    qWarning() << "Single-instance server unavailable:" << server.errorString();
    return InstanceStartResult::Unavailable;
}

bool singleInstanceSelfCheck() {
    const QString name =
        QString::fromLatin1(kInstanceServerName) + ".self-check." + QString::number(QCoreApplication::applicationPid());
    QLocalServer::removeServer(name);
    QLocalServer primary;
    if (!primary.listen(name))
        return false;

    QLocalSocket client;
    client.connectToServer(name);
    const bool connected = client.waitForConnected(500);

    primary.close();
    QLocalServer::removeServer(name);
    return connected;
}

/// Restores, raises, and activates the application \p window.
void activateWindow(QQuickWindow *window) {
    if (!window)
        return;
    // Main.qml remembers whether the window was maximized before it was hidden or minimized.
    if (!window->isVisible() || window->visibility() == QWindow::Minimized)
        QMetaObject::invokeMethod(window, "restoreWindow");
#ifdef Q_OS_WIN
    HWND hwnd = reinterpret_cast<HWND>(window->winId());
    if (hwnd) {
        if (IsIconic(hwnd)) {
            ShowWindow(hwnd, SW_RESTORE);
        } else {
            ShowWindow(hwnd, SW_SHOW);
        }
        SetForegroundWindow(hwnd);
    }
#endif
    window->raise();
    window->requestActivate();
}

/// Rotates the debug log when appending \p incomingBytes would exceed its limit.
void rotateDebugLogIfNeeded(qint64 incomingBytes) {
    if (gDebugLogPath.isEmpty() || gDebugLogBytes + incomingBytes <= kMaxDebugLogBytes)
        return;

    const QString rotatedPath = gDebugLogPath + ".1";
    QFile::remove(rotatedPath);
    if (QFile::exists(gDebugLogPath))
        QFile::rename(gDebugLogPath, rotatedPath);
    gDebugLogBytes = 0;
}

/// Initializes the debug-log path, size accounting, and startup rotation.
void initializeDebugLog() {
    QMutexLocker locker(&gDebugLogMutex);
    gDebugLogPath = debugLogFilePath();
    gDebugLogBytes = QFileInfo(gDebugLogPath).size();
    rotateDebugLogIfNeeded(0);
}

/// Redacts and writes a Qt diagnostic \p message to stderr and the debug log.
void writeDebugLog(QtMsgType, const QMessageLogContext &, const QString &message) {
    QMutexLocker locker(&gDebugLogMutex);
    const QString redacted = CredentialVault::redactSecrets(message);
    std::cerr << redacted.toStdString() << std::endl;
    if (gDebugLogPath.isEmpty())
        return;

    const QByteArray line = redacted.toUtf8() + '\n';
    rotateDebugLogIfNeeded(line.size());

    QFile logFile(gDebugLogPath);
    if (logFile.open(QIODevice::WriteOnly | QIODevice::Append)) {
        const qint64 written = logFile.write(line);
        if (written > 0)
            gDebugLogBytes += written;
    }
}

struct Fonts {
    QString display = "Space Grotesk";
    QString body = "IBM Plex Sans";
    QString mono = "IBM Plex Mono";
};

Fonts loadBundledFonts() {
    Fonts fonts;
    const struct FontEntry {
        QString path;
        QString *targetFamily;
    } fontEntries[] = {{":/qt/qml/CassetteCat/fonts/space_grotesk_variable.ttf", &fonts.display},
                       {":/qt/qml/CassetteCat/fonts/ibm_plex_sans_variable.ttf", &fonts.body},
                       {":/qt/qml/CassetteCat/fonts/ibm_plex_mono_regular.ttf", &fonts.mono},
                       {":/qt/qml/CassetteCat/fonts/ibm_plex_mono_semibold.ttf", nullptr}};

    for (const auto &entry : fontEntries) {
        int id = QFontDatabase::addApplicationFont(entry.path);
        if (id >= 0) {
            const QStringList families = QFontDatabase::applicationFontFamilies(id);
            if (!families.isEmpty() && entry.targetFamily) {
                *entry.targetFamily = families.first();
            }
            qWarning().noquote() << "FONT_LOAD:" << entry.path << "id=" << id << "families=" << families;
        } else {
            qWarning().noquote() << "FONT_LOAD_FAIL:" << entry.path;
        }
    }
    return fonts;
}

/// Runs the self-check named by \p flag and returns its exit code, or nothing for any other argument.
std::optional<int> runSelfCheck(const char *flag) {
    if (std::strcmp(flag, "--single-instance-self-check") == 0) {
        return singleInstanceSelfCheck() ? 0 : 1;
    }

    if (std::strcmp(flag, "--library-self-check") == 0) {
        return (scanSelfCheck() && LibraryController::selfCheck()) ? 0 : 1;
    }

    if (std::strcmp(flag, "--services-self-check") == 0) {
        return ServicesController::selfCheck() ? 0 : 1;
    }

    if (std::strcmp(flag, "--player-self-check") == 0) {
        return PlayerController::selfCheck() ? 0 : 1;
    }

    if (std::strcmp(flag, "--streaming-self-check") == 0) {
        return streaming::runSelfChecks() ? 0 : 1;
    }

    if (std::strcmp(flag, "--vault-self-check") == 0) {
        return streaming::runSelfChecks(true) ? 0 : 1;
    }

    if (std::strcmp(flag, "--self-check") == 0) {
        bool passed = true;
        const auto check = [&passed](bool result, const char *name) {
            if (result)
                return;
            qCritical().noquote() << "Self-check failed:" << name;
            passed = false;
        };
        check(scanSelfCheck(), "library scan");
        check(SettingsController::selfCheck(), "settings");
        check(LibraryController::selfCheck(), "library controller");
        check(streaming::runSelfChecks(), "streaming");
        check(GlobalShortcutController::selfCheck(), "global shortcuts");
        check(ServicesController::selfCheck(), "services");
        check(PlayerController::selfCheck(), "player");
        check(MprisController::selfCheck(), "mpris");
        check(DiscordPresence::selfCheck(), "discord presence");
        check(RemoteControlServer::selfCheck(), "remote control");
        QSize labelSize;
        const QString bundledLabel = QStringLiteral("0.5/qrc:/qt/qml/CassetteCat/assets/cassettecat_icon.png");
        check(!CoverImageProvider().requestImage(bundledLabel, &labelSize, QSize(0, 0)).isNull(), "bundled cover");
        check(singleInstanceSelfCheck(), "single instance");
        return passed ? 0 : 1;
    }
    return std::nullopt;
}

QIcon bundledAppIcon() {
    QIcon icon;
    for (const int size : {16, 24, 32, 48, 64, 128, 256})
        icon.addFile(":/qt/qml/CassetteCat/assets/cassettecat_icon.png", QSize(size, size));
    return icon;
}
} // namespace

#ifdef Q_OS_WIN
static void setupWindowsFrameless(QQuickWindow *window) {
    if (!window)
        return;
    HWND hwnd = (HWND)window->winId();
    if (!hwnd)
        return;

    // Windows 10 before 20H1 only knows the older attribute number.
    BOOL darkMode = TRUE;
    DwmSetWindowAttribute(hwnd, 19 /* DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1 */, &darkMode, sizeof(darkMode));
    DwmSetWindowAttribute(hwnd, 20 /* DWMWA_USE_IMMERSIVE_DARK_MODE */, &darkMode, sizeof(darkMode));

    // A one-pixel client extension is required for DWM to composite a frameless window on Windows.
    MARGINS margins = {1, 1, 1, 1};
    DwmExtendFrameIntoClientArea(hwnd, &margins);

    // Matching the app background (#0E0D0C) keeps Windows 11 from drawing a light line around the window.
    COLORREF borderColor = RGB(14, 13, 12);
    DwmSetWindowAttribute(hwnd, 34 /* DWMWA_BORDER_COLOR */, &borderColor, sizeof(borderColor));

    // Frameless windows get square corners unless they ask; Windows 11 rounds them like other apps.
    const int roundCorners = 2 /* DWMWCP_ROUND */;
    DwmSetWindowAttribute(hwnd, 33 /* DWMWA_WINDOW_CORNER_PREFERENCE */, &roundCorners, sizeof(roundCorners));

    // Snap Layouts and Aero Snap only work on sizable windows with a caption. WindowFrame hides both.
    SetWindowLongPtr(hwnd, GWL_STYLE, GetWindowLongPtr(hwnd, GWL_STYLE) | WS_THICKFRAME | WS_CAPTION);
    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
}

static void registerWindowsAppIdentity() {
    const QString shortcutPath =
        QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation) + '/' + kApplicationName + ".lnk";
    IShellLinkW *shellLink = nullptr;
    if (FAILED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER, IID_IShellLinkW,
                                reinterpret_cast<void **>(&shellLink))))
        return;
    const std::wstring target = QCoreApplication::applicationFilePath().toStdWString();
    const std::wstring shortcut = shortcutPath.toStdWString();
    shellLink->SetPath(target.c_str());
    shellLink->SetDescription(L"CassetteCat music player");
    IPropertyStore *properties = nullptr;
    if (SUCCEEDED(shellLink->QueryInterface(IID_PPV_ARGS(&properties)))) {
        PROPVARIANT value;
        PropVariantInit(&value);
        if (SUCCEEDED(InitPropVariantFromString(kAppUserModelId, &value))) {
            properties->SetValue(PKEY_AppUserModel_ID, value);
            properties->Commit();
        }
        PropVariantClear(&value);
        properties->Release();
    }
    IPersistFile *persist = nullptr;
    if (SUCCEEDED(shellLink->QueryInterface(IID_PPV_ARGS(&persist)))) {
        persist->Save(shortcut.c_str(), TRUE);
        persist->Release();
    }
    shellLink->Release();
}

#endif

static void showMainWindow(QQuickWindow *window, bool startMinimized, SmtcController &smtc, const QIcon &icon) {
#ifdef Q_OS_WIN
    window->setIcon(icon);
    if (startMinimized) {
        window->create();
        setupWindowsFrameless(window);
        smtc.initialize(static_cast<quintptr>(window->winId()));
    } else {
        window->setVisible(true);
        setupWindowsFrameless(window);
        smtc.initialize(static_cast<quintptr>(window->winId()));
        activateWindow(window);
    }
#else
    if (startMinimized) {
        window->create();
    } else {
        window->setVisible(true);
    }
#ifdef Q_OS_MACOS
    smtc.initialize(0);
#endif
#endif
}

int main(int argc, char *argv[]) {
    qInstallMessageHandler(writeDebugLog);

    if (argc == 3 && std::strcmp(argv[1], "--scan-library") == 0) {
        const QVariantList tracks = scanTracks(QString::fromLocal8Bit(argv[2]));
        std::cout << QJsonDocument::fromVariant(tracks).toJson(QJsonDocument::Compact).constData();
        return 0;
    }

#ifdef Q_OS_WIN
    SetCurrentProcessExplicitAppUserModelID(kAppUserModelId);
#endif

    QSurfaceFormat surfaceFormat = QSurfaceFormat::defaultFormat();
    surfaceFormat.setSwapInterval(1);
    QSurfaceFormat::setDefaultFormat(surfaceFormat);

    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);
    QQuickStyle::setStyle("Basic");
    QCoreApplication::setOrganizationName("CassetteCat");
    QCoreApplication::setApplicationName(kApplicationName);
    QCoreApplication::setApplicationVersion(QStringLiteral(CASSETTECAT_VERSION));
    initializeDebugLog();
    // English is written in the code; other languages, and English plural forms, come from the translation files.
    QTranslator translator;
    if (translator.load(QLocale(), QStringLiteral("cassettecat"), QStringLiteral("_"), QStringLiteral(":/i18n")))
        QCoreApplication::installTranslator(&translator);
#ifdef Q_OS_WIN
    CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    registerWindowsAppIdentity();
#endif

    const Fonts fonts = loadBundledFonts();

    if (argc == 2) {
        if (const std::optional<int> result = runSelfCheck(argv[1]))
            return *result;
    }

    QString openPath;
    for (int i = 1; i < argc; ++i) {
        const QFileInfo candidate(QString::fromLocal8Bit(argv[i]));
        if (candidate.exists()) {
            openPath = candidate.absoluteFilePath();
            break;
        }
    }

    QLocalServer instanceServer;
#ifdef _WIN32
    SetLastError(0);
    const HANDLE instanceMutex = CreateMutexW(nullptr, FALSE, kInstanceMutexName);
    if (instanceMutex && GetLastError() == ERROR_ALREADY_EXISTS) {
        bool handedOff = false;
        constexpr int maxHandoffRetries = 5;
        for (int attempt = 0; attempt < maxHandoffRetries; ++attempt) {
            if (notifyRunningInstance(QString::fromLatin1(kInstanceServerName), openPath)) {
                handedOff = true;
                break;
            }
            if (attempt + 1 < maxHandoffRetries)
                QThread::msleep(100);
        }
        if (!handedOff) {
            qWarning() << "Existing instance detected, but handoff notification failed.";
            return 1;
        }
        return 0;
    }
#endif
    const InstanceStartResult instanceResult =
        startInstanceServer(instanceServer, QString::fromLatin1(kInstanceServerName), openPath);
    if (instanceResult == InstanceStartResult::HandedOff)
        return 0;
    if (instanceResult == InstanceStartResult::Unavailable)
        qWarning() << "Proceeding without single-instance handoff server.";

    QQuickWindow *mainWindow = nullptr;

    const QIcon appIcon = bundledAppIcon();
    app.setWindowIcon(appIcon);

    QFont defaultFont(fonts.display);
    defaultFont.setStyleHint(QFont::SansSerif);
    app.setFont(defaultFont);

    LibraryController library(&app);
    StreamingController streaming(settingsFilePath(), &app);
    PlayerController player(&app, &streaming);
    ServicesController services(&app);
    SettingsController appSettings(&app);
    QObject::connect(&app, &QCoreApplication::aboutToQuit, [&appSettings]() {
        qInfo() << "APP_ABOUT_TO_QUIT: app is exiting";
        appSettings.sync();
    });
    SmtcController smtc(&player, &app);
    MprisController mpris(&player, &app);
    DiscordPresence discord(&player, &app);
    RemoteControlServer phoneRemote(&player, &library, &app);
    GlobalShortcutController globalShortcuts(&app);
    TrayController tray(appIcon, &app);

    const auto openExternalPath = [&](const QString &path) {
        const QFileInfo file(path);
        if (!file.exists())
            return;
        if (file.isDir()) {
            library.loadFolder(QUrl::fromLocalFile(file.absoluteFilePath()));
            return;
        }
        const QString ext = file.suffix().toLower();
        if (ext == "m3u" || ext == "m3u8") {
            const QVariantList tracks = parseM3uPlaylist(file.absoluteFilePath());
            if (!tracks.isEmpty()) {
                player.requestPlayback(tracks, 0);
            }
            return;
        }
        TrackInfo info = readTrackInfo(file.absoluteFilePath());
        if (info.album.isEmpty()) {
            info.album = QStringLiteral("External file");
        }
        player.requestPlayback({info.toMap()}, 0);
    };

    QObject::connect(&mpris, &MprisController::openUriRequested, [&](const QString &uri) {
        const QUrl url(uri);
        if (!url.isLocalFile())
            return;
        const QString path = url.toLocalFile();
        const QFileInfo file(path);
        if (file.exists() && file.isFile()) {
            openExternalPath(path);
        }
    });
    QObject::connect(&mpris, &MprisController::raiseRequested, [&]() { activateWindow(mainWindow); });
    mpris.initialize();

    const auto handleInstanceSocket = [&](QLocalSocket *socket) {
        const auto processRequest = [&, socket] {
            const QJsonDocument request = QJsonDocument::fromJson(socket->readAll());
            const QString path = request.object().value("path").toString();
            qInfo() << "Instance handoff received:" << path;
            if (!path.isEmpty())
                openExternalPath(path);
            activateWindow(mainWindow);
            socket->disconnectFromServer();
        };
        QObject::connect(socket, &QLocalSocket::readyRead, &app, processRequest);
        QObject::connect(socket, &QLocalSocket::disconnected, socket, &QObject::deleteLater);
        if (socket->bytesAvailable())
            processRequest();
    };

    const auto processInstanceConnections = [&] {
        while (QLocalSocket *socket = instanceServer.nextPendingConnection())
            handleInstanceSocket(socket);
    };
    QObject::connect(&instanceServer, &QLocalServer::newConnection, &app, processInstanceConnections);
    processInstanceConnections();
    // Declared before the engine so it outlives the QML that binds to it while the app quits.
    WindowFrame windowFrame;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("displayFontFamily", fonts.display);
    engine.rootContext()->setContextProperty("bodyFontFamily", fonts.body);
    engine.rootContext()->setContextProperty("monoFontFamily", fonts.mono);
    engine.rootContext()->setContextProperty("library", &library);
    engine.rootContext()->setContextProperty("streaming", &streaming);
    engine.rootContext()->setContextProperty("player", &player);
    engine.rootContext()->setContextProperty("services", &services);
    engine.rootContext()->setContextProperty("appSettings", &appSettings);
    engine.rootContext()->setContextProperty("installedFromStore", installedFromStore());
    engine.rootContext()->setContextProperty("smtc", &smtc);
    engine.rootContext()->setContextProperty("windowFrame", &windowFrame);
    engine.rootContext()->setContextProperty("mpris", &mpris);
    engine.rootContext()->setContextProperty("discord", &discord);
    engine.rootContext()->setContextProperty("phoneRemote", &phoneRemote);
    engine.rootContext()->setContextProperty("globalShortcuts", &globalShortcuts);
    engine.rootContext()->setContextProperty("tray", &tray);
    engine.addImageProvider("cover", new CoverImageProvider);

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        [](const QUrl &url) {
            qWarning() << "Failed to create QML root object from URL:" << url;
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, [](const QList<QQmlError> &warnings) {
        for (const auto &w : warnings) {
            qWarning() << "QML warning:" << w.toString();
        }
    });

    engine.loadFromModule("CassetteCat", "Main");
    // After the first pass this only reads image headers, so it runs on every launch rather than tracking a flag.
    QThreadPool::globalInstance()->start(shrinkOversizedCachedImages);
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "FATAL: engine.rootObjects() is empty after loading Main module!";
#ifdef Q_OS_WIN
        MessageBoxA(NULL, "FATAL: QML root object creation failed. Check the CassetteCat log for details.",
                    "CassetteCat Error", MB_OK | MB_ICONERROR);
#endif
        return 1;
    }

    for (auto *rootObj : engine.rootObjects()) {
        if (auto *quickWin = qobject_cast<QQuickWindow *>(rootObj)) {
            quickWin->setPersistentGraphics(false);
            quickWin->setPersistentSceneGraph(false);
            mainWindow = quickWin;
            showMainWindow(quickWin,
                           appSettings.value(QStringLiteral("ui/startMinimizedToTray"), false).toBool() &&
                               tray.available(),
                           smtc, appIcon);
            break;
        }
    }

    if (!openPath.isEmpty())
        openExternalPath(openPath);

    const int result = app.exec();
    qInfo() << "APP_EXEC_RETURNED:" << result;
#ifdef _WIN32
    CloseHandle(instanceMutex);
#endif
    return result;
}
