pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import Scarlett

// a genre to explore: a two-colour gradient with a big faint shape of its
// own cut off by the corner, with a restrained highlight on hover.
T.AbstractButton {
    id: root

    property string name
    property string symbol
    property color startColor
    property color endColor

    readonly property list<string> shapes: ["flower", "cookie9", "clover4", "sunny", "puffy", "ghostish", "bun",
                                            "heart", "softBoom", "pixelCircle", "clover8", "gem", "arch", "fan"]
    /// the genre's own shape, from its name
    readonly property string shape: {
        let hash = 0
        for (let index = 0; index < name.length; ++index) {
            hash = (hash * 31 + name.charCodeAt(index)) >>> 0
        }
        return shapes[hash % shapes.length]
    }

    implicitWidth: Appearance.sizes.cardSize
    implicitHeight: 112
    hoverEnabled: true
    // click focus would let other mouse buttons grab and press it
    focusPolicy: Qt.TabFocus
    scale: down ? 0.985 : (hovered ? 1.012 : 1)

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.reduceMotion ? 0 : Appearance.motion(210)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.curves.expressiveFastSpatial
        }
    }

    background: Item {
        SoftShadow {
            anchors.fill: parent
            radius: Appearance.sizes.artworkRadius
            blur: root.hovered ? 12 : 6
            offset: Qt.vector2d(0, root.hovered ? 6 : 3)
            color: Qt.rgba(0, 0, 0, root.hovered ? 0.2 : 0.1)
        }

        // hovered, its edge turns to running scallops, as a cover's does
        WavyClip {
            anchors.fill: parent
            radius: Appearance.sizes.artworkRadius
            wavy: false

            Rectangle {
                anchors.fill: parent
                radius: Appearance.sizes.artworkRadius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: root.startColor }
                    GradientStop { position: 1; color: root.endColor }
                }

                MaterialShape {
                    x: parent.width - 100
                    y: -16
                    width: 136
                    height: 136
                    shape: root.shape
                    color: Qt.rgba(1, 1, 1, 0.16)
                    // cut off by the card's edge, round corner and all
                    parentClipRadius: Appearance.sizes.artworkRadius
                    spinAngle: 8

                    Behavior on spinAngle {
                        enabled: !Appearance.performanceMode
                        Bounce {}
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -8
                        anchors.verticalCenterOffset: 8
                        text: root.symbol
                        iconSize: 50
                        fill: 1
                        weight: 600
                        rotation: 10
                        color: Qt.rgba(1, 1, 1, 0.34)
                    }
                }
            }
        }
    }

    contentItem: Item {
        StyledText {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 14
                text: qsTranslate("Genres", root.name)
            color: "white"
            font.pixelSize: Appearance.fontSize.larger
            font.weight: Font.Bold
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
