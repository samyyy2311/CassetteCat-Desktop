import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AppDialog {
    id: root

    required property var appWindow
    property int step: 0
    readonly property var steps: [
        { icon: "", title: "Welcome to CassetteCat" },
        { icon: "folder", title: "Choose your music" },
        { icon: "pencil", title: "Make it yours" }
    ]

    signal addFolderRequested()
    signal themeImportRequested()
    signal themeExportRequested()
    signal finished()

    maxWidth: 560
    closePolicy: Popup.CloseOnEscape
    onClosed: root.finished()

    component Body: Label {
        Layout.fillWidth: true
        color: textSecondary
        font.family: bodyFont
        font.pixelSize: 13
        lineHeight: 1.3
        wrapMode: Text.WordWrap
    }

    contentItem: ColumnLayout {
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Image {
                visible: root.step === 0
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                source: "qrc:/qt/qml/CassetteCat/assets/cassettecat_icon.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            Rectangle {
                visible: root.step > 0
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: "transparent"
                border.width: 1
                border.color: recordRed

                LucideIcon {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    icon: root.steps[root.step].icon
                    color: recordRed
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: root.steps[root.step].title
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Label {
                    text: "Step " + (root.step + 1) + " of " + root.steps.length
                    color: textSecondary
                    font.family: bodyFont
                    font.pixelSize: 12
                }
            }
        }

        Body {
            visible: root.step === 0
            text: "A player for the music you own. It plays files from folders on this computer, works without an "
                  + "internet connection, and pairs with the CassetteCat Android app over your Wi-Fi."
        }

        Body {
            visible: root.step === 1
            text: "CassetteCat builds your library from the folders you choose, and picks up new files as you add them. "
                  + "You can change these later in Settings > Library."
        }

        SettingCard {
            visible: root.step === 1

            SettingRow {
                iconName: "folder"
                title: "Music Folders"
                subtitle: library.folders.length > 0
                          ? (library.folders.length + " folder(s) • " + library.trackCount + " songs")
                          : "No folders yet"

                SettingButton {
                    text: "Add folder"
                    onClicked: root.addFolderRequested()
                }
            }

            // Scrolls past four folders so the step's buttons stay in the window.
            AppFlickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(folderList.implicitHeight, 184)
                contentWidth: width
                contentHeight: folderList.implicitHeight
                clip: true
                ScrollBar.vertical: AutoHideScrollBar {}

                SettingsPathList {
                    id: folderList
                    width: parent.width
                    paths: library.folders
                    onRemoveRequested: path => library.removeFolder(path)
                }
            }
        }

        AppFlickable {
            visible: root.step === 2
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(appearance.implicitHeight,
                                             (root.parent ? root.parent.height : 700) - 260)
            contentWidth: width
            contentHeight: appearance.implicitHeight
            clip: true
            ScrollBar.vertical: AutoHideScrollBar {}

            SettingsAppearanceSection {
                id: appearance
                width: parent.width
                accentName: root.appWindow.accentName
                customAccentColor: root.appWindow.customAccentColor
                theme: root.appWindow.theme
                themeStatus: root.appWindow.themeStatus
                albumArtRadius: root.appWindow.albumArtRadius
                nowPlayingBackdrop: root.appWindow.nowPlayingBackdrop
                showRemainingTime: root.appWindow.showRemainingTime
                onAccentSelected: value => root.appWindow.accentName = value
                onThemeSelected: value => root.appWindow.theme = value
                onThemeImportRequested: root.themeImportRequested()
                onThemeExportRequested: root.themeExportRequested()
                onCustomAccentSelected: hex => {
                    root.appWindow.customAccentColor = hex
                    root.appWindow.accentName = "custom"
                }
                onAlbumArtRadiusSelected: value => root.appWindow.albumArtRadius = value
                onNowPlayingBackdropSelected: value => root.appWindow.nowPlayingBackdrop = value
                onShowRemainingTimeSelected: value => root.appWindow.showRemainingTime = value
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 10

            SettingButton {
                text: root.step === 0 ? "Skip setup" : "Back"
                onClicked: root.step === 0 ? root.close() : root.step--
            }

            Item { Layout.fillWidth: true }

            SettingButton {
                text: root.step === 0 ? "Get started"
                    : root.step === root.steps.length - 1 ? "Start listening"
                    : library.folders.length > 0 ? "Continue" : "Skip for now"
                primary: true
                onClicked: root.step === root.steps.length - 1 ? root.close() : root.step++
            }
        }
    }
}
