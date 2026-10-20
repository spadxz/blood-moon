pragma ComponentBehavior: Bound
import QtQuick
import Scarlett

// The expanded Scarlett control floats above its button so it never covers
// the queue, lyrics, or other player controls. Other themes keep their pill.
Item {
    id: root

    property MaterialScheme scheme: Appearance.colors
    property bool expanded: false
    readonly property string symbol: Player.volume <= 0.01 ? "volume_off"
        : Player.volume <= 0.34 ? "volume_mute"
        : Player.volume <= 0.67 ? "volume_down" : "volume_up"

    implicitWidth: 32
    implicitHeight: 32

    Timer {
        id: closeTimer
        interval: 240
        onTriggered: if (!buttonHover.hovered && !popupHover.hovered) root.expanded = false
    }

    HoverHandler {
        id: buttonHover
        onHoveredChanged: {
            if (hovered) closeTimer.stop();
            else if (Appearance.scarlett && root.expanded) closeTimer.restart();
        }
    }

    // Existing layout for the other themes.
    Rectangle {
        id: pill
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.expanded ? 172 : 32
        height: root.expanded ? 42 : 32
        radius: Appearance.rounding.normal
        color: Qt.alpha(root.scheme.surfaceContainerHighest, root.expanded ? 1 : 0)
        z: 3
        visible: !Appearance.scarlett

        Behavior on width { ElementMoveSmall {} }
        Behavior on height { ElementMoveSmall {} }
        Behavior on color { ElementMoveFastColor {} }

        HoverHandler {
            onHoveredChanged: if (!hovered) root.expanded = false
        }

        StyledSlider {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: legacyButton.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.expanded && pill.width > 100 ? 1 : 0
            visible: opacity > 0
            scheme: root.scheme
            trackThickness: 8
            handleLength: 20
            showStopIndicator: false
            showValueTip: true
            enabled: !Player.volumeManagedBySleepTimer
            value: Player.volume
            onMoved: Player.setVolume(value)
            Behavior on opacity { NumberAnimation { duration: Appearance.duration(150) } }
        }

        IconButton {
            id: legacyButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            size: 32
            iconSize: 20
            symbol: root.symbol
            iconColor: root.expanded ? root.scheme.primary : root.scheme.onSurfaceVariant
            tooltip: root.expanded ? (Player.volume <= 0.01 ? qsTr("Unmute") : qsTr("Mute")) : qsTr("Show Volume")
            onClicked: {
                if (root.expanded) Player.toggleMute();
                else root.expanded = true;
            }
        }
    }

    // A stable button stays in the player row while the glass slider opens
    // above it. This is a separate overlay instead of a sideways extension.
    Rectangle {
        id: popup
        x: root.width - width
        y: -height - 8
        width: 172
        height: 42
        radius: 18
        visible: Appearance.scarlett && root.expanded
        z: 10
        color: Qt.alpha(root.scheme.layer1, 0.92)
        border.width: 1
        border.color: Qt.rgba(0.91, 0.92, 0.98, 0.42)

        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.12) }
            GradientStop { position: 0.55; color: Qt.rgba(0.08, 0.08, 0.10, 0.20) }
            GradientStop { position: 1; color: Qt.rgba(0.32, 0.008, 0.04, 0.15) }
        }

        HoverHandler {
            id: popupHover
            onHoveredChanged: {
                if (hovered) closeTimer.stop();
                else if (root.expanded) closeTimer.restart();
            }
        }

        StyledSlider {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            scheme: root.scheme
            trackThickness: 8
            handleLength: 20
            showStopIndicator: false
            showValueTip: true
            enabled: !Player.volumeManagedBySleepTimer
            value: Player.volume
            onMoved: Player.setVolume(value)
        }
    }

    IconButton {
        id: button
        visible: Appearance.scarlett
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        size: 32
        iconSize: 20
        symbol: root.symbol
        iconColor: root.expanded ? root.scheme.primary : root.scheme.onSurfaceVariant
        tooltip: root.expanded ? (Player.volume <= 0.01 ? qsTr("Unmute") : qsTr("Mute")) : qsTr("Show Volume")
        onClicked: {
            if (root.expanded) Player.toggleMute();
            else root.expanded = true;
        }
    }
}
