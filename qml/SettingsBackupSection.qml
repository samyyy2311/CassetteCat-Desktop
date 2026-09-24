import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string backupStatus: ""
    property bool logsVisible: false
    property string recentLogs: ""

    signal exportBackupRequested()
    signal importBackupRequested()

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "Settings & Library Backup" }

    SettingCard {
        SettingRow {
            iconName: "refresh-cw"
            title: "Configuration Backup"
            subtitle: root.backupStatus.length > 0
                      ? root.backupStatus
                      : "Export settings, favorites, saved queues, and filters as a JSON file"

            SettingButton {
                text: "Export"
                iconName: "refresh-cw"
                primary: true
                onClicked: root.exportBackupRequested()
            }

            SettingButton {
                text: "Import"
                iconName: "arrow-down"
                onClicked: root.importBackupRequested()
            }
        }

        Rectangle {
            visible: root.backupStatus.length > 0
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 8
            height: 36
            radius: 8
            color: (root.backupStatus.toLowerCase().includes("error") || root.backupStatus.toLowerCase().includes("fail"))
                   ? "#33FF4444" : "#2510B981"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                LucideIcon {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    icon: (root.backupStatus.toLowerCase().includes("error") || root.backupStatus.toLowerCase().includes("fail"))
                          ? "shield" : "refresh-cw"
                    color: (root.backupStatus.toLowerCase().includes("error") || root.backupStatus.toLowerCase().includes("fail"))
                           ? "#FF6677" : "#34D399"
                }

                Label {
                    Layout.fillWidth: true
                    text: root.backupStatus
                    color: (root.backupStatus.toLowerCase().includes("error") || root.backupStatus.toLowerCase().includes("fail"))
                           ? "#FF8899" : "#6EE7B7"
                    font.family: displayFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }

        SettingDivider {}

        Label {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.bottomMargin: 4
            wrapMode: Text.WordWrap
            text: "Importing a backup applies its saved settings and library state immediately. Passwords, secrets, and server authentication tokens are never exported."
            color: silverDim
            font.family: bodyFont
            font.pixelSize: 11
            lineHeight: 1.3
        }
    }

    SectionLabel { text: "Diagnostics & Logs" }

    SettingCard {
        SettingRow {
            iconName: "archive"
            title: "Application Logs"
            subtitle: appSettings.getLogFilePath()

            SettingButton {
                text: root.logsVisible ? "Hide Logs" : "Logs"
                iconName: "list"
                onClicked: {
                    root.logsVisible = !root.logsVisible
                    if (root.logsVisible) {
                        root.recentLogs = appSettings.readRecentLogs(150)
                    }
                }
            }

            SettingButton {
                text: "Open"
                iconName: "external-link"
                onClicked: appSettings.openLogFile()
            }

            SettingButton {
                text: "Copy"
                onClicked: appSettings.copyToClipboard(appSettings.readRecentLogs(200))
            }

            SettingButton {
                text: "Clear"
                iconName: "x"
                destructive: true
                onClicked: {
                    appSettings.clearLogs()
                    root.recentLogs = appSettings.readRecentLogs(150)
                }
            }
        }

        Rectangle {
            visible: root.logsVisible
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            radius: 8
            color: (typeof surfaceInput !== "undefined" ? surfaceInput : "#141312")
            border.width: 0
            clip: true

            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                contentWidth: logText.contentWidth
                contentHeight: logText.contentHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: AutoHideScrollBar {}

                TextEdit {
                    id: logText
                    readOnly: true
                    selectByMouse: true
                    text: root.recentLogs
                    color: (typeof textPrimary !== "undefined" ? textPrimary : "#F5F0EC")
                    font.family: (typeof monoFont !== "undefined") ? monoFont : "IBM Plex Mono"
                    font.pixelSize: 11
                }
            }
        }
    }
}
