import QtQuick

// The letters down the side of a list sorted by name, as on the phone: clicking or dragging along them jumps the list
// to the first entry filed under that letter.
Item {
    id: root
    // The first index filed under each letter, as LibraryController.letterRows gives them.
    property var rows: ({})
    // The first index showing in the list, which lights up the letter it's filed under.
    property int position: -1
    signal jump(int index)

    readonly property var letters: ["#"].concat("ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(""))
    // The letter whose first entry is the nearest one at or above the position, in either sort direction.
    readonly property string currentLetter: {
        let current = ""
        let best = -1
        for (const letter of letters) {
            const row = rows[letter]
            if (row !== undefined && row <= position && row > best) {
                best = row
                current = letter
            }
        }
        return current
    }
    readonly property var filledLetters: letters.filter(letter => rows[letter] !== undefined)

    // Up and Down step through the letters that have entries, in list order, and jump straight there.
    function step(by) {
        const ordered = filledLetters.slice().sort((a, b) => rows[a] - rows[b])
        const at = ordered.indexOf(currentLetter)
        const next = ordered[Math.max(0, Math.min(ordered.length - 1, at + by))]
        if (next !== undefined)
            jump(rows[next])
    }

    activeFocusOnTab: visible
    Accessible.role: Accessible.ScrollBar
    Accessible.name: qsTr("Jump to letter")
    Keys.onUpPressed: step(-1)
    Keys.onDownPressed: step(1)

    implicitWidth: 18
    visible: Object.keys(rows).length > 1

    function select(y) {
        const index = Math.max(0, Math.min(letters.length - 1, Math.floor(y / height * letters.length)))
        // A letter with nothing under it goes to the next one that has something.
        for (let i = index; i < letters.length; ++i) {
            if (rows[letters[i]] !== undefined) {
                jump(rows[letters[i]])
                return
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(textPrimary, 0.35)
        visible: root.activeFocus
    }

    Column {
        anchors.fill: parent

        Repeater {
            model: root.letters

            Text {
                required property string modelData
                width: root.width
                height: root.height / root.letters.length
                text: modelData
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: monoFont
                font.pixelSize: Math.max(8, Math.min(11, height * 0.75))
                font.weight: modelData === root.currentLetter ? Font.Bold : Font.Normal
                color: modelData === root.currentLetter ? recordRed
                     : root.rows[modelData] === undefined ? Qt.alpha(silverDim, 0.35)
                     : railMouse.containsMouse ? textPrimary : textSecondary
            }
        }
    }

    MouseArea {
        id: railMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.select(mouse.y)
        onPositionChanged: mouse => { if (pressed) root.select(mouse.y) }
    }
}
