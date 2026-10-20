pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import Scarlett

// a menu built the first time it is opened, rather than with the view it
// belongs to: most menus are never opened, and each one built is a few
// hundred objects kept for as long as the view is
Loader {
    id: root

    active: false

    // An empty, unanimated copy of the trigger rectangle. Popup's outside-
    // parent policy can close on outside clicks without following its spin.
    Item { id: popupAnchor }

    /// opens it under or beside `anchor`, at `x`, `y` in its coordinates
    function popupAt(anchor: Item, x: real, y: real) {
        active = true
        // through a name: a line opening with a bracket runs on from the
        // one before, and `true(item)` is no call
        const menu = item as T.Menu
        if (menu.visible) {
            menu.close()
            return
        }
        // Settle lazy delegates before Popup fits its geometry to the window.
        menu.contentItem.forceLayout()
        // Toolbar buttons spin and spring after a click. Use their logical
        // position once, then parent the popup to the stationary window.
        const popupParent = anchor.Window.window ? anchor.Window.window.contentItem : anchor.parent
        const position = anchor.parent.mapToItem(popupParent, anchor.x, anchor.y)
        popupAnchor.parent = popupParent
        popupAnchor.x = position.x
        popupAnchor.y = position.y
        popupAnchor.width = anchor.width
        popupAnchor.height = anchor.height
        menu.closePolicy = T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent
        menu.popup(popupAnchor, x, y)
    }

    /// opens it at the pointer
    function popupHere() {
        active = true
        const menu = item as T.Menu
        menu.contentItem.forceLayout()
        menu.popup()
    }
}
