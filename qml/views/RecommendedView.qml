pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import Swiftify

Flickable {
    id: root

    topMargin: Appearance.sizes.topBarHeight
    contentHeight: column.implicitHeight + Appearance.sizes.playerBarClearance
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: StyledScrollBar { topPadding: 3 + Appearance.sizes.topBarHeight }

    readonly property real margin: Appearance.sizes.pageMargin

    Column {
        id: column
        x: root.margin
        y: 26
        width: root.width - 2 * x
        spacing: 18

        Item {
            width: parent.width
            height: 66

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                TitleText {
                    text: qsTr("Made for you")
                    level: "headline"
                }
                StyledText {
                    text: qsTr("Daily discoveries shaped by your listening and playlists")
                    color: Appearance.colors.onSurfaceVariant
                    font.pixelSize: Appearance.fontSize.smaller
                }
            }

            TextButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                variant: TextButton.Outlined
                symbol: "refresh"
                text: qsTr("Refresh")
                onClicked: Library.loadDailyRecommendations(true)
            }
        }

        TitleText {
            width: parent.width
            visible: Library.dailyRecommendationArtists.count > 0
            text: qsTr("Artists to explore")
            font.pixelSize: Appearance.fontSize.title
            font.weight: Font.Bold
        }

        Flow {
            width: parent.width
            spacing: Appearance.sizes.shelfGap
            visible: Library.dailyRecommendationArtists.count > 0

            Repeater {
                model: Library.dailyRecommendationArtists

                MediaCard {
                    required property artist artist
                    artworkSize: Math.min(132, Appearance.sizes.cardSize)
                    artworkUrl: artist.artworkUrl
                    title: artist.name
                    subtitle: qsTr("New artist")
                    onClicked: Library.selectArtist(artist)
                }
            }
        }

        TitleText {
            width: parent.width
            visible: Library.dailyRecommendationSongs.count > 0
            topPadding: 6
            text: qsTr("New songs for you")
            font.pixelSize: Appearance.fontSize.title
            font.weight: Font.Bold
        }

        Repeater {
            model: Library.dailyRecommendationSongs

            SongRow {
                x: 0
                width: column.width
                songs: Library.dailyRecommendationSongs
                showsNumber: false
            }
        }

        EmptyState {
            width: parent.width
            height: 220
            visible: Library.dailyRecommendationSongs.count === 0
            symbol: "auto_awesome"
            title: qsTr("Your daily mix is still learning")
            description: qsTr("Play a few songs and open a couple of your playlists, then refresh. Blood Moon will look for tracks you have not played or saved yet.")
        }
    }

    Component.onCompleted: Library.loadDailyRecommendations()
}
