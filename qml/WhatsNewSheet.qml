import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AppDialog {
    id: root

    readonly property var notes: services.releaseNotes(Qt.application.version)

    maxWidth: 560

    contentItem: ColumnLayout {
        spacing: 16

        DialogHeader {
            imageSource: "qrc:/qt/qml/CassetteCat/assets/cassettecat_icon.png"
            title: qsTr("What's New")
            subtitle: "CassetteCat " + Qt.application.version

            TransportButton {
                Layout.alignment: Qt.AlignTop
                Accessible.name: qsTr("Close")
                buttonSize: 32
                iconName: "x"
                tooltipText: qsTr("Close")
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

                // Each part of the release, such as Lyrics or Fixes, under the small capitals used above page titles.
                Repeater {
                    model: root.notes

                    ColumnLayout {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.topMargin: index > 0 ? 8 : 0
                        spacing: 10

                        OverlineLabel {
                            visible: text.length > 0
                            text: modelData.title
                        }

                        Repeater {
                            model: modelData.notes

                            RowLayout {
                                required property string modelData

                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 8
                                    width: 4
                                    height: 4
                                    radius: 2
                                    color: accentText
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
    }
}
