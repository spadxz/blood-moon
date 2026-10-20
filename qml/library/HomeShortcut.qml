pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import Swiftify

// a library shortcut on home (HomeLibraryShortcut)
T.AbstractButton {
    id: root

    property string title
    property string subtitle
    property string symbol
    property url artworkSource

    implicitHeight: 64
    hoverEnabled: true
    // click focus would let other mouse buttons grab and press it
    focusPolicy: Qt.TabFocus
    scale: down ? 0.98 : 1

    Behavior on scale {
        enabled: !Appearance.performanceMode
        Bounce {}
    }

    // hovered, its edge turns to running scallops
    background: WavyClip {
        radius: 16
        wavy: root.hovered && !Appearance.bloodMoon
        depth: 1.7
        wavelength: 30

        Rectangle {
            anchors.fill: parent
            radius: 16
            // two steps up from the page (surfaceContainerLow), so it stands off it
            color: Appearance.bloodMoon
                   ? Qt.alpha(Appearance.colors.layer1, root.hovered ? 0.42 : 0.30)
                   : root.hovered ? Appearance.colors.surfaceContainerHighest : Appearance.colors.surfaceContainerHigh
            border.width: Appearance.bloodMoon ? 1 : 0
            border.color: Appearance.bloodMoon ? Qt.rgba(0.88, 0.89, 0.95, root.hovered ? 0.42 : 0.22) : "transparent"

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: Appearance.bloodMoon
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, root.hovered ? 0.09 : 0.045) }
                    GradientStop { position: 0.56; color: "transparent" }
                    GradientStop { position: 1; color: Qt.rgba(0.38, 0.008, 0.035, root.hovered ? 0.12 : 0.07) }
                }
            }

            Behavior on color {
                ElementMoveFastColor {}
            }
        }

        HoverSheen {
            anchors.fill: parent
            radius: 16
            active: root.hovered && !Appearance.bloodMoon
        }
    }

    contentItem: Item {
        Item {
            id: badge
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 44

            ArtworkImage {
                anchors.fill: parent
                visible: root.artworkSource.toString().length > 0
                source: root.artworkSource
                fallbackKey: root.title
                radius: 10
                borderWidth: 1
                borderColor: Qt.rgba(0.88, 0.88, 0.94, 0.2)
            }

            // Keep an undecorated glyph when this library has no cover art.
            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.artworkSource.toString().length === 0
                text: root.symbol
                iconSize: 21
                color: Appearance.colors.primary
            }
        }

        Column {
            anchors.left: badge.right
            anchors.leftMargin: 12
            anchors.right: chevron.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            StyledText {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                font.pixelSize: Appearance.fontSize.small
                font.weight: Font.DemiBold
            }
            StyledText {
                width: parent.width
                text: root.subtitle
                elide: Text.ElideRight
                font.pixelSize: Appearance.fontSize.smaller
                color: Appearance.colors.onSurfaceVariant
            }
        }

        MaterialSymbol {
            id: chevron
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "chevron_right"
            iconSize: 18
            color: Appearance.colors.outline
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
