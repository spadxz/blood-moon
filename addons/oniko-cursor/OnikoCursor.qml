pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// A lightweight vector companion: no image assets, timers, or mouse polling.
// HoverHandler passively observes pointer motion and does not take clicks.
Item {
    id: root

    property real pointerX: width * 0.5
    property real pointerY: height * 0.5

    HoverHandler {
        id: pointer
        target: null
        onPointChanged: {
            root.pointerX = point.position.x
            root.pointerY = point.position.y
        }
    }

    Item {
        id: follower
        width: 64
        height: 66
        x: Math.max(6, Math.min(root.width - width - 6, root.pointerX + 22))
        y: Math.max(6, Math.min(root.height - height - 6, root.pointerY + 18))
        opacity: pointer.hovered ? 1 : 0
        scale: pointer.hovered ? 1 : 0.78

        Behavior on x { SmoothedAnimation { velocity: 860; duration: 150 } }
        Behavior on y { SmoothedAnimation { velocity: 860; duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

        Rectangle {
            id: tail
            x: 43
            y: 43
            width: 18
            height: 6
            radius: 3
            rotation: -28
            transformOrigin: Item.Left
            color: "#171216"
            border.color: "#8d142b"
            border.width: 1
            SequentialAnimation on rotation {
                running: pointer.hovered && !Appearance.reduceMotion
                loops: Animation.Infinite
                NumberAnimation { to: -53; duration: 460; easing.type: Easing.InOutSine }
                NumberAnimation { to: -28; duration: 460; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            x: 5
            y: 6
            width: 22
            height: 23
            radius: 5
            rotation: -18
            color: "#171216"
            border.color: "#8d142b"
            border.width: 1
        }
        Rectangle {
            x: 37
            y: 6
            width: 22
            height: 23
            radius: 5
            rotation: 18
            color: "#171216"
            border.color: "#8d142b"
            border.width: 1
        }
        Rectangle {
            x: 9
            y: 15
            width: 46
            height: 40
            radius: 19
            color: "#101013"
            border.color: "#c32943"
            border.width: 1.4

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 14
                spacing: 13
                Rectangle { id: leftEye; width: 5; height: 7; radius: 3; color: "#ef5368" }
                Rectangle { id: rightEye; width: 5; height: 7; radius: 3; color: "#ef5368" }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 25
                width: 5
                height: 4
                radius: 2
                color: "#e6a0a8"
            }
            Rectangle {
                x: -1
                y: 26
                width: 10
                height: 1
                rotation: -10
                color: "#ae5362"
            }
            Rectangle {
                anchors.right: parent.right
                y: 26
                width: 10
                height: 1
                rotation: 10
                color: "#ae5362"
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: "ONIKO"
            font.pixelSize: Appearance.fontSize.smaller
            font.weight: Font.DemiBold
            font.letterSpacing: 1.1
            color: "#f2dce1"
        }

        SequentialAnimation {
            running: pointer.hovered && !Appearance.reduceMotion
            loops: Animation.Infinite
            PauseAnimation { duration: 3200 }
            ParallelAnimation {
                NumberAnimation { target: leftEye; property: "height"; to: 1; duration: 70 }
                NumberAnimation { target: rightEye; property: "height"; to: 1; duration: 70 }
            }
            PauseAnimation { duration: 100 }
            ParallelAnimation {
                NumberAnimation { target: leftEye; property: "height"; to: 7; duration: 90 }
                NumberAnimation { target: rightEye; property: "height"; to: 7; duration: 90 }
            }
        }
    }
}
