pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import Scarlett

// an artist (ArtistDetailView): top songs, then albums and singles
Flickable {
    id: root

    // pages run up under the top bar, which floats over them with no
    // background of its own; they start below it
    topMargin: Appearance.sizes.topBarHeight

    /// the artist it opened on. a page kept behind a newer one (PageHost)
    /// holds on to its own rather than following the library elsewhere
    property artist artist
    property int historyRevision: 0
    readonly property var recentArtistPlays: root.historyRevision >= 0
        ? Player.recentHistoryForArtist(root.artist.name, 8) : []

    Binding {
        target: root
        property: "artist"
        value: Library.currentArtist
        when: root.visible
        restoreMode: Binding.RestoreNone
    }
    readonly property real margin: Appearance.sizes.pageMargin

    /// whether something `top` down the page and `height` tall is in sight,
    /// or within `slack` of it (HomeView.reaches)
    function reaches(top: real, height: real, slack: real): bool {
        return top + height > root.contentY - slack && top < root.contentY + root.height + slack;
    }

    contentHeight: column.implicitHeight + Appearance.sizes.playerBarClearance
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: StyledScrollBar {
        topPadding: 3 + Appearance.sizes.topBarHeight
    }

    Column {
        id: column
        width: root.width

        CollectionHero {
            width: root.width
            artworkUrl: root.artist.artworkUrl
            circular: false
            portrait: true
            kind: "ARTIST"
            title: root.artist.name
            titleSize: 38

            actions: [
                TextButton {
                    iconOnly: parent ? parent.compactActions : false
                    compactSize: parent ? parent.actionSize : 48
                    implicitHeight: iconOnly ? compactSize : 48
                    wavy: true
                    symbol: "play_arrow"
                    burst: "play"
                    text: qsTr("Play")
                    enabled: Library.artistTopSongs.count > 0
                    onClicked: Player.playFromModel(Library.artistTopSongs, 0)
                }
            ]
        }

        TitleText {
            x: root.margin
            Reveal.shown: root.recentArtistPlays.length > 0
            topPadding: 10
            bottomPadding: 8
            text: qsTr("Recently Played by You")
            font.pixelSize: Appearance.fontSize.title
            font.weight: Font.Bold
        }

        Repeater {
            model: root.recentArtistPlays

            delegate: Rectangle {
                id: recentRow
                required property var modelData

                x: root.margin
                width: root.width - 2 * root.margin
                height: 64
                radius: 12
                color: Appearance.scarlett ? Qt.alpha(Appearance.colors.layer1, 0.50)
                                            : Qt.alpha(Appearance.colors.surfaceContainerLow, 0.8)
                border.width: Appearance.scarlett ? 1 : 0
                border.color: Qt.rgba(0.88, 0.89, 0.95, 0.18)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 12
                    spacing: 12

                    ArtworkImage {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        height: 44
                        source: recentRow.modelData.artworkUrl
                        radius: 7
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(0, parent.width - 128)
                        spacing: 3

                        StyledText {
                            width: parent.width
                            text: recentRow.modelData.name
                            elide: Text.ElideRight
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            width: parent.width
                            text: recentRow.modelData.artists + "  ·  " + recentRow.modelData.albumName
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fontSize.smaller
                            color: Appearance.colors.onSurfaceVariant
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: recentRow.modelData.playedAtMs > 0
                              ? Qt.formatDateTime(new Date(recentRow.modelData.playedAtMs), "ddd, MMM d · h:mm AP")
                              : ""
                        font.pixelSize: Appearance.fontSize.smaller
                        color: Appearance.colors.onSurfaceVariant
                    }
                }
            }
        }

        Item {
            width: root.width
            height: 240
            Reveal.shown: Library.loadingArtist

            Column {
                anchors.centerIn: parent
                spacing: 12
                LoadingSpinner {
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                StyledText {
                    text: qsTr("Loading albums…")
                    color: Appearance.colors.onSurfaceVariant
                }
            }
        }

        TitleText {
            x: root.margin
            Reveal.shown: Library.artistTopSongs.count > 0
            bottomPadding: 10
            text: qsTr("Top Songs")
            font.pixelSize: Appearance.fontSize.title
            font.weight: Font.Bold
        }

        Repeater {
            model: Library.artistTopSongs

            SongRow {
                x: root.margin
                width: root.width - 2 * root.margin
                songs: Library.artistTopSongs
            }
        }

        TitleText {
            x: root.margin
            Reveal.shown: !Library.loadingArtist
            topPadding: 28
            bottomPadding: 14
            text: qsTr("Albums & Singles")
            font.pixelSize: Appearance.fontSize.title
            font.weight: Font.Bold
        }

        EmptyState {
            anchors.horizontalCenter: parent.horizontalCenter
            Reveal.shown: !Library.loadingArtist && Library.artistAlbums.count === 0
            symbol: "album"
            title: qsTr("No Albums Found")
        }

        Flow {
            id: albums
            x: root.margin
            width: root.width - 2 * root.margin
            spacing: Appearance.sizes.shelfGap

            Repeater {
                model: Library.artistAlbums

                // a card's place, kept whether the card is there or not: out
                // of sight it is let go of, and its cover with it. a long
                // discography had every cover decoded at once, most of them
                // never drawn and so never handed to the gpu
                Item {
                    id: place

                    required property album album

                    width: Appearance.sizes.cardSize
                    height: Appearance.sizes.cardSize + 64

                    // built half a screen ahead, drawn only in sight; the
                    // place itself stays, as the flow lays out only what shows
                    Loader {
                        active: root.reaches(column.y + albums.y + place.y, place.height, root.height / 2)
                        visible: root.reaches(column.y + albums.y + place.y, place.height, 0)
                        asynchronous: true
                        sourceComponent: MediaCard {
                            artworkUrl: place.album.artworkUrl
                            title: place.album.name
                            subtitle: place.album.releaseDate.slice(0, 4)
                            onClicked: Library.selectAlbum(place.album)
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: Player
        function onListeningHistoryChanged() { root.historyRevision++ }
    }

    Connections {
        target: Library.recentlyPlayed
        function onCountChanged() { Player.syncSpotifyRecentHistory(Library.recentlyPlayed) }
    }

    Component.onCompleted: Player.syncSpotifyRecentHistory(Library.recentlyPlayed)
}
