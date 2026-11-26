import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A page's tabs with its actions beside them. When both don't fit, the tabs fold into a menu under the current one.
RowLayout {
    id: root
    property alias tabs: pageTabs.tabs
    property alias current: pageTabs.current
    default property alias actions: actionRow.data
    readonly property bool folded: width < pageTabs.implicitWidth + spacing + actionRow.implicitWidth
    readonly property string currentLabel: {
        const tab = tabs.find(tab => tab.id === current)
        return tab ? tab.label : ""
    }
    signal selected(string id)

    z: 100
    Layout.fillWidth: true
    // Without this the unfolded row's full width becomes its minimum, so a narrowing window could never fold it.
    Layout.minimumWidth: 0
    Layout.leftMargin: 28
    Layout.rightMargin: 28
    Layout.topMargin: 16
    Layout.bottomMargin: 14
    spacing: 16

    PageTabs {
        id: pageTabs
        visible: !root.folded
        onSelected: id => root.selected(id)
    }

    // Looks like the current tab, with a chevron to open the others.
    ButtonBase {
        id: foldedTab
        visible: root.folded
        // Hidden when the tabs unfold, so it mustn't keep keyboard focus or catch keys then.
        enabled: visible
        activeFocusOnTab: visible
        implicitWidth: foldedRow.implicitWidth
        implicitHeight: 32
        Accessible.role: Accessible.ButtonMenu
        Accessible.name: root.currentLabel
        onClicked: tabMenu.visible ? tabMenu.close() : tabMenu.open()

        Row {
            id: foldedRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Label {
                text: root.currentLabel
                color: textPrimary
                font.family: displayFont
                font.pixelSize: 15
                font.weight: Font.Bold
            }

            LucideIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                icon: tabMenu.visible ? "chevron-up" : "chevron-down"
                color: foldedTab.isHovered ? textPrimary : textSecondary
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: foldedRow.implicitWidth
            height: 2.5
            radius: 1.25
            color: recordRed
        }

        Menu {
            id: tabMenu
            y: parent.height + 6
            implicitWidth: 190
            padding: 6
            // A press on the tab itself toggles the menu instead of closing and reopening it.
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
            background: MenuSurface {}

            Repeater {
                model: root.tabs

                AppMenuItem {
                    required property var modelData
                    text: modelData.label
                    // Not checkable: choosing the current tab would uncheck it, and nothing binds it back.
                    checked: modelData.id === root.current
                    onTriggered: root.selected(modelData.id)
                }
            }
        }
    }

    RowLayout {
        id: actionRow
        Layout.fillWidth: true
        spacing: 8

        Item { Layout.fillWidth: true }
    }
}
