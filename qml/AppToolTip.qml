import QtQuick
import QtQuick.Controls

ToolTip {
    id: root
    property var visibleTarget: undefined
    property bool below: false
    property Item targetItem: null

    readonly property bool isTargetHovered: {
        if (visibleTarget !== undefined) return Boolean(visibleTarget)
        if (targetItem && typeof targetItem.containsMouse !== "undefined") return targetItem.containsMouse
        if (parent && typeof parent.containsMouse !== "undefined") return parent.containsMouse
        return false
    }

    visible: isTargetHovered && text.length > 0
    delay: 350
    timeout: 5000

    padding: 6
    topPadding: 5
    bottomPadding: 5
    leftPadding: 10
    rightPadding: 10

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    Component.onCompleted: {
        if (targetItem) root.parent = targetItem
    }
    onTargetItemChanged: {
        if (targetItem) root.parent = targetItem
    }

    function updateCoordinates() {
        const p = root.parent
        if (!p) return
        try {
            const globalPos = p.mapToItem(null, 0, 0)
            const win = p ? p.Window.window : null
            const winWidth = win ? win.width : 1280
            const placeBelow = root.below || (globalPos && globalPos.y < 55)
            
            root.y = placeBelow ? (p.height + 6) : (-root.implicitHeight - 6)
            
            let targetX = (p.width - root.implicitWidth) / 2
            if (globalPos) {
                const screenX = globalPos.x + targetX
                if (screenX < 12) {
                    targetX += (12 - screenX)
                } else if (screenX + root.implicitWidth > winWidth - 12) {
                    targetX -= (screenX + root.implicitWidth - (winWidth - 12))
                }
            }
            root.x = targetX
        } catch (e) {
            root.x = (p.width - root.implicitWidth) / 2
            root.y = p.height + 6
        }
    }

    onAboutToShow: updateCoordinates()

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 120; easing.type: Easing.OutQuad }
        NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 120; easing.type: Easing.OutQuad }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0.0; duration: 80; easing.type: Easing.InQuad }
    }

    background: Rectangle {
        radius: 8
        color: "#22201D"
        border.width: 1
        border.color: "#45FFFFFF"
    }

    contentItem: Text {
        text: root.text
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        font.family: (typeof displayFont !== "undefined" && displayFont.length > 0) ? displayFont : "Space Grotesk"
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: "#FFFFFF"
    }
}

