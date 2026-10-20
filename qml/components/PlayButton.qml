pragma ComponentBehavior: Bound
import QtQuick
import Scarlett

// the play button wherever music starts: a clean circle in both playback
// states, with a small glyph pop when play/pause changes.
ShapeButton {
    id: root

    property bool playing: Player.playing
    property color iconColor: Appearance.colors.onPrimary
    property real iconSize: Math.round(width * 0.52)

    shape: "circle"
    morphTo: "circle"
    morphed: false
    spinRate: 0
    tooltip: playing ? qsTr("Pause") : qsTr("Play")

    onPlayingChanged: if (!Appearance.performanceMode) pop.restart()
    // starting music throws out a little burst of cookies
    onClicked: if (!playing) UiState.burst(root, "play")

    contentItem: Item {
        MaterialSymbol {
            id: glyph
            anchors.centerIn: parent
            text: root.playing ? "pause" : "play_arrow"
            iconSize: root.iconSize
            fill: 1
            color: root.iconColor
        }
    }

    NumberAnimation {
        id: pop
        target: glyph
        property: "scale"
        from: 0.55
        to: 1
        duration: 480
        easing.type: Easing.OutBack
        easing.overshoot: 2.6
    }
}
