import QtQuick
import QtQuick.Layouts

Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 1
    color: (typeof borderVariant !== "undefined" ? borderVariant : "#2A2825")
    opacity: 0.5
}
