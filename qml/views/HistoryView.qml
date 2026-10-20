pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import Swiftify

Flickable {
    id: root

    topMargin: Appearance.sizes.topBarHeight
    contentHeight: column.implicitHeight + 24 + Appearance.sizes.playerBarClearance
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: StyledScrollBar { topPadding: 3 + Appearance.sizes.topBarHeight }

    property string period: "week"
    property int selectedYear: new Date().getFullYear()
    property int historyRevision: 0
    property int artistProfileRevision: 0
    property string selectedArtistName: ""
    readonly property var summary: {
        return root.historyRevision >= 0 ? Player.historySummary(period, selectedYear) : ({})
    }
    readonly property string artistQuery: artistSearch.text.trim()
    readonly property var artistSummary: {
        return root.historyRevision >= 0 && artistQuery.length > 0
            ? Player.historySummary(period, selectedYear, artistQuery) : ({})
    }
    readonly property var selectedSpotifyArtist: {
        root.artistProfileRevision
        const count = Library.searchArtists.count
        let prefixMatch = null
        for (let index = 0; index < count; ++index) {
            const candidate = Library.searchArtists.at(index)
            if (candidate.name.toLocaleLowerCase() === root.selectedArtistName.toLocaleLowerCase()) return candidate
            if (prefixMatch === null && candidate.name.toLocaleLowerCase().startsWith(root.selectedArtistName.toLocaleLowerCase())) {
                prefixMatch = candidate
            }
        }
        return prefixMatch
    }

    function openArtistProfile(name: string) {
        const artist = name.trim()
        if (artist.length === 0) return
        selectedArtistName = artist
        artistSearch.text = artist
        Library.searchQuery = artist
        artistProfile.open()
    }

    function formatMinutes(minutes: int): string {
        const hours = Math.floor(minutes / 60)
        const remainingMinutes = minutes % 60
        return hours > 0 ? qsTr("%1 hr %2 min").arg(hours).arg(remainingMinutes)
                         : qsTr("%1 min").arg(remainingMinutes)
    }

    function formatListeningTime(stats: var): string {
        const plays = Number(stats.playCount ?? 0)
        const timedPlays = Number(stats.durationPlayCount ?? 0)
        if (plays > 0 && timedPlays === 0) return qsTr("Import data")
        const time = formatMinutes(Number(stats.listenedMinutes ?? 0))
        return timedPlays < plays ? time + qsTr(" + unknown") : time
    }

    function moveYear(direction: int) {
        const years = Player.listeningHistoryYears.map(value => Number(value))
        if (years.length === 0) {
            selectedYear += direction
            return
        }
        let index = years.indexOf(selectedYear)
        if (index < 0) index = 0
        const next = Math.max(0, Math.min(years.length - 1, index + direction))
        selectedYear = years[next]
    }

    FileDialog {
        id: historyPicker
        title: qsTr("Import Spotify Extended Streaming History")
        fileMode: FileDialog.OpenFiles
        nameFilters: [qsTr("Spotify history JSON (*.json)"), qsTr("JSON files (*.json)")]
        onAccepted: {
            const paths = Array.from(selectedFiles).map(file => file.toString())
            const count = Player.importSpotifyHistory(paths)
            UiState.toastRequested(count > 0 ? qsTr("Imported %1 listening records").arg(count)
                                              : qsTr("No new listening records found"))
        }
    }

    Column {
        id: column
        x: Appearance.sizes.pageMargin
        y: 24
        width: root.width - 2 * x
        spacing: 20

        Item {
            width: parent.width
            height: 52

            TitleText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Listening History")
                level: "headline"
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                TextButton {
                    variant: TextButton.Tonal
                    symbol: "file_upload"
                    text: qsTr("Import Spotify Data")
                    onClicked: historyPicker.open()
                }
                TextButton {
                    visible: Player.listeningHistory.count > 0
                    variant: TextButton.Text
                    symbol: "delete_outline"
                    text: qsTr("Clear")
                    onClicked: Player.clearListeningHistory()
                }
            }
        }

        NoteText {
            width: parent.width
            text: qsTr("Blood Moon saves listens on this device. Spotify’s recent-play list includes timestamps but not listening duration; import Extended Streaming History JSON for accurate listening time and older years.")
        }

        ConfigSelection {
            width: parent.width
            text: qsTr("Recap")
            currentIndex: ["week", "month", "year", "all"].indexOf(root.period)
            segments: [
                Segment { text: qsTr("Week") },
                Segment { text: qsTr("Month") },
                Segment { text: qsTr("Year") },
                Segment { text: qsTr("All Time") }
            ]
            onActivated: (index) => root.period = ["week", "month", "year", "all"][index]
        }

        Row {
            visible: root.period === "year"
            width: parent.width
            height: 38
            spacing: 8

            IconButton {
                symbol: "chevron_left"
                size: 34
                tooltip: qsTr("Previous year")
                onClicked: root.moveYear(1)
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.selectedYear
                font.pixelSize: Appearance.fontSize.large
                font.weight: Font.DemiBold
                tabularNumbers: true
            }
            IconButton {
                symbol: "chevron_right"
                size: 34
                enabled: root.selectedYear < new Date().getFullYear()
                tooltip: qsTr("Next year")
                onClicked: root.moveYear(-1)
            }
        }

        Flow {
            width: parent.width
            spacing: 10

            Repeater {
                model: [
                    { title: qsTr("Plays"), value: root.summary.playCount ?? 0, symbol: "play_arrow" },
                    { title: qsTr("Listening time"), value: root.formatListeningTime(root.summary), symbol: "schedule" },
                    { title: qsTr("Top artist"), value: root.summary.topArtist || qsTr("—"), symbol: "person" },
                    { title: qsTr("Top song"), value: root.summary.topTrack || qsTr("—"), symbol: "music_note" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: (column.width - 10) / 2
                    height: 90
                    radius: Appearance.rounding.normal
                    color: Appearance.bloodMoon ? Qt.alpha(Appearance.colors.layer1, 0.72) : Appearance.colors.layer1
                    border.width: Appearance.bloodMoon ? 1 : 0
                    border.color: Appearance.bloodMoon ? Qt.rgba(0.88, 0.87, 0.92, 0.22) : "transparent"

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 14
                        spacing: 5

                        StyledText {
                            width: parent.width
                            text: modelData.title
                            font.pixelSize: Appearance.fontSize.smaller
                            color: Appearance.colors.onSurfaceVariant
                        }
                        StyledText {
                            width: parent.width
                            text: modelData.value
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fontSize.large
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 10

            TitleText {
                text: qsTr("Artist breakdown")
                font.pixelSize: Appearance.fontSize.larger
            }

            NoteText {
                width: parent.width
                text: qsTr("See how much you’ve listened to a specific artist during this period.")
            }

            SearchField {
                id: artistSearch
                width: parent.width
                placeholder: qsTr("Search an artist, like J")
                onAccepted: root.openArtistProfile(text)
            }

            TextButton {
                visible: root.artistQuery.length > 0
                variant: TextButton.Outlined
                symbol: "person_search"
                text: qsTr("Open artist profile")
                onClicked: root.openArtistProfile(root.artistQuery)
            }

            Flow {
                width: parent.width
                spacing: 8
                visible: artistSuggestions.count > 0

                Repeater {
                    id: artistSuggestions
                    model: {
                        const query = root.artistQuery.toLocaleLowerCase()
                        const artists = Player.listeningHistoryArtists
                        return (query.length > 0
                            ? artists.filter(name => name.toLocaleLowerCase().includes(query))
                            : artists).slice(0, 10)
                    }

                    delegate: TextButton {
                        required property string modelData
                        variant: root.artistQuery === modelData ? TextButton.Tonal : TextButton.Outlined
                        text: modelData
                        onClicked: root.openArtistProfile(modelData)
                    }
                }
            }

            Flow {
                width: parent.width
                spacing: 10
                visible: root.artistQuery.length > 0

                Repeater {
                    model: [
                        { title: qsTr("Plays"), value: root.artistSummary.playCount ?? 0 },
                        { title: qsTr("Listening time"), value: root.formatListeningTime(root.artistSummary) },
                        { title: qsTr("Active days"), value: root.artistSummary.activeDays ?? 0 },
                        { title: qsTr("Longest streak"), value: qsTr("%1 days").arg(root.artistSummary.streakDays ?? 0) }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: (parent.width - 10) / 2
                        height: 78
                        radius: Appearance.rounding.normal
                        color: Appearance.bloodMoon ? Qt.alpha(Appearance.colors.layer1, 0.72) : Appearance.colors.layer1
                        border.width: Appearance.bloodMoon ? 1 : 0
                        border.color: Appearance.bloodMoon ? Qt.rgba(0.88, 0.87, 0.92, 0.22) : "transparent"

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 14
                            spacing: 4

                            StyledText {
                                width: parent.width
                                text: modelData.title
                                font.pixelSize: Appearance.fontSize.smaller
                                color: Appearance.colors.onSurfaceVariant
                            }
                            StyledText {
                                width: parent.width
                                text: modelData.value
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.fontSize.large
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            StyledText {
                visible: root.artistQuery.length > 0 && (root.artistSummary.playCount ?? 0) === 0
                width: parent.width
                text: qsTr("No plays for %1 in this period.").arg(root.artistQuery)
                color: Appearance.colors.onSurfaceVariant
            }
        }

        Item {
            width: parent.width
            height: 38

            TitleText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Recent plays")
                font.pixelSize: Appearance.fontSize.larger
            }
            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("%1 active days").arg(root.summary.activeDays ?? 0)
                color: Appearance.colors.onSurfaceVariant
            }
        }

        ListView {
            width: parent.width
            height: Math.min(480, Math.max(150, count * 68))
            visible: count > 0
            model: Player.listeningHistory
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 2
            ScrollBar.vertical: StyledScrollBar {}

            delegate: Item {
                required property song song
                required property var playedAtMs
                required property var playedDurationMs
                required property string playedContext
                width: ListView.view.width
                height: 66

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: hovered.hovered ? Qt.alpha(Appearance.colors.onSurface, 0.045) : "transparent"
                    Behavior on color { ColorAnimation { duration: Appearance.duration(120) } }
                }
                HoverHandler { id: hovered }

                ArtworkImage {
                    id: cover
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 48
                    height: 48
                    source: parent.song.artworkUrl
                    radius: 7
                    fallbackKey: parent.song.uri
                }

                Column {
                    anchors.left: cover.right
                    anchors.leftMargin: 12
                    anchors.right: dateLabel.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    StyledText {
                        width: parent.width
                        text: parent.parent.song.name
                        elide: Text.ElideRight
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        width: parent.width
                        text: [parent.parent.song.artists, parent.parent.playedContext].filter(value => value.length > 0).join(" · ")
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fontSize.smaller
                        color: Appearance.colors.onSurfaceVariant
                    }
                }

                StyledText {
                    id: dateLabel
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 150
                    horizontalAlignment: Text.AlignRight
                    text: Qt.formatDateTime(new Date(parent.playedAtMs), "MMM d, yyyy  h:mm AP")
                    font.pixelSize: Appearance.fontSize.smallest
                    color: Appearance.colors.onSurfaceVariant
                }
            }
        }

        EmptyState {
            width: parent.width
            height: 180
            visible: Player.listeningHistory.count === 0
            symbol: "history"
            title: qsTr("No Listening History Yet")
            description: qsTr("Play music here, or import Spotify’s Extended Streaming History JSON files.")
        }
    }

    Connections {
        target: Player
        function onListeningHistoryChanged() {
            root.historyRevision++
            if (root.period === "year" && Player.listeningHistoryYears.length > 0
                && Player.listeningHistoryYears.indexOf(String(root.selectedYear)) < 0) {
                root.selectedYear = Number(Player.listeningHistoryYears[0])
            }
        }
    }

    Connections {
        target: Library
        function onSearchChanged() { root.artistProfileRevision++ }
    }

    ArtistHistoryDialog {
        id: artistProfile
        artistName: root.selectedArtistName
        artworkUrl: root.artistProfileRevision >= 0 && root.selectedSpotifyArtist
                    ? root.selectedSpotifyArtist.artworkUrl : ""
        year: root.selectedYear
        historyRevision: root.historyRevision
    }

    Connections {
        target: Library.recentlyPlayed
        function onCountChanged() { Player.syncSpotifyRecentHistory(Library.recentlyPlayed) }
    }

    Component.onCompleted: {
        Player.syncSpotifyRecentHistory(Library.recentlyPlayed)
        if (Player.listeningHistoryYears.length > 0
            && Player.listeningHistoryYears.indexOf(String(selectedYear)) < 0) {
            selectedYear = Number(Player.listeningHistoryYears[0])
        }
    }
}
