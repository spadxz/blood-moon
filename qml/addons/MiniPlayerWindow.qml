pragma ComponentBehavior: Bound
import QtQuick
import Scarlett

// A native floating host for any installed miniPlayer extension. Add-ons
// provide only the content; Scarlett owns the close and always-on-top chrome.
Window {
    id: root

    property var transientParentWindow
    property bool pinned: false
    property bool closingAnimation: false
    property bool animateIn: false
    readonly property bool shouldBeVisible: Addons.activeMiniPlayerId.length > 0 && extension !== null
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
    visible: shouldBeVisible || closingAnimation
    title: addon && addon.name ? addon.name : qsTr("Scarlett Mini Player")
    color: Appearance.colors.background
    flags: {
        let windowFlags = App.macOS ? Qt.Window : Qt.Window | Qt.FramelessWindowHint
        if (pinned) windowFlags |= Qt.WindowStaysOnTopHint
        return windowFlags
    }
    opacity: 0

    Behavior on opacity {
        NumberAnimation {
            duration: Settings.reduceMotion || Settings.performanceMode ? 1 : 190
            easing.type: Easing.OutCubic
        }
    }

    onShouldBeVisibleChanged: syncVisibility()

    function syncVisibility() {
        if (shouldBeVisible) {
            closeAnimation.stop()
            closingAnimation = false
            requestActivate()
            Qt.callLater(() => {
                animateIn = true
                opacity = 1
            })
        } else if (visible) {
            animateIn = false
            opacity = 0
            closingAnimation = true
            closeAnimation.restart()
        }
    }

    Component.onCompleted: if (shouldBeVisible) syncVisibility()

    onVisibleChanged: {
        if (visible) requestActivate()
    }
    onClosing: Addons.closeMiniPlayer()

    Timer {
        id: closeAnimation
        interval: Settings.reduceMotion || Settings.performanceMode ? 1 : 200
        onTriggered: {
            if (!root.shouldBeVisible) root.closingAnimation = false
        }
    }

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
        scale: root.animateIn ? 1 : 0.985

        Behavior on scale {
            NumberAnimation {
                duration: Appearance.reduceMotion ? 0 : Appearance.motion(260)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.curves.expressiveFastSpatial
            }
        }

        Column {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                width: parent.width
                height: 48
                color: Appearance.scarlett ? Qt.alpha(Appearance.colors.layer1, 0.84)
                                             : Appearance.colors.surfaceContainer
                border.width: Appearance.scarlett ? 1 : 0
                border.color: Appearance.scarlett ? Qt.rgba(0.95, 0.82, 0.87, 0.4) : "transparent"

                DragHandler {
                    target: null
                    onActiveChanged: if (active) root.startSystemMove()
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 177
                        text: root.addon && root.addon.name ? root.addon.name : qsTr("Mini Player")
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
                        symbol: "remove"
                        tooltip: qsTr("Minimize mini-player")
                        onClicked: root.showMinimized()
                    }
                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 34
                        symbol: root.visibility === Window.Maximized ? "close_fullscreen" : "open_in_full"
                        tooltip: root.visibility === Window.Maximized ? qsTr("Restore mini-player") : qsTr("Maximize mini-player")
                        onClicked: root.visibility === Window.Maximized ? root.showNormal() : root.showMaximized()
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
                    text: qsTr("This add-on could not be loaded. Check its QML files and Scarlett API version.")
                }
            }
        }
    }

    // Frameless windows retain resize behavior through app-owned edge grips.
    MouseArea {
        x: 0
        y: 8
        width: 6
        height: parent.height - 16
        z: 20
        cursorShape: Qt.SizeHorCursor
        onPressed: root.startSystemResize(Qt.LeftEdge)
    }
    MouseArea {
        x: parent.width - width
        y: 8
        width: 6
        height: parent.height - 16
        z: 20
        cursorShape: Qt.SizeHorCursor
        onPressed: root.startSystemResize(Qt.RightEdge)
    }
    MouseArea {
        x: 8
        y: 0
        width: parent.width - 16
        height: 6
        z: 20
        cursorShape: Qt.SizeVerCursor
        onPressed: root.startSystemResize(Qt.TopEdge)
    }
    MouseArea {
        x: 8
        y: parent.height - height
        width: parent.width - 16
        height: 6
        z: 20
        cursorShape: Qt.SizeVerCursor
        onPressed: root.startSystemResize(Qt.BottomEdge)
    }
    MouseArea {
        x: 0
        y: 0
        width: 12
        height: 12
        z: 21
        cursorShape: Qt.SizeFDiagCursor
        onPressed: root.startSystemResize(Qt.LeftEdge | Qt.TopEdge)
    }
    MouseArea {
        x: parent.width - width
        y: 0
        width: 12
        height: 12
        z: 21
        cursorShape: Qt.SizeBDiagCursor
        onPressed: root.startSystemResize(Qt.RightEdge | Qt.TopEdge)
    }
    MouseArea {
        x: 0
        y: parent.height - height
        width: 12
        height: 12
        z: 21
        cursorShape: Qt.SizeBDiagCursor
        onPressed: root.startSystemResize(Qt.LeftEdge | Qt.BottomEdge)
    }
    MouseArea {
        x: parent.width - width
        y: parent.height - height
        width: 12
        height: 12
        z: 21
        cursorShape: Qt.SizeFDiagCursor
        onPressed: root.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
    }
}
