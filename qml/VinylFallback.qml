import QtQuick

Item {
    id: root

    property bool playing: false
    property bool showTonearm: false
    property real progress: 0

    Item {
        id: composition
        anchors.centerIn: parent
        width: Math.min(root.width, root.height)
        height: width

        Image {
            id: record
            anchors.centerIn: parent
            width: composition.width * 0.78
            height: width
            source: "qrc:/qt/qml/CassetteCat/assets/vinyl_record.svg"
            sourceSize.width: Math.ceil(width * 2)
            smooth: true

            Canvas {
                id: labelCanvas
                anchors.centerIn: parent
                width: parent.width * 0.305
                height: width
                property url fallbackArtwork: "qrc:/qt/qml/CassetteCat/assets/cassettecat_icon.png"
                Component.onCompleted: loadImage(fallbackArtwork)
                onWidthChanged: requestPaint()
                onImageLoaded: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.beginPath()
                    ctx.arc(width / 2, height / 2, width / 2, 0, Math.PI * 2)
                    ctx.clip()
                    if (isImageLoaded(fallbackArtwork)) ctx.drawImage(fallbackArtwork, 0, 0, width, height)
                }
            }
            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 8000
                loops: Animation.Infinite
                running: root.playing && root.visible
            }
        }

        Image {
            x: composition.width * 0.83
            y: composition.height * 0.035
            width: composition.width * 0.16
            height: width * 310 / 80
            source: "qrc:/qt/qml/CassetteCat/assets/vinyl_tonearm.svg"
            sourceSize.width: Math.ceil(width * 2)
            sourceSize.height: Math.ceil(height * 2)
            smooth: true
            visible: root.showTonearm && composition.width >= 64
            transform: Rotation {
                origin.x: composition.width * 0.08
                origin.y: composition.width * 0.116
                angle: root.playing ? 10 + 29 * Math.max(0, Math.min(1, root.progress)) : 0
                Behavior on angle {
                    NumberAnimation { duration: 450; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}
