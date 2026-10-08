import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "AutoEqProfiles.js" as AutoEq

SettingCard {
    id: root

    readonly property var eq: player.equalizer
    readonly property var bandLabels: ["31", "62", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"]
    readonly property var presets: [
        { label: "Flat", bands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] },
        { label: "Bass Boost", bands: [6, 5, 4, 2, 0, 0, 0, 0, 0, 0] },
        { label: "Treble Boost", bands: [0, 0, 0, 0, 0, 0, 1, 3, 5, 6] },
        { label: "Vocal", bands: [-2, -2, -1, 0, 2, 3, 3, 2, 0, -1] },
        { label: "Loudness", bands: [4, 3, 1, 0, -1, -1, 0, 1, 3, 4] }
    ]
    readonly property var headphoneOptions: [{ value: "", label: "None" }].concat(
        AutoEq.profiles.map(p => ({ value: p.brand + " " + p.name, label: p.brand + " " + p.name })))

    function apply(changes) {
        player.setEqualizer(Object.assign({}, eq, changes))
    }

    // A boost would clip loud songs, so picking a curve lowers the preamp by its largest boost.
    function applyCurve(name, bands) {
        apply({ enabled: true, preset: name, bands: bands, preamp: -Math.max(0, Math.max(...bands)) })
    }

    function setBand(index, value) {
        const bands = eq.bands.slice()
        bands[index] = value
        apply({ bands: bands, preset: "Custom" })
    }

    component BandSlider: Item {
        id: band
        property string label: ""
        property real value: 0
        signal moved(real value)

        readonly property real range: 12
        implicitWidth: 34
        implicitHeight: 180
        activeFocusOnTab: true
        Accessible.role: Accessible.Slider
        Accessible.name: band.label + " Hz, " + band.value.toFixed(1) + " dB"
        Keys.onUpPressed: band.moved(Math.min(range, Math.round(band.value + 1)))
        Keys.onDownPressed: band.moved(Math.max(-range, Math.round(band.value - 1)))

        Label {
            id: valueLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            text: (band.value > 0 ? "+" : "") + band.value.toFixed(band.value % 1 === 0 ? 0 : 1)
            color: band.value === 0 ? silverDim : textPrimary
            font.family: monoFont
            font.pixelSize: 11
        }

        Item {
            id: track
            anchors.top: valueLabel.bottom
            anchors.bottom: freqLabel.top
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: 24

            readonly property real zeroY: height / 2
            readonly property real valueY: height / 2 - band.value / band.range * height / 2

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 4
                height: parent.height
                radius: 2
                color: surfaceElevated
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 4
                y: Math.min(track.zeroY, track.valueY)
                height: Math.abs(track.valueY - track.zeroY)
                radius: 2
                color: recordRed
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: track.valueY - height / 2
                width: 14
                height: 14
                radius: 7
                color: textPrimary
                border.width: band.activeFocus ? 2 : 0
                border.color: accentText
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                function valueAt(y) {
                    const v = (track.height / 2 - (y - 6)) / (track.height / 2) * band.range
                    return Math.round(Math.max(-band.range, Math.min(band.range, v)) * 2) / 2
                }
                onPressed: mouse => { band.forceActiveFocus(); band.moved(valueAt(mouse.y)) }
                onPositionChanged: mouse => { if (pressed) band.moved(valueAt(mouse.y)) }
                onDoubleClicked: band.moved(0)
            }
        }

        Label {
            id: freqLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: band.label
            color: textSecondary
            font.family: monoFont
            font.pixelSize: 11
        }
    }

    SettingRow {
        iconName: "sliders-horizontal"
        title: "Equalizer"
        subtitle: root.eq.enabled ? "On · " + root.eq.preset : "Shape the sound with ten bands from 31 Hz to 16 kHz"

        SettingSwitch {
            checked: !!root.eq.enabled
            onToggled: val => root.apply({ enabled: val })
        }
    }

    SettingDivider {}

    SettingChoiceGroup {
        iconName: "audio-lines"
        title: "Preset"
        subtitle: "Starting points you can adjust band by band"
        forceMenu: true
        options: root.presets.map(p => ({ value: p.label, label: p.label }))
            .concat(root.presets.some(p => p.label === root.eq.preset) ? [] : [{ value: root.eq.preset, label: root.eq.preset }])
        selectedValue: root.eq.preset
        onOptionSelected: value => {
            const preset = root.presets.find(p => p.label === value)
            if (preset)
                root.applyCurve(preset.label, preset.bands)
        }
    }

    SettingDivider {}

    SettingChoiceGroup {
        iconName: "headphones"
        title: "Headphone Correction"
        subtitle: "Measured curves from the AutoEq project that even out your headphones"
        forceMenu: true
        options: root.headphoneOptions
        selectedValue: root.headphoneOptions.some(o => o.value === root.eq.preset) ? root.eq.preset : ""
        onOptionSelected: value => {
            const profile = AutoEq.profiles.find(p => p.brand + " " + p.name === value)
            if (profile)
                root.applyCurve(value, profile.bands)
            else
                root.applyCurve("Flat", root.presets[0].bands)
        }
    }

    SettingDivider {}

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 16
        Layout.bottomMargin: 16
        spacing: 0
        opacity: root.eq.enabled ? 1 : 0.5

        BandSlider {
            label: "PRE"
            value: root.eq.preamp
            onMoved: value => root.apply({ preamp: value })
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            color: borderSubtle
        }

        Repeater {
            model: root.bandLabels

            delegate: Item {
                Layout.fillWidth: true
                implicitHeight: 180

                BandSlider {
                    anchors.horizontalCenter: parent.horizontalCenter
                    label: modelData
                    value: root.eq.bands[index]
                    onMoved: value => root.setBand(index, value)
                }
            }
        }
    }

    SettingDivider {}

    SettingRow {
        iconName: "rotate-ccw"
        title: "Reset"
        subtitle: "Set every band and the preamp back to 0 dB"

        SettingButton {
            text: "Reset"
            onClicked: root.apply({ preset: "Flat", bands: root.presets[0].bands, preamp: 0 })
        }
    }
}
