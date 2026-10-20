pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Templates as T
import Swiftify

// settings, as a sheet over the window rather than a window of its own, laid
// out like end4's settings app: a navigation rail on the left, and the chosen
// page of settings beside it. escape, a click outside, or its close button
// put it away.
T.Popup {
    id: root

    property int page: 0
    readonly property list<string> titles: [qsTr("Visualizer"), qsTr("Background"), qsTr("Playback"), qsTr("Files"), qsTr("Appearance"), qsTr("Performance"),
                                            qsTr("Account"), qsTr("About"), qsTr("Add-ons")]
    readonly property list<string> symbols: ["graphic_eq", "wallpaper", "play_circle", "folder", "palette", "speed",
                                             "account_circle", "info", "extension"]
    readonly property list<string> shapes: ["sunny", "flower", "cookie9", "softBoom", "clover4", "gem", "cookie12", "heart", "gem"]

    parent: T.Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(860, parent ? parent.width - 48 : 860)
    height: Math.min(640, parent ? parent.height - 48 : 640)
    modal: true
    focus: true
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
    padding: 0
    // drawn in the window: no window, render thread or buffers of its own
    popupType: T.Popup.Item


    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Appearance.duration(150) }
        NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: Appearance.motion(380); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.curves.expressiveFastSpatial }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Appearance.duration(120) }
        NumberAnimation { property: "scale"; to: 0.97; duration: Appearance.duration(120) }
    }

    T.Overlay.modal: Rectangle {
        color: Appearance.colors.scrimOverlay
    }

    background: Rectangle {
        radius: Appearance.rounding.large + 8
        color: Appearance.bloodMoon ? Qt.alpha(Appearance.colors.layer0, 0.88)
                                    : Appearance.colors.layer0
        border.width: 1
        border.color: Appearance.bloodMoon ? Qt.rgba(0.95, 0.92, 1, 0.48)
                                           : Appearance.colors.layer0Border

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: Appearance.bloodMoon
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 0.96, 1, 0.12) }
                GradientStop { position: 0.22; color: Qt.rgba(0.76, 0.66, 0.78, 0.035) }
                GradientStop { position: 1; color: Qt.rgba(0.07, 0.004, 0.018, 0.2) }
            }
        }

        Rectangle {
            x: 10
            y: 1
            width: parent.width - 20
            height: 1
            radius: 1
            visible: Appearance.bloodMoon
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.18; color: Qt.rgba(1, 1, 1, 0.72) }
                GradientStop { position: 0.82; color: Qt.rgba(1, 0.8, 0.88, 0.5) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    contentItem: Item {
        // the window's own close shortcut puts the settings away first
        Shortcut {
            sequences: [StandardKey.Close]
            enabled: root.opened
            onActivated: root.close()
        }

        // a short window can't fit every destination, so the rail scrolls
        Flickable {
            id: railScroller
            objectName: "settingsRail"
            x: 12
            width: 104
            height: parent.height
            contentHeight: rail.implicitHeight + 32
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height
            clip: true

            ScrollBar.vertical: StyledScrollBar {}

            Column {
                id: rail
                y: 16
                width: railScroller.width
                spacing: 4

                Repeater {
                    model: root.titles.length

                    delegate: RippleButton {
                        id: destination

                        required property int index
                        readonly property bool selected: root.page === index

                        width: rail.width
                        implicitHeight: 64
                        padding: 0
                        colBackground: "transparent"
                        colBackgroundHover: "transparent"
                        rippleEnabled: false
                        onClicked: root.page = index

                        contentItem: Column {
                            spacing: 4

                            // the selection is a pill behind the icon, which grows in
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 56
                                height: 32
                                radius: height / 2
                                color: Qt.alpha(Appearance.colors.layer1Hover, !destination.selected && destination.hovered ? 1 : 0)

                                Behavior on color {
                                    ElementMoveFastColor {}
                                }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    Reveal.shown: !destination.selected
                                    text: root.symbols[destination.index]
                                    iconSize: 22
                                    color: Appearance.colors.onSurfaceVariant
                                }
                                ShapeIcon {
                                    anchors.centerIn: parent
                                    Reveal.shown: destination.selected
                                    Reveal.overshoot: 2.4
                                    size: 38
                                    iconSize: 20
                                    shape: root.shapes[destination.index]
                                    symbol: root.symbols[destination.index]
                                    hovered: destination.hovered
                                }
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: rail.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: root.titles[destination.index]
                                font.pixelSize: Appearance.fontSize.smaller
                                font.weight: destination.selected ? Font.DemiBold : Font.Normal
                                color: destination.selected ? Appearance.colors.onSurface : Appearance.colors.onSurfaceVariant
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.left: railScroller.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            radius: Appearance.rounding.large
            color: Appearance.bloodMoon ? Qt.alpha(Appearance.colors.layer1, 0.68)
                                        : Appearance.colors.layer1
            border.width: Appearance.bloodMoon ? 1 : 0
            border.color: Appearance.bloodMoon ? Qt.rgba(0.92, 0.89, 0.97, 0.3)
                                               : "transparent"

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: Appearance.bloodMoon
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 0.95, 1, 0.08) }
                    GradientStop { position: 0.42; color: Qt.rgba(0.62, 0.05, 0.13, 0.025) }
                    GradientStop { position: 1; color: Qt.rgba(0.06, 0.004, 0.015, 0.16) }
                }
            }

            // each page's own scatter of faint shapes, kept inside the card
            // and its rounding
            Stickers {
                anchors.fill: parent
                anchors.margins: 6
                key: root.titles[root.page]
                count: 4
                minimumSize: 90
                maximumSize: 220
                clipRadius: Appearance.rounding.large - 6
                visible: !Appearance.bloodMoon
            }

            Flickable {
                id: scroller
                anchors.fill: parent
                anchors.margins: 20
                contentHeight: pages.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                SettingsPages {
                    id: pages
                    width: scroller.width
                    page: root.page

                    // a page arrives from a little below, as end4's pages do
                    onPageChanged: {
                        scroller.contentY = 0
                        if (!Appearance.performanceMode) {
                            arrive.restart()
                        }
                    }

                    ParallelAnimation {
                        id: arrive
                        NumberAnimation { target: pages; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                        NumberAnimation { target: pages; property: "y"; from: 16; to: 0; duration: Appearance.motion(380); easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.curves.emphasizedDecel }
                    }
                }

                ScrollBar.vertical: StyledScrollBar {}
            }
        }

        ToolbarButton {
            anchors.top: parent.top
            anchors.topMargin: 18
            anchors.right: parent.right
            anchors.rightMargin: 18
            z: 2
            shape: "cookie6"
            symbol: "close"
            onClicked: root.close()
            tooltip: qsTr("Close")
        }
    }
}
