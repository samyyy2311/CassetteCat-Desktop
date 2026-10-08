import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

BottomSheet {
    id: root

    property var audioFormat: ({})
    maxWidth: 420

    onClosed: isOpen = false

    component DetailRow: RowLayout {
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        Layout.topMargin: 2
        Layout.bottomMargin: 2

        Label {
            Layout.fillWidth: true
            text: parent.label
            color: root.appWindow.textSecondary
            font.family: root.appWindow.bodyFont
            font.pixelSize: 13
        }

        Label {
            text: parent.value
            color: root.appWindow.textPrimary
            font.family: root.appWindow.bodyFont
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 4

        Label {
            text: root.audioFormat.isHiRes ? "Hi-Res Lossless Audio"
                : (root.audioFormat.isLossless ? "Lossless Audio" : "Audio Quality")
            color: root.appWindow.textPrimary
            font.family: root.appWindow.displayFont
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }

        Label {
            Layout.bottomMargin: 12
            text: root.audioFormat.label || ""
            color: root.appWindow.accentText
            font.family: root.appWindow.monoFont
            font.pixelSize: 13
        }

        DetailRow { label: "Format"; value: root.audioFormat.codecName || "" }

        DetailRow {
            visible: root.audioFormat.sampleRateHz > 0
            label: "Sample Rate"
            value: root.audioFormat.sampleRateHz + " Hz (" + (root.audioFormat.sampleRateHz / 1000).toFixed(1) + " kHz)"
        }

        DetailRow {
            visible: root.audioFormat.bitDepth > 0
            label: "Bit Depth"
            value: root.audioFormat.bitDepth + "-bit"
        }

        DetailRow {
            visible: root.audioFormat.bitrateKbps > 0
            label: "Bitrate"
            value: root.audioFormat.bitrateKbps + " kbps"
        }

        DetailRow {
            label: "Encoding"
            value: root.audioFormat.isLossless ? "Lossless" : "Lossy Compressed"
        }
    }
}
