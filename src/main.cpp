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
#include <QSize>
#include <QStandardPaths>
#include <QStringList>
#include <QTextStream>
#include <QUrl>
#include <QVariantList>
#include <cstring>
#include <iostream>
#include <string>

#include <QFontDatabase>

#include "smtc_controller.h"
#include "global_shortcut_controller.h"
#include "tray_controller.h"

#include "app_paths.h"
#include "app_settings.h"
#include "credential_vault.h"
#include "library_controller.h"
#include "library_scanner.h"
#include "player_controller.h"
#include "services_controller.h"
#include "streaming.h"

namespace {

constexpr auto kInstanceServerName = "CassetteCat.Desktop.Instance";
#ifdef _WIN32
constexpr auto kInstanceMutexName = L"CassetteCat.AudioEngine.Desktop.InstanceMutex";
#endif

bool notifyRunningInstance(const QString &serverName, const QString &openPath = {})
{
    QLocalSocket socket;
    socket.connectToServer(serverName);
    if (!socket.waitForConnected(200)) {
        qWarning() << "Instance handoff connection failed:" << socket.errorString();
        return false;
    }
    QJsonObject request{{"action", "activate"}};
    if (!openPath.isEmpty()) request.insert("path", openPath);
    socket.write(QJsonDocument(request).toJson(QJsonDocument::Compact));
    const bool written = socket.waitForBytesWritten(200);
    if (!written) qWarning() << "Instance handoff write failed:" << socket.errorString();
    return written;
}

bool startInstanceServer(QLocalServer &server, const QString &serverName, const QString &openPath = {})
{
    server.setSocketOptions(QLocalServer::UserAccessOption);
    if (server.listen(serverName)) return true;
    if (notifyRunningInstance(serverName, openPath)) return false;

    QLocalServer::removeServer(serverName);
    if (server.listen(serverName)) return true;

    qWarning() << "Single-instance server unavailable:" << server.errorString();
    return false;
}

bool singleInstanceSelfCheck()
{
    const QString name = QString::fromLatin1(kInstanceServerName)
        + ".self-check." + QString::number(QCoreApplication::applicationPid());
    QLocalServer::removeServer(name);
    QLocalServer primary;
    QLocalServer duplicate;
    const bool primaryStarted = startInstanceServer(primary, name);
    const bool duplicateBlocked = !startInstanceServer(duplicate, name);
    primary.close();
    QLocalServer::removeServer(name);
    return primaryStarted && duplicateBlocked;
}

void activateWindow(QQuickWindow *window)
{
    if (!window) return;
    if (window->visibility() == QWindow::Minimized) window->showNormal();
    window->raise();
    window->requestActivate();
}

void writeDebugLog(QtMsgType, const QMessageLogContext &, const QString &message)
{
    static QMutex logMutex;
    QMutexLocker locker(&logMutex);
    const QString redacted = CredentialVault::redactSecrets(message);
    std::cerr << redacted.toStdString() << std::endl;
    QFile logFile("debug.log");
    if (logFile.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream(&logFile) << redacted << '\n';
    }
}

}

#ifdef Q_OS_WIN
#include <windows.h>
#include <dwmapi.h>
#include <shobjidl.h>
#include <propkey.h>
#include <propvarutil.h>

static void setupWindowsFrameless(QQuickWindow *window) {
    if (!window) return;
    HWND hwnd = (HWND)window->winId();
    if (!hwnd) return;

    // A one-pixel client extension keeps DWM shadowing on a frameless window.
    MARGINS margins = { 1, 1, 1, 1 };
    DwmExtendFrameIntoClientArea(hwnd, &margins);
}

static void registerWindowsAppIdentity()
{
    const QString shortcutPath = QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation)
        + "/CassetteCat.lnk";
    IShellLinkW *shellLink = nullptr;
    if (FAILED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                                IID_IShellLinkW, reinterpret_cast<void **>(&shellLink)))) return;
    const std::wstring target = QCoreApplication::applicationFilePath().toStdWString();
    const std::wstring shortcut = shortcutPath.toStdWString();
    shellLink->SetPath(target.c_str());
    shellLink->SetDescription(L"CassetteCat music player");
    IPropertyStore *properties = nullptr;
    if (SUCCEEDED(shellLink->QueryInterface(IID_PPV_ARGS(&properties)))) {
        PROPVARIANT value;
        PropVariantInit(&value);
        if (SUCCEEDED(InitPropVariantFromString(L"CassetteCat.AudioEngine.Desktop.App", &value))) {
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

int main(int argc, char *argv[])
{
    qInstallMessageHandler(writeDebugLog);

    if (argc == 3 && std::strcmp(argv[1], "--scan-library") == 0) {
        const QVariantList tracks = scanTracks(QString::fromLocal8Bit(argv[2]));
        std::cout << QJsonDocument::fromVariant(tracks).toJson(QJsonDocument::Compact).constData();
        return 0;
    }

#ifdef Q_OS_WIN
    SetCurrentProcessExplicitAppUserModelID(L"CassetteCat.AudioEngine.Desktop.App");
#endif

    QApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");
    QCoreApplication::setOrganizationName("CassetteCat");
    QCoreApplication::setApplicationName("CassetteCat");
#ifdef Q_OS_WIN
    CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    registerWindowsAppIdentity();
#endif

    if (argc == 2 && std::strcmp(argv[1], "--single-instance-self-check") == 0) {
        return singleInstanceSelfCheck() ? 0 : 1;
    }

    QString displayFontFamily = "Space Grotesk";
    QString bodyFontFamily = "IBM Plex Sans";
    QString monoFontFamily = "IBM Plex Mono";

    const struct FontEntry {
        QString path;
        QString *targetFamily;
    } fontEntries[] = {
        {":/qt/qml/CassetteCat/fonts/space_grotesk_variable.ttf", &displayFontFamily},
        {":/qt/qml/CassetteCat/fonts/ibm_plex_sans_variable.ttf", &bodyFontFamily},
        {":/qt/qml/CassetteCat/fonts/ibm_plex_mono_regular.ttf", &monoFontFamily},
        {":/qt/qml/CassetteCat/fonts/ibm_plex_mono_semibold.ttf", nullptr}
    };

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

    if (argc == 2 && std::strcmp(argv[1], "--library-self-check") == 0) {
        return (scanSelfCheck() && LibraryController::selfCheck()) ? 0 : 1;
    }

    if (argc == 2 && std::strcmp(argv[1], "--services-self-check") == 0) {
        return ServicesController::selfCheck() ? 0 : 1;
    }

    if (argc == 2 && std::strcmp(argv[1], "--player-self-check") == 0) {
        return PlayerController::selfCheck() ? 0 : 1;
    }

    if (argc == 2 && std::strcmp(argv[1], "--streaming-self-check") == 0) {
        return streaming::runSelfChecks() ? 0 : 1;
    }

    if (argc == 2 && std::strcmp(argv[1], "--vault-self-check") == 0) {
        return streaming::runSelfChecks(true) ? 0 : 1;
    }

    if (argc == 2 && std::strcmp(argv[1], "--self-check") == 0) {
        return (scanSelfCheck() && LibraryController::selfCheck() && streaming::runSelfChecks()
                && GlobalShortcutController::selfCheck() && ServicesController::selfCheck()
                && PlayerController::selfCheck() && singleInstanceSelfCheck()) ? 0 : 1;
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
    const HANDLE instanceMutex = CreateMutexW(nullptr, FALSE, kInstanceMutexName);
    if (!instanceMutex || GetLastError() == ERROR_ALREADY_EXISTS) {
        notifyRunningInstance(QString::fromLatin1(kInstanceServerName), openPath);
        return 0;
    }
#endif
    if (!startInstanceServer(instanceServer, QString::fromLatin1(kInstanceServerName), openPath)) return 0;

    QQuickWindow *mainWindow = nullptr;

    QIcon appIcon;
    appIcon.addFile(":/qt/qml/CassetteCat/assets/cassettecat_icon.png", QSize(16, 16));
    appIcon.addFile(":/qt/qml/CassetteCat/assets/cassettecat_icon.png", QSize(24, 24));
    appIcon.addFile(":/qt/qml/CassetteCat/assets/cassettecat_icon.png", QSize(32, 32));
    appIcon.addFile(":/qt/qml/CassetteCat/assets/cassettecat_icon.png", QSize(48, 48));
    appIcon.addFile(":/qt/qml/CassetteCat/assets/cassettecat_icon.png", QSize(64, 64));
    appIcon.addFile(":/qt/qml/CassetteCat/assets/cassettecat_icon.png", QSize(128, 128));
    appIcon.addFile(":/qt/qml/CassetteCat/assets/cassettecat_icon.png", QSize(256, 256));
    app.setWindowIcon(appIcon);

    QFont defaultFont(displayFontFamily);
    defaultFont.setStyleHint(QFont::SansSerif);
    app.setFont(defaultFont);

    LibraryController library(&app);
    StreamingController streaming(settingsFilePath(), &app);
    PlayerController player(&app, &streaming);
    ServicesController services(&app);
    SettingsController appSettings(&app);
    SmtcController smtc(&player, &app);
    GlobalShortcutController globalShortcuts(&app);
    TrayController tray(appIcon, &app);
    if (tray.available()) app.setQuitOnLastWindowClosed(false);

    const auto openExternalPath = [&](const QString &path) {
        const QFileInfo file(path);
        if (!file.exists()) return;
        if (file.isDir()) {
            library.loadFolder(QUrl::fromLocalFile(file.absoluteFilePath()));
            return;
        }
        QVariantMap track;
        track.insert("filePath", file.absoluteFilePath());
        track.insert("fileName", file.fileName());
        track.insert("title", file.completeBaseName());
        track.insert("artist", "Unknown Artist");
        track.insert("album", "External file");
        track.insert("format", file.suffix().toUpper());
        player.playTrack(track);
    };

    const auto handleInstanceSocket = [&](QLocalSocket *socket) {
        const auto processRequest = [&, socket] {
            const QJsonDocument request = QJsonDocument::fromJson(socket->readAll());
            const QString path = request.object().value("path").toString();
            qInfo() << "Instance handoff received:" << path;
            if (!path.isEmpty()) openExternalPath(path);
            activateWindow(mainWindow);
            socket->disconnectFromServer();
        };
        QObject::connect(socket, &QLocalSocket::readyRead, &app, processRequest);
        QObject::connect(socket, &QLocalSocket::disconnected, socket, &QObject::deleteLater);
        if (socket->bytesAvailable()) processRequest();
    };

    const auto processInstanceConnections = [&] {
        while (QLocalSocket *socket = instanceServer.nextPendingConnection()) handleInstanceSocket(socket);
    };
    QObject::connect(&instanceServer, &QLocalServer::newConnection, &app, processInstanceConnections);
    processInstanceConnections();
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("displayFontFamily", displayFontFamily);
    engine.rootContext()->setContextProperty("bodyFontFamily", bodyFontFamily);
    engine.rootContext()->setContextProperty("monoFontFamily", monoFontFamily);
    engine.rootContext()->setContextProperty("library", &library);
    engine.rootContext()->setContextProperty("streaming", &streaming);
    engine.rootContext()->setContextProperty("player", &player);
    engine.rootContext()->setContextProperty("services", &services);
    engine.rootContext()->setContextProperty("appSettings", &appSettings);
    engine.rootContext()->setContextProperty("smtc", &smtc);
    engine.rootContext()->setContextProperty("globalShortcuts", &globalShortcuts);
    engine.rootContext()->setContextProperty("tray", &tray);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [](const QUrl &url) {
            qWarning() << "Failed to create QML root object from URL:" << url;
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::warnings,
        [](const QList<QQmlError> &warnings) {
            for (const auto &w : warnings) {
                qWarning() << "QML warning:" << w.toString();
            }
        }
    );

    engine.loadFromModule("CassetteCat", "Main");

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "FATAL: engine.rootObjects() is empty after loading Main module!";
#ifdef Q_OS_WIN
        MessageBoxA(NULL, "FATAL: QML root object creation failed. Check debug.log for details.", "CassetteCat Error", MB_OK | MB_ICONERROR);
#endif
        return 1;
    }

    for (auto *rootObj : engine.rootObjects()) {
        if (auto *quickWin = qobject_cast<QQuickWindow *>(rootObj)) {
            quickWin->setPersistentGraphics(false);
            quickWin->setPersistentSceneGraph(false);
#ifdef Q_OS_WIN
            mainWindow = quickWin;
            quickWin->setIcon(appIcon);
            quickWin->show();
            setupWindowsFrameless(quickWin);
            smtc.initialize(static_cast<quintptr>(quickWin->winId()));
            activateWindow(quickWin);
#endif
            break;
        }
    }

    if (!openPath.isEmpty()) openExternalPath(openPath);

    const int result = app.exec();
#ifdef _WIN32
    CloseHandle(instanceMutex);
#endif
    return result;
}
