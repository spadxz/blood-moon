pragma ComponentBehavior: Bound
import QtQuick
import Scarlett

// a card's artwork (InteractiveMediaArtwork): on hover it lifts a little, its
// shadow deepens and a round badge fades in. the playing item gets an outline.
Item {
    id: root

    property url source
    property string placeholderSymbol: "music_note"
    property string fallbackKey: source.toString().length > 0 ? source.toString() : placeholderSymbol
    property real radius: Appearance.sizes.artworkRadius
    property bool circular: false
    property string badgeSymbol: "arrow_forward"
    property bool current: false
    property bool hovered: false
    /// kept for add-on compatibility; the artwork edge stays still
    property bool wavy: false

    readonly property real effectiveRadius: circular ? width / 2 : radius
    /// the cover itself, which flies to the page's hero when clicked
    readonly property ArtworkImage cover: art

    SoftShadow {
        anchors.fill: art
        radius: root.effectiveRadius
        blur: root.hovered ? 13 : 7
        offset: Qt.vector2d(0, root.hovered ? 6 : 3)
        color: Qt.rgba(0, 0, 0, root.hovered ? 0.22 : 0.11)
        scale: art.scale

        Behavior on blur {
            NumberAnimation { duration: Appearance.duration(160); easing.type: Easing.OutCubic }
        }
    }

    ArtworkImage {
        id: art
        anchors.fill: parent
        source: root.source
        placeholderSymbol: root.placeholderSymbol
        fallbackKey: root.fallbackKey
        circular: root.circular
        radius: root.radius
        scale: root.hovered ? 1.015 : 1
        // hidden while a cover flies home to it
        opacity: UiState.heroTarget === art ? 0 : 1
        waviness: 0
        borderWidth: root.current ? 2 : 0
        borderColor: Appearance.colors.primary
        squiggleTurning: false

        Behavior on scale {
            NumberAnimation { duration: Appearance.reduceMotion ? 0 : Appearance.motion(160); easing.type: Easing.OutCubic }
        }
    }

    HoverSheen {
        anchors.fill: art
        radius: root.effectiveRadius
        active: root.hovered
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        width: 34
        height: 34
        radius: 17
        color: Qt.rgba(0, 0, 0, 0.58)
        border.width: 0.75
        border.color: Qt.rgba(1, 1, 1, 0.18)
        opacity: root.hovered ? 1 : 0
        scale: root.hovered ? 1 : 0.82
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Appearance.duration(160); easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: Appearance.motion(160); easing.type: Easing.OutCubic }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: root.badgeSymbol
            iconSize: 18
            fill: 1
            weight: 600
            color: "white"
        }
    }
}
