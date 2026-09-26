import QtQuick

ListView {
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: UiConstants.flickDeceleration
    maximumFlickVelocity: UiConstants.maximumFlickVelocity
    cacheBuffer: UiConstants.cacheBuffer
    populate: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: UiConstants.durationStd; easing.type: UiConstants.easingStd }
    }
}
