pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// The supplied eclipse photograph, upscaled from its original pixels and
// fitted as a 4K backdrop for the main window and immersive player.
Item {
    id: root

    clip: true

    Image {
        anchors.fill: parent
        source: Appearance.bloodMoon ? "qrc:/images/blood-moon-background.png" : ""
        sourceSize: Qt.size(3840, 2160)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        cache: true
    }
}
