import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var appWindow
    readonly property bool meterVisible: visible && waveRow.visible
    readonly property color recordRedHover: appWindow.recordRedHover
    readonly property color textPrimary: appWindow.textPrimary
    readonly property color textSecondary: appWindow.textSecondary
    readonly property color silverDim: appWindow.silverDim
    readonly property color surfaceElevated: appWindow.surfaceElevated
    readonly property color surfaceCard: appWindow.surfaceCard
    readonly property color borderVariant: appWindow.borderVariant
    readonly property color borderSubtle: appWindow.borderSubtle
    readonly property string displayFont: appWindow.displayFont
    readonly property string bodyFont: appWindow.bodyFont
    readonly property int lyricsFontSize: appWindow.lyricsFontSize
    anchors.fill: parent
    visible: opacity > 0.001
    opacity: root.appWindow.nowPlayingMode === "lyrics" ? 1.0 : 0.0
    scale: root.appWindow.nowPlayingMode === "lyrics" ? 1.0 : 0.98

    Behavior on opacity {
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }

    ListView {
        id: lyricsListView
        Component.onCompleted: root.appWindow.lyricsListView = lyricsListView
        Component.onDestruction: {
            if (root.appWindow.lyricsListView === lyricsListView) root.appWindow.lyricsListView = null
        }
        anchors.fill: parent
        clip: true
        model: root.appWindow.lyricDisplayItems
        currentIndex: root.appWindow.activeLyricDisplayIndex
        spacing: 26
        interactive: root.appWindow.lyricDisplayItems.length > 0
        topMargin: Math.round(height * 0.38)
        bottomMargin: Math.round(height * 0.45)
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: Math.round(height * 0.36)
        preferredHighlightEnd: Math.round(height * 0.38)
        highlightMoveDuration: 550
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: SleekScrollBar { visible: root.appWindow.lyricDisplayItems.length > 0 }

        delegate: Item {
            id: lyricItem
            width: ListView.view.width
            readonly property bool isGap: modelData.type === "gap"
            readonly property bool isCurrent: Boolean(!isGap && root.appWindow.activeLyricDisplayIndex >= 0 && modelData.lineIndex === root.appWindow.activeLyricIndex && root.appWindow.lyricDisplayItems[root.appWindow.activeLyricDisplayIndex] && root.appWindow.lyricDisplayItems[root.appWindow.activeLyricDisplayIndex].type === "line")
            readonly property bool isSynced: !isGap
            readonly property bool gapActive: Boolean(isGap && player.position >= modelData.startMs && player.position <= modelData.endMs)
            height: isGap ? 72 : lyricTextLabel.implicitHeight + 14

            Label {
                id: lyricTextLabel
                width: Math.min(parent.width - 72, 920)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                visible: !lyricItem.isGap
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                text: lyricItem.isGap ? "" : root.appWindow.karaokeLyricHtml(modelData.lineIndex, modelData.text)
                color: isCurrent ? (root.appWindow.lyricsActiveStyle === "accent" ? recordRedHover : "#FFFFFF") : (lyricLineMouse.containsMouse ? textPrimary : (isSynced ? "#7E7A74" : textPrimary))
                horizontalAlignment: root.appWindow.lyricsAlignment === "center" ? Text.AlignHCenter : Text.AlignLeft
                font.family: displayFont
                font.pixelSize: lyricsFontSize
                font.weight: isCurrent ? Font.Bold : Font.DemiBold
                font.letterSpacing: -0.3
                lineHeight: 1.35
                transformOrigin: Item.Center
                scale: isCurrent ? 1.03 : (lyricLineMouse.containsMouse ? 1.01 : 0.96)
                opacity: isCurrent ? 1.0 : (lyricLineMouse.containsMouse ? 0.75 : (isSynced ? 0.28 : 0.85))

                Behavior on color { ColorAnimation { duration: 300 } }
                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10
                visible: lyricItem.isGap
                opacity: lyricItem.gapActive ? 1.0 : 0.22

                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: 7
                        height: 7
                        radius: 4
                        color: recordRedHover
                        y: 0
                        SequentialAnimation on y {
                            running: lyricItem.gapActive && player.isPlaying
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 150 }
                            NumberAnimation { to: -6; duration: 260; easing.type: Easing.OutSine }
                            NumberAnimation { to: 0; duration: 260; easing.type: Easing.InSine }
                            PauseAnimation { duration: (2 - index) * 150 }
                        }
                    }
                }
            }

            MouseArea {
                id: lyricLineMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: player.seek(modelData.startMs)
            }
        }

        Item {
            anchors.fill: parent
            visible: !root.appWindow.parsedLyrics || root.appWindow.parsedLyrics.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 18

                Row {
                    id: waveRow
                    Layout.alignment: Qt.AlignHCenter
                    Layout.minimumHeight: 64
                    Layout.preferredHeight: 64
                    Layout.maximumHeight: 64
                    spacing: 7

                    Repeater {
                        model: [0.42, 0.72, 0.56, 1.0, 0.62, 0.82, 0.46]
                        delegate: Rectangle {
                            required property real modelData
                            width: 6
                            radius: 3
                            color: recordRedHover
                            anchors.verticalCenter: parent.verticalCenter
                            height: 10 + (player.isPlaying ? player.audioLevel * 52 * modelData : 0)
                            Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Instrumental"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 28
                        font.weight: Font.Medium
                        font.letterSpacing: -0.3
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: player.currentTrack.artist ? ("Composed by " + player.currentTrack.artist) : (player.currentTrack.title ? ("Track by " + (player.currentTrack.artist || "Unknown Artist")) : "No lyrics available")
                        color: textSecondary
                        font.family: bodyFont
                        font.pixelSize: 14
                    }
                }

                Item {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 6
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Rectangle {
                        implicitWidth: searchRow.implicitWidth + 32
                        implicitHeight: 40
                        radius: 20
                        color: searchPillMouse.containsMouse ? surfaceElevated : surfaceCard
                        border.width: 1
                        border.color: searchPillMouse.containsMouse ? borderVariant : borderSubtle

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: searchRow
                            anchors.centerIn: parent
                            spacing: 8

                            LucideIcon {
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 15
                                icon: "search"
                                color: recordRedHover
                            }

                            Label {
                                text: "Choose lyrics"
                                color: textPrimary
                                font.family: displayFont
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: searchPillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.appWindow.openLyricsSearch()
                        }
                    }

                    Rectangle {
                        implicitWidth: artRow.implicitWidth + 32
                        implicitHeight: 40
                        radius: 20
                        color: artPillMouse.containsMouse ? surfaceElevated : surfaceCard
                        border.width: 1
                        border.color: artPillMouse.containsMouse ? borderVariant : borderSubtle

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: artRow
                            anchors.centerIn: parent
                            spacing: 8

                            LucideIcon {
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 15
                                icon: "disc"
                                color: silverDim
                            }

                            Label {
                                text: "Album Art"
                                color: textPrimary
                                font.family: displayFont
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: artPillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.appWindow.nowPlayingMode = "controls"
                            }
                        }
                    }
                }
            }
        }
    }

}

