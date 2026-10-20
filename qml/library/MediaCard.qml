pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import Scarlett

// a shelf or grid card: artwork, a title of up to two lines and a subtitle.
// pressing contracts it slightly; hovering brings a calm gloss and lift.
T.AbstractButton {
    id: root

    property url artworkUrl
    /// what shows in place of a cover it has not got
    property string placeholderSymbol: "music_note"
    property string title
    property string fallbackKey: title
    property string subtitle
    property bool circular: false
    property bool current: false
    property string badgeSymbol: "arrow_forward"
    property real artworkSize: Appearance.sizes.cardSize
    property int titleLines: 2
    /// kept for add-on compatibility; the Scarlett artwork remains still
    property bool wavyOnHover: false
    signal secondaryClicked()

    implicitWidth: artworkSize
    implicitHeight: column.implicitHeight
    hoverEnabled: true
    // click focus would let other mouse buttons grab and press it
    focusPolicy: Qt.TabFocus
    // a restrained hover lift and a short press response
    scale: down ? 0.985 : (hovered ? 1.012 : 1)
    opacity: down ? 0.86 : 1

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.reduceMotion ? 0 : Appearance.motion(210)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.curves.expressiveFastSpatial
        }
    }
    Behavior on opacity {
        NumberAnimation { duration: Appearance.duration(100); easing.type: Easing.OutCubic }
    }

    contentItem: Column {
        id: column
        spacing: 8

        MediaArtwork {
            id: artwork
            width: root.artworkSize
            height: root.artworkSize
            source: root.artworkUrl
            placeholderSymbol: root.placeholderSymbol
            fallbackKey: root.fallbackKey
            circular: root.circular
            current: root.current
            badgeSymbol: root.badgeSymbol
            hovered: root.hovered
        }

        // the words are drawn before the cover and its shadow, which only
        // reaches them faintly: drawn after, every card's shadow lay over
        // the next card's words in the order things are drawn, and nothing
        // in a shelf could share a draw with its neighbour
        StyledText {
            z: -1
            width: root.artworkSize
            text: root.title
            maximumLineCount: root.titleLines
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            horizontalAlignment: root.circular ? Text.AlignHCenter : Text.AlignLeft
            font.pixelSize: Appearance.fontSize.small
            font.weight: Font.DemiBold
        }

        StyledText {
            z: -1
            width: root.artworkSize
            visible: root.subtitle.length > 0
            text: root.subtitle
            elide: Text.ElideRight
            horizontalAlignment: root.circular ? Text.AlignHCenter : Text.AlignLeft
            font.pixelSize: Appearance.fontSize.smaller
            color: Appearance.colors.onSurfaceVariant
        }
    }

    // released over the card, it is about to be clicked: the cover sets off
    // for the hero of whatever page the click opens
    onReleased: {
        if (hovered) {
            UiState.launchHero(artwork.cover, artworkUrl, circular)
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.secondaryClicked()
    }
}
