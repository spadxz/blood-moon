pragma ComponentBehavior: Bound
import QtQuick
import Scarlett

// end4's elementMoveFast for colours.
ColorAnimation {
    duration: Appearance.duration(200)
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.curves.expressiveEffects
}
