import QtQuick

Flickable {
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: UiConstants.flickDeceleration
    maximumFlickVelocity: UiConstants.maximumFlickVelocity
}
