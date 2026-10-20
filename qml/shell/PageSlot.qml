pragma ComponentBehavior: Bound
import QtQuick
import Scarlett

// one step of the PageHost's stack: the page for a destination, built while
// it is kept, and the cover a click on it sent flying to the next page's
// hero, so that cover can fly home again when the next page is left
Item {
    id: slot

    final property Component page
    /// an old step is let go, to be built afresh if back ever reaches it
    final property bool built: true
    final property ArtworkImage returnCover: null
    final property url returnSource
    final property bool returnCircular: false
    readonly property Item view: loader.item as Item

    Loader {
        id: loader
        anchors.fill: parent
        active: slot.built
        sourceComponent: slot.page
    }
}
