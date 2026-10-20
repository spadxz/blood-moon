pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import Swiftify

T.MenuSeparator {
    id: root

    property MaterialScheme scheme: UiState.immersiveOpen ? PlayerStyle.darkScheme : Appearance.colors

    topPadding: 4
    bottomPadding: 4
    leftPadding: 8
    rightPadding: 8
    contentItem: Item {
        implicitHeight: 1
        Rectangle {
            anchors.fill: parent
            visible: Appearance.bloodMoon
            color: root.scheme.outlineVariant
            opacity: 0.55
        }
        WavyLine {
            anchors.fill: parent
            visible: !Appearance.bloodMoon
            color: root.scheme.outlineVariant
            amplitude: 1.4
            wavelength: 12
        }
    }
}
