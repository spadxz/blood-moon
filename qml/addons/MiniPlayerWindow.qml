pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// A native floating host for any installed miniPlayer extension. Add-ons
// provide only the content; Blood Moon owns the close and always-on-top chrome.
Window {
    id: root

    property var transientParentWindow
    property bool pinned: false
    readonly property var addon: Addons.addon(Addons.activeMiniPlayerId)
    readonly property var extension: {
        if (!addon || !addon.extensions) return null
        for (const item of addon.extensions) {
            if (item.slot === "miniPlayer") return item
        }
        return null
    }

    transientParent: transientParentWindow
    width: 380
    height: 600
    minimumWidth: 320
    minimumHeight: 400
    visible: Addons.activeMiniPlayerId.length > 0 && extension !== null
    title: addon ? addon.name : qsTr("Blood Moon Mini Player")
    color: Appearance.colors.background
    flags: pinned ? Qt.Window | Qt.WindowStaysOnTopHint : Qt.Window

    onVisibleChanged: {
        if (visible) requestActivate()
    }
    onClosing: Addons.closeMiniPlayer()

    Connections {
        target: Addons
        function onMiniPlayerChanged() {
            if (Addons.activeMiniPlayerId.length === 0) root.pinned = false
            else if (root.visible) root.requestActivate()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.background

        Column {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                width: parent.width
                height: 48
                color: Appearance.bloodMoon ? Qt.alpha(Appearance.colors.layer1, 0.84)
                                             : Appearance.colors.surfaceContainer
                border.width: Appearance.bloodMoon ? 1 : 0
                border.color: Appearance.bloodMoon ? Qt.rgba(0.95, 0.82, 0.87, 0.4) : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 96
                        text: root.addon ? root.addon.name : qsTr("Mini Player")
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Item { width: 1; height: 1 }

                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 34
                        symbol: root.pinned ? "keep" : "keep_off"
                        toggled: root.pinned
                        tooltip: root.pinned ? qsTr("Unpin window") : qsTr("Keep window on top")
                        onClicked: root.pinned = !root.pinned
                    }
                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 34
                        symbol: "close"
                        tooltip: qsTr("Close mini-player")
                        onClicked: Addons.closeMiniPlayer()
                    }
                }
            }

            Item {
                width: parent.width
                height: parent.height - 48

                Loader {
                    id: content
                    anchors.fill: parent
                    active: root.extension !== null
                    asynchronous: true
                    source: root.extension ? root.extension.entryPoint : ""
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: content.status === Loader.Error
                    width: parent.width - 32
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    color: Appearance.colors.error
                    text: qsTr("This add-on could not be loaded. Check its QML files and Blood Moon API version.")
                }
            }
        }
    }
}
