pragma ComponentBehavior: Bound
import QtQuick
import Scarlett

// a title in end4's manner, set in the installed ColorOS family for Scarlett.
StyledText {
    /// display, headline or title: the page's name, a hero's, a section's
    property string level: "title"

    font.pixelSize: level === "display" ? Appearance.fontSize.display
                  : level === "headline" ? Appearance.fontSize.headline : Appearance.fontSize.title
    font.weight: Appearance.scarlett ? Font.DemiBold : Font.Bold
    font.letterSpacing: Appearance.scarlett ? 0.05 : level === "display" ? -0.4 : 0
}
