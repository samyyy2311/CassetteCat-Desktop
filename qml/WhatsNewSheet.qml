import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AppDialog {
    id: root

    readonly property var notes: services.releaseNotes(Qt.application.version)

    maxWidth: 560

    contentItem: ColumnLayout {
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Image {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                source: "qrc:/qt/qml/CassetteCat/assets/cassettecat_icon.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: "What's New"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    text: "CassetteCat " + Qt.application.version
                    color: textSecondary
                    font.family: bodyFont
                    font.pixelSize: 12
                }
            }

            TransportButton {
                Layout.alignment: Qt.AlignTop
                Accessible.name: "Close"
                buttonSize: 32
                iconName: "x"
                tooltipText: "Close"
                onClicked: root.close()
            }
        }

        AppFlickable {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(notesColumn.implicitHeight, (root.parent ? root.parent.height : 700) - 200)
            contentWidth: width
            contentHeight: notesColumn.implicitHeight
            clip: true
            ScrollBar.vertical: AutoHideScrollBar {}

            ColumnLayout {
                id: notesColumn
                width: parent.width
                spacing: 10

                Repeater {
                    model: root.notes

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 8
                            width: 4
                            height: 4
                            radius: 2
                            color: textSecondary
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData
                            color: textSecondary
                            font.family: bodyFont
                            font.pixelSize: 13
                            lineHeight: 1.3
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
