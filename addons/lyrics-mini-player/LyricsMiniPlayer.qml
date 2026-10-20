pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// QML add-ons are loaded from their installed package folder. The host gives
// them the same app API as built-in QML, including playback, queue and lyrics.
Item {
    id: root

    property bool queueVisible: false

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.background
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Row {
            width: parent.width
            height: 64
            spacing: 12

            ArtworkImage {
                width: 64
                height: 64
                circular: false
                source: Player.currentSong.artworkUrl
                placeholderSymbol: "music_note"
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 76
                spacing: 4

                StyledText {
                    width: parent.width
                    text: Player.hasSong ? Player.currentSong.name : qsTr("Nothing playing")
                    font.pixelSize: Appearance.fontSize.large
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                StyledText {
                    width: parent.width
                    text: Player.hasSong ? Player.currentSong.artists : qsTr("Choose a song in Blood Moon")
                    color: Appearance.colors.onSurfaceVariant
                    elide: Text.ElideRight
                }
            }
        }

        Row {
            width: parent.width
            spacing: 8

            TextButton {
                variant: root.queueVisible ? TextButton.Tonal : TextButton.Text
                symbol: "lyrics"
                text: qsTr("Lyrics")
                onClicked: root.queueVisible = false
            }
            TextButton {
                variant: root.queueVisible ? TextButton.Text : TextButton.Tonal
                symbol: "queue_music"
                text: qsTr("Queue")
                onClicked: root.queueVisible = true
            }
        }

        Item {
            width: parent.width
            height: parent.height - 64 - 40 - 48 - 36

            ListView {
                id: lyricList
                anchors.fill: parent
                visible: !root.queueVisible
                model: Player.lyrics
                clip: true
                spacing: 14
                topMargin: 8
                bottomMargin: 8

                delegate: Item {
                    id: lyricLine
                    required property int index
                    required property string words
                    width: lyricList.width
                    height: lyricText.implicitHeight
                    readonly property bool active: !Player.lyricsSynchronized || Player.activeLyricIndex === index

                    StyledText {
                        id: lyricText
                        width: parent.width
                        text: lyricLine.words.length > 0 ? lyricLine.words : "♪"
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: lyricLine.active ? 20 : 17
                        font.weight: lyricLine.active ? Font.Bold : Font.Medium
                        color: lyricLine.active ? Appearance.colors.onSurface : Appearance.colors.onSurfaceVariant
                        opacity: lyricLine.active ? 1 : 0.52

                        Behavior on opacity {
                            NumberAnimation { duration: Appearance.duration(180); easing.type: Easing.OutCubic }
                        }
                        Behavior on font.pixelSize {
                            NumberAnimation { duration: Appearance.duration(180); easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: Player.lyricsSynchronized
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: Player.seekToLyricLine(lyricLine.index)
                    }
                }

                Connections {
                    target: Player
                    function onActiveLyricIndexChanged() {
                        if (Player.activeLyricIndex >= 0) lyricList.positionViewAtIndex(Player.activeLyricIndex, ListView.Center)
                    }
                    function onLyricsChanged() {
                        if (Player.activeLyricIndex >= 0) lyricList.positionViewAtIndex(Player.activeLyricIndex, ListView.Center)
                    }
                }
            }

            ListView {
                id: queueList
                anchors.fill: parent
                visible: root.queueVisible
                model: Player.upNext
                clip: true
                spacing: 4

                delegate: RippleButton {
                    id: queueRow
                    required property string name
                    required property string artists
                    required property song song
                    width: queueList.width
                    implicitHeight: 58
                    leftPadding: 12
                    rightPadding: 12
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.layer1
                    colBackgroundHover: Appearance.colors.layer1Hover
                    onClicked: Player.playFromQueue(song)

                    contentItem: Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        spacing: 2
                        StyledText {
                            width: parent.width
                            text: queueRow.name
                            elide: Text.ElideRight
                        }
                        StyledText {
                            width: parent.width
                            text: queueRow.artists
                            color: Appearance.colors.onSurfaceVariant
                            font.pixelSize: Appearance.fontSize.smaller
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.queueVisible ? Player.upNext.count === 0 : !Player.loadingLyrics && !Player.hasLyrics
                width: parent.width - 28
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: Appearance.colors.onSurfaceVariant
                text: root.queueVisible
                    ? qsTr("Nothing is waiting in the queue.")
                    : Player.loadingLyrics ? qsTr("Loading lyrics…")
                    : Player.lyricsMessage.length > 0 ? Player.lyricsMessage
                    : qsTr("Lyrics are unavailable for this song.")
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            IconButton {
                enabled: Player.hasSong
                symbol: "skip_previous"
                tooltip: qsTr("Restart song or go to previous song")
                onClicked: Player.skipBackward()
            }
            IconButton {
                enabled: Player.hasSong
                variant: IconButton.Filled
                size: 48
                iconSize: 26
                symbol: Player.playing ? "pause" : "play_arrow"
                onClicked: Player.togglePlayback()
            }
            IconButton {
                enabled: Player.hasSong
                symbol: "skip_next"
                onClicked: Player.skipForward()
            }
        }
    }
}
