pragma ComponentBehavior: Bound
import QtQuick
import Scarlett

// A single quiet chrome reflection when the pointer enters a surface.
Item {
    id: root

    property bool active: false
    property real radius: Appearance.rounding.small

    clip: true
    opacity: active ? 1 : 0
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation { duration: Appearance.duration(140); easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: reflection
        x: -width
        y: -height * 0.28
        width: Math.max(40, root.width * 0.34)
        height: root.height * 1.56
        radius: root.radius
        rotation: 12

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.44; color: Qt.rgba(0.94, 0.96, 1, 0.16) }
            GradientStop { position: 0.58; color: Qt.rgba(0.63, 0.07, 0.15, 0.13) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    SequentialAnimation {
        id: sweep
        running: false

        NumberAnimation {
            target: reflection
            property: "x"
            from: -reflection.width
            to: root.width + reflection.width
            duration: 620
            easing.type: Easing.InOutSine
        }
    }

    onActiveChanged: {
        if (!active) {
            sweep.stop()
            reflection.x = -reflection.width
        } else if (Appearance.reduceMotion) {
            reflection.x = (width - reflection.width) / 2
        } else {
            reflection.x = -reflection.width
            sweep.restart()
        }
    }
}
