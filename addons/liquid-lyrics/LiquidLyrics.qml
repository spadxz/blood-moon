pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// Loaded only while the lyrics inspector is open. The app's spectrum renderer
// already sleeps when inactive, so this panel adds no permanent audio work.
Item {
    id: root

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.layer0
    }

    Image {
        anchors.fill: parent
        source: "qrc:/images/blood-moon-background.png"
        sourceSize: Qt.size(520, 980)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        opacity: 0.24
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(0.025, 0.005, 0.012, 0.36) }
            GradientStop { position: 0.58; color: Qt.rgba(0.018, 0.004, 0.009, 0.68) }
            GradientStop { position: 1; color: Qt.rgba(0.008, 0.003, 0.006, 0.90) }
        }
    }

    SpectrumView {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.min(118, root.height * 0.19)
        kind: SpectrumView.Immersive
        wave: true
        continuous: true
        sensitivity: Settings.visualizerSensitivity
        active: Player.playing && Player.showingLyrics && Settings.visualizersEnabled
                 && !Appearance.performanceMode
        opacity: 0.48
    }

    ListView {
        id: lyricList
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 18
        anchors.bottomMargin: 18
        clip: true
        spacing: 15
        model: Player.lyrics
        currentIndex: Player.activeLyricIndex
        preferredHighlightBegin: height * 0.43
        preferredHighlightEnd: height * 0.57
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: Appearance.reduceMotion ? 0 : 360
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            id: lyricRow
            required property int index
            required property string words
            width: lyricList.width
            height: lyricText.implicitHeight + 8
            readonly property bool current: Player.lyricsSynchronized
                                                ? Player.activeLyricIndex === index
                                                : true

            StyledText {
                id: lyricText
                anchors.centerIn: parent
                width: parent.width
                text: lyricRow.words.length > 0 ? lyricRow.words : "♪"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: lyricRow.current ? Appearance.fontSize.large : Appearance.fontSize.normal
                font.weight: lyricRow.current ? Font.DemiBold : Font.Medium
                color: lyricRow.current ? Appearance.colors.onSurface : Appearance.colors.onSurfaceVariant
                opacity: lyricRow.current ? 1 : 0.58
                Behavior on opacity { NumberAnimation { duration: Appearance.reduceMotion ? 0 : 220 } }
                Behavior on font.pixelSize { NumberAnimation { duration: Appearance.reduceMotion ? 0 : 220 } }
            }

            TapHandler {
                enabled: Player.lyricsSynchronized
                onTapped: Player.seekToLyricLine(lyricRow.index)
            }
        }

        Connections {
            target: Player
            function onLyricsChanged() { lyricList.followActiveLine() }
            function onActiveLyricIndexChanged() { lyricList.followActiveLine() }
        }

        function followActiveLine() {
            if (Player.activeLyricIndex >= 0 && Player.activeLyricIndex < count)
                positionViewAtIndex(Player.activeLyricIndex, ListView.Center)
        }
    }

    StyledText {
        anchors.centerIn: parent
        width: parent.width - 36
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        visible: !Player.loadingLyrics && !Player.hasLyrics
        text: Player.lyricsMessage.length > 0 ? Player.lyricsMessage : qsTr("Lyrics are unavailable for this song.")
        color: Appearance.colors.onSurfaceVariant
    }
}
