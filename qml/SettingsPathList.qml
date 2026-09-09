import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var paths: []
    signal removeRequested(string path)

    Layout.fillWidth: true
    spacing: 0

    Repeater {
        model: root.paths

        delegate: RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: modelData
                color: textSecondary
                font.family: monoFont
                font.pixelSize: 10
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
