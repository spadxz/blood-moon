pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// a title in end4's manner, set in the installed ColorOS family for Blood Moon.
StyledText {
    /// display, headline or title: the page's name, a hero's, a section's
    property string level: "title"

    font.pixelSize: level === "display" ? Appearance.fontSize.display
                  : level === "headline" ? Appearance.fontSize.headline : Appearance.fontSize.title
    font.weight: Appearance.bloodMoon ? Font.DemiBold : Font.Bold
    font.letterSpacing: Appearance.bloodMoon ? 0.05 : level === "display" ? -0.4 : 0
}
