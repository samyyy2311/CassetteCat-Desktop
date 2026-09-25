import QtQuick
import QtQuick.Controls
import QtTest
import "../qml"

TestCase {
    id: test
    name: "SettingChoiceGroup"
    when: windowShown

    Component {
        id: windowComponent

        ApplicationWindow {
            property alias group: choiceGroup
            property color textPrimary: "#F5F0EC"
            property color textSecondary: "#8E8A84"

            width: 800
            height: 600
            visible: true

            SettingChoiceGroup {
                id: choiceGroup
                x: 100
                y: 200
                width: 600
                forceMenu: true
                title: "Device"
                options: [{ value: "a", label: "Speakers" }, { value: "b", label: "Headphones" }]
                selectedValue: "a"
            }
        }
    }

    function findMenuButton(item) {
        for (let i = 0; i < item.children.length; ++i) {
            const child = item.children[i]
            if (child.iconRight === true && child.visible)
                return child
            const found = findMenuButton(child)
            if (found)
                return found
        }
        return null
    }

    function findPopup(item) {
        for (let i = 0; i < item.data.length; ++i) {
            const child = item.data[i]
            if (child.closePolicy !== undefined)
                return child
            const found = child.data ? findPopup(child) : null
            if (found)
                return found
        }
        return null
    }

    function test_menuButtonTogglesPopup() {
        const window = createTemporaryObject(windowComponent, test)
        // Without a real display the window is laid out after creation, and placement depends on its size.
        tryVerify(() => window.group.Overlay.overlay.height > 0)
        const button = findMenuButton(window.group)
        const popup = findPopup(window.group)
        verify(button)
        verify(popup)

        mouseClick(button)
        tryCompare(popup, "opened", true)
        const buttonY = button.mapToItem(null, 0, 0).y
        const popupY = popup.contentItem.mapToItem(null, 0, 0).y
        verify(Math.abs(popupY - (buttonY + button.height + 4 + popup.topPadding)) < 2, "popup opens below its button")

        mouseClick(button)
        tryCompare(popup, "visible", false)
        wait(100)
        verify(!popup.visible, "a second click on the button leaves the popup closed")

        mouseClick(button)
        tryCompare(popup, "opened", true)
    }
}
