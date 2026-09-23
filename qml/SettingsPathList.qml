import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var paths: []
    signal removeRequested(string path)

    readonly property color accentHoverColor: (typeof recordRedHover !== "undefined" ? recordRedHover : "#FF5C4D")

    Layout.fillWidth: true
    spacing: 0

    Repeater {
        model: root.paths

        delegate: Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            radius: 8
            color: (typeof surfaceInput !== "undefined" ? surfaceInput : "#1A1917")
            border.width: 1
            border.color: (typeof borderSubtle !== "undefined" ? borderSubtle : "#22201D")

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 6
                spacing: 10

                LucideIcon {
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    icon: "folder"
                    color: root.accentHoverColor
                }

                Label {
                    Layout.fillWidth: true
                    text: modelData
                    color: textSecondary
                    font.family: monoFont
                    font.pixelSize: 11
                    elide: Text.ElideMiddle
                }

                SettingButton {
                    text: "Remove"
                    destructive: true
                    onClicked: root.removeRequested(modelData)
                }
            }
        }
    }
}
