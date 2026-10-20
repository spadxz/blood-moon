pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Templates as T
import Scarlett

StyledDialog {
    id: root

    property string artistName
    property url artworkUrl
    property int year: new Date().getFullYear()
    property int historyRevision: 0
    property string period: "all"

    readonly property var summary: historyRevision >= 0
        ? Player.historySummary(period, year, artistName) : ({})
    readonly property var recentPlays: historyRevision >= 0
        ? Player.recentHistoryForArtist(artistName, 40) : []

    preferredWidth: Math.min(940, parent ? parent.width - 48 : 900)
    padding: 0
    headline: ""

    background: Rectangle {
        radius: 24
        color: Qt.alpha(Appearance.colors.layer1, 0.94)
        border.width: 1
        border.color: Qt.rgba(0.93, 0.92, 0.98, 0.38)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.12) }
            GradientStop { position: 0.52; color: Qt.rgba(0.13, 0.13, 0.16, 0.08) }
            GradientStop { position: 1; color: Qt.rgba(0.22, 0.012, 0.035, 0.22) }
        }
    }

    T.Overlay.modal: Rectangle { color: Qt.rgba(0.015, 0.012, 0.02, 0.78) }

    content: Item {
        width: parent ? parent.width : 900
        height: Math.min(690, root.parent ? root.parent.height - 56 : 640)
        clip: true

        Flickable {
            id: scroll
            anchors.fill: parent
            anchors.margins: 22
            contentWidth: width
            contentHeight: content.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: StyledScrollBar {}

            Column {
                id: content
                width: scroll.width
                spacing: 15

                Item {
                    width: parent.width
                    height: 34

                    StyledText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("ARTIST LISTENING PROFILE")
                        font.pixelSize: Appearance.fontSize.smaller
                        font.letterSpacing: 1.2
                        font.weight: Font.DemiBold
                        color: Appearance.colors.onSurfaceVariant
                    }

                    IconButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        symbol: "close"
                        size: 34
                        onClicked: root.close()
                    }
                }

                Row {
                    width: parent.width
                    height: 232
                    spacing: 22

                    ArtworkImage {
                        width: 172
                        height: 224
                        anchors.verticalCenter: parent.verticalCenter
                        source: root.artworkUrl
                        fallbackKey: root.artistName
                        placeholderSymbol: "person"
                        radius: 12
                        maximumPixelSize: 2048
                    }

                    Column {
                        width: Math.max(0, parent.width - 196)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        StyledText {
                            width: parent.width
                            text: root.artistName
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            font.pixelSize: Appearance.fontSize.display
                            font.weight: Font.Bold
                        }

                        StyledText {
                            width: parent.width
                            text: qsTr("%1 plays · %2 listened · %3 active days")
                                .arg(root.summary.playCount ?? 0)
                                .arg(root.formatListeningTime(root.summary))
                                .arg(root.summary.activeDays ?? 0)
                            wrapMode: Text.Wrap
                            color: Appearance.colors.onSurfaceVariant
                        }

                        StyledText {
                            width: parent.width
                            visible: (root.summary.playCount ?? 0) > 0
                            text: qsTr("Your longest listening streak is %1 days.").arg(root.summary.streakDays ?? 0)
                            wrapMode: Text.Wrap
                            color: Appearance.colors.onSurfaceVariant
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: [
                            { key: "week", label: qsTr("Week") },
                            { key: "month", label: qsTr("Month") },
                            { key: "year", label: qsTr("Year") },
                            { key: "all", label: qsTr("All Time") }
                        ]
                        delegate: TextButton {
                            required property var modelData
                            variant: root.period === modelData.key ? TextButton.Tonal : TextButton.Outlined
                            text: modelData.label
                            onClicked: root.period = modelData.key
                        }
                    }
                    StyledText {
                        visible: root.period === "year"
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.year
                        font.weight: Font.DemiBold
                        color: Appearance.colors.onSurfaceVariant
                    }
                }

                Flow {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: [
                            { title: qsTr("Plays"), value: root.summary.playCount ?? 0 },
                            { title: qsTr("Listening time"), value: root.formatListeningTime(root.summary) },
                            { title: qsTr("Active days"), value: root.summary.activeDays ?? 0 },
                            { title: qsTr("Longest streak"), value: qsTr("%1 days").arg(root.summary.streakDays ?? 0) }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            width: Math.max(130, (scroll.width - 30) / 4)
                            height: 82
                            radius: 14
                            color: Qt.alpha(Appearance.colors.layer1, 0.72)
                            border.width: 1
                            border.color: Qt.rgba(0.91, 0.91, 0.96, 0.20)

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
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
                                    font.pixelSize: Appearance.fontSize.larger
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }
                }

                Flow {
                    width: parent.width
                    spacing: 10
                    visible: (root.summary.topTrack || "").length > 0 || (root.summary.topPlaylist || "").length > 0

                    Repeater {
                        model: [
                            { title: qsTr("Most played song"), value: root.summary.topTrack || "" },
                            { title: qsTr("Top playlist"), value: root.summary.topPlaylist || "" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            visible: modelData.value.length > 0
                            width: Math.max(0, (scroll.width - 10) / 2)
                            height: 62
                            radius: 14
                            color: Qt.alpha(Appearance.colors.layer1, 0.62)
                            border.width: 1
                            border.color: Qt.rgba(0.91, 0.91, 0.96, 0.18)

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 3
                                StyledText {
                                    width: parent.width
                                    text: modelData.title
                                    font.pixelSize: Appearance.fontSize.smallest
                                    color: Appearance.colors.onSurfaceVariant
                                }
                                StyledText {
                                    width: parent.width
                                    text: modelData.value
                                    elide: Text.ElideRight
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 30

                    TitleText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Your recent plays")
                        font.pixelSize: Appearance.fontSize.larger
                    }
                    StyledText {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("%1 records").arg(root.recentPlays.length)
                        color: Appearance.colors.onSurfaceVariant
                        font.pixelSize: Appearance.fontSize.smaller
                    }
                }

                Repeater {
                    model: root.recentPlays
                    delegate: Item {
                        required property var modelData
                        width: content.width
                        height: 56

                        ArtworkImage {
                            id: trackCover
                            x: 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42
                            height: 42
                            source: parent.modelData.artworkUrl
                            radius: 7
                            fallbackKey: parent.modelData.uri
                        }
                        Column {
                            anchors.left: trackCover.right
                            anchors.leftMargin: 10
                            anchors.right: playedDate.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            StyledText {
                                width: parent.width
                                text: parent.parent.modelData.name
                                elide: Text.ElideRight
                                font.weight: Font.DemiBold
                            }
                            StyledText {
                                width: parent.width
                                text: parent.parent.modelData.albumName
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.fontSize.smaller
                                color: Appearance.colors.onSurfaceVariant
                            }
                        }
                        StyledText {
                            id: playedDate
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 155
                            horizontalAlignment: Text.AlignRight
                            text: parent.modelData.playedAtMs > 0
                                ? Qt.formatDateTime(new Date(parent.modelData.playedAtMs), "MMM d, yyyy · h:mm AP") : ""
                            font.pixelSize: Appearance.fontSize.smallest
                            color: Appearance.colors.onSurfaceVariant
                        }
                    }
                }

                EmptyState {
                    width: parent.width
                    height: 100
                    visible: root.recentPlays.length === 0
                    symbol: "history"
                    title: qsTr("No plays found for this artist yet")
                }
            }
        }
    }

    function formatListeningTime(stats: var): string {
        const minutes = Number(stats.listenedMinutes ?? 0)
        const hours = Math.floor(minutes / 60)
        const remainder = minutes % 60
        const time = hours > 0 ? qsTr("%1 hr %2 min").arg(hours).arg(remainder) : qsTr("%1 min").arg(minutes)
        const plays = Number(stats.playCount ?? 0)
        const timedPlays = Number(stats.durationPlayCount ?? 0)
        if (plays > 0 && timedPlays === 0) return qsTr("Import data")
        return timedPlays < plays ? time + qsTr(" + unknown") : time
    }
}
