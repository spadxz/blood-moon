pragma ComponentBehavior: Bound
import QtQuick
import Scarlett

// The supplied eclipse photograph, upscaled from its original pixels and
// fitted as a 4K backdrop for the main window and immersive player.
Item {
    id: root

    clip: true

    Image {
        anchors.fill: parent
        // Bring the supplied moon forward in the composition while keeping
        // its center fixed; the parent clips the extra image area cleanly.
        scale: Appearance.scarlett ? 1.65 : 1
        source: Appearance.scarlett ? "qrc:/images/scarlett-background.png" : ""
        sourceSize: Qt.size(3840, 2160)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        cache: true
    }
}
