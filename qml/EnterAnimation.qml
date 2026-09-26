import QtQuick

ParallelAnimation {
    id: root
    property Item target
    property Translate shift
    property string axis: "y"
    property real distance: 10
    property int duration: UiConstants.durationStd

    NumberAnimation {
        target: root.target
        property: "opacity"
        from: 0
        to: 1
        duration: root.duration
        easing.type: UiConstants.easingStd
    }

    NumberAnimation {
        target: root.shift
        property: root.axis
        from: root.distance
        to: 0
        duration: root.duration
        easing.type: UiConstants.easingStd
    }
}
