import QtQuick

GridView {
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: UiConstants.flickDeceleration
    maximumFlickVelocity: UiConstants.maximumFlickVelocity
    cacheBuffer: UiConstants.cacheBuffer
}
