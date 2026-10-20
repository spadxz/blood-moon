pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import Scarlett

// end4's RippleButton: a state-layer background that tints on hover, ripples on
// press and can be toggled. right and middle clicks are reported separately.
T.AbstractButton {
    id: root

    property bool toggled: false
    property MaterialScheme scheme: Appearance.colors
    property real buttonRadius: Appearance.rounding.small
    property real buttonRadiusPressed: buttonRadius
    readonly property real effectiveRadius: root.down ? root.buttonRadiusPressed : root.buttonRadius
    property color colBackground: "transparent"
    property color colBackgroundHover: scheme.layer1Hover
    property color colBackgroundToggled: scheme.primary
    property color colBackgroundToggledHover: scheme.primaryHover
    property color colRipple: scheme.layer1Active
    property color colRippleToggled: scheme.primaryActive
    property bool rippleEnabled: true
    property bool pointingHandCursor: true
    property alias backgroundItem: backgroundRectangle
    /// shown on hover; created only while it is
    property string tooltip
    /// a press contracts the button; a hover adds a barely-there lift.
    property bool bounce: true

    signal secondaryClicked(point position)
    signal middleClicked()

    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    opacity: enabled ? 1 : 0.38
    scale: !bounce ? 1 : down ? 1 - Math.min(0.04, 2 / Math.max(width, 1)) : hovered ? 1.012 : 1

    Behavior on scale {
        NumberAnimation {
            duration: Appearance.reduceMotion ? 0 : Appearance.motion(190)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.curves.expressiveFastSpatial
        }
    }
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)
    padding: 8

    background: Rectangle {
        id: backgroundRectangle

        implicitHeight: 40
        radius: root.effectiveRadius
        color: {
            const rest = root.toggled ? root.colBackgroundToggled : root.colBackground
            const hover = root.toggled ? root.colBackgroundToggledHover : root.colBackgroundHover
            return root.hovered ? Appearance.fadeable(hover, rest) : Appearance.fadeable(rest, hover)
        }
        border.width: root.visualFocus ? 2 : 0
        border.color: root.scheme.secondary

        Behavior on color {
            ElementMoveFastColor {}
        }
        Behavior on radius {
            ElementMoveFast {}
        }

        Ripple {
            id: ripple
            anchors.fill: parent
            cornerRadius: backgroundRectangle.radius
            color: root.toggled ? root.colRippleToggled : root.colRipple
        }
    }

    onPressed: {
        if (rippleEnabled) {
            ripple.start(pressX - leftInset, pressY - topInset)
        }
    }
    onReleased: ripple.release()
    onCanceled: ripple.release()

    // as big as the button, so the tooltip places itself by the button
    Loader {
        anchors.fill: parent
        active: root.tooltip.length > 0 && root.hovered
        sourceComponent: StyledToolTip {
            visible: true
            text: root.tooltip
        }
    }

    HoverHandler {
        cursorShape: root.pointingHandCursor && root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        acceptedButtons: Qt.RightButton | Qt.MiddleButton
        gesturePolicy: TapHandler.WithinBounds
        onTapped: (eventPoint, button) => {
            if (button === Qt.RightButton) {
                root.secondaryClicked(eventPoint.position)
            } else {
                root.middleClicked()
            }
        }
    }
}
