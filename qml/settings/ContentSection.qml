pragma ComponentBehavior: Bound
import QtQuick
import Scarlett

// a titled group of settings on a tonal card, as end4's settings app lays
// them out.
Column {
    id: root

    property string title
    property string symbol
    readonly property list<string> shapes: ["cookie9", "clover4", "sunny", "flower", "bun", "heart", "puffy", "gem"]
    /// the section's own shape, from its title
    property string iconShape: {
        let hash = 0
        for (let index = 0; index < title.length; ++index) {
            hash = (hash * 31 + title.charCodeAt(index)) >>> 0
        }
        return shapes[hash % shapes.length]
    }
    default property alias content: rows.data

    width: parent ? parent.width : 0
    spacing: 8

    Row {
        spacing: 10
        leftPadding: 2

        HoverHandler {
            id: headerHover
        }

        ShapeIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.symbol.length > 0
            size: 34
            iconSize: 18
            shape: root.iconShape
            symbol: root.symbol
            hovered: headerHover.hovered
        }
        TitleText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            font.pixelSize: Appearance.fontSize.larger
        }
    }

    Rectangle {
        width: parent.width
        implicitHeight: rows.implicitHeight + 16
        radius: Appearance.rounding.normal
        color: Appearance.scarlett ? Qt.alpha(Appearance.colors.layer1, 0.72)
                                    : Appearance.colors.layer1
        border.width: Appearance.scarlett ? 1 : 0
        border.color: Appearance.scarlett ? Qt.rgba(0.94, 0.92, 1, 0.34)
                                           : "transparent"

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: Appearance.scarlett
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 0.96, 1, 0.10) }
                GradientStop { position: 0.3; color: Qt.rgba(0.8, 0.7, 0.8, 0.035) }
                GradientStop { position: 1; color: Qt.rgba(0.12, 0.005, 0.025, 0.14) }
            }
        }

        Rectangle {
            x: 1
            y: 1
            width: parent.width - 2
            height: 1
            radius: 1
            visible: Appearance.scarlett
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.25; color: Qt.rgba(1, 1, 1, 0.56) }
                GradientStop { position: 0.8; color: Qt.rgba(1, 0.82, 0.9, 0.4) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        Column {
            id: rows
            x: 8
            y: 8
            width: parent.width - 16
            spacing: 2
        }
    }
}
