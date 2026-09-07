#include <QJsonDocument>
#include <QLocalServer>
#include <QLocalSocket>
#include <QDebug>
#include <QCoreApplication>
#include <QFile>
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
#include <QStringList>
#include <QTextStream>
#include <QUrl>
#include <QVariantList>
#include <cstring>
#include <iostream>

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

bool notifyRunningInstance(const QString &serverName)
{
    QLocalSocket socket;
    socket.connectToServer(serverName);
    if (!socket.waitForConnected(200)) return false;
    socket.write("activate");
    socket.waitForBytesWritten(200);
    return true;
}

bool startInstanceServer(QLocalServer &server, const QString &serverName)
{
    server.setSocketOptions(QLocalServer::UserAccessOption);
    if (server.listen(serverName)) return true;
    if (notifyRunningInstance(serverName)) return false;

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

static void setupWindowsFrameless(QQuickWindow *window) {
    if (!window) return;
    HWND hwnd = (HWND)window->winId();
    if (!hwnd) return;

    // A one-pixel client extension keeps DWM shadowing on a frameless window.
    MARGINS margins = { 1, 1, 1, 1 };
    DwmExtendFrameIntoClientArea(hwnd, &margins);
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

    QLocalServer instanceServer;
    if (!startInstanceServer(instanceServer, QString::fromLatin1(kInstanceServerName))) return 0;

    QQuickWindow *mainWindow = nullptr;
    QObject::connect(&instanceServer, &QLocalServer::newConnection, &app, [&] {
        while (QLocalSocket *socket = instanceServer.nextPendingConnection()) {
            socket->readAll();
            socket->deleteLater();
            activateWindow(mainWindow);
        }
    });

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
            smtc.initialize(reinterpret_cast<quintptr>(quickWin->winId()));
            activateWindow(quickWin);
#endif
            break;
        }
    }

    return app.exec();
}
