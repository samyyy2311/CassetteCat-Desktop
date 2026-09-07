import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string backupStatus: ""

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
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            spacing: 12

            SettingButton {
                text: "Export Backup"
                iconName: "refresh-cw"
                primary: true
                onClicked: root.exportBackupRequested()
            }

            SettingButton {
                text: "Import Backup"
                iconName: "folder"
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
            border.width: 1
            border.color: (root.backupStatus.toLowerCase().includes("error") || root.backupStatus.toLowerCase().includes("fail"))
                   ? "#80FF4444" : "#8010B981"

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
            text: "Importing a backup restores application settings and library state after asking for confirmation. Passwords, secrets, and server authentication tokens are never exported."
            color: silverDim
            font.family: bodyFont
            font.pixelSize: 11
            lineHeight: 1.3
        }
    }
}
