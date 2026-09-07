import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property string catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
    property string title: "No tracks found"
    property string subtitle: "Try adjusting your filters or search"
    property string actionLabel: ""
    signal actionClicked()

    implicitWidth: 360
    implicitHeight: contentCol.implicitHeight

    ColumnLayout {
        id: contentCol
        width: implicitWidth
        height: implicitHeight
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        spacing: 12

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 110
            Layout.preferredHeight: 110

            Image {
                id: catImg
                anchors.fill: parent
                source: root.catImage
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: root.visible
                    NumberAnimation { to: -6; duration: 1400; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0; duration: 1400; easing.type: Easing.InOutQuad }
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: root.title
            color: textPrimary
            font.family: displayFont
            font.pixelSize: 16
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: textSecondary
            font.family: bodyFont
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Rectangle {
            visible: root.actionLabel.length > 0
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            Layout.preferredHeight: 34
            Layout.preferredWidth: btnLbl.implicitWidth + 28
            radius: 17
            color: btnMouse.containsMouse ? "#20FF3344" : "transparent"
            border.width: 1.5
            border.color: recordRed

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Label {
                id: btnLbl
                anchors.centerIn: parent
                text: root.actionLabel
                color: recordRedHover
                font.family: displayFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: btnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.actionClicked()
            }
        }
    }
}
