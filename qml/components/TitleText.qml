pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// a title in end4's manner: Google Sans Flex's variable axes give headings a
// rounded display face. Blood Moon uses a finer, narrower setting inspired by
// ColorOS typography.
StyledText {
    /// display, headline or title: the page's name, a hero's, a section's
    property string level: "title"

    font.pixelSize: level === "display" ? Appearance.fontSize.display
                  : level === "headline" ? Appearance.fontSize.headline : Appearance.fontSize.title
    font.weight: Appearance.bloodMoon ? Font.DemiBold : Font.Bold
    font.letterSpacing: Appearance.bloodMoon ? -0.15 : level === "display" ? -0.4 : 0
    font.variableAxes: Appearance.roundedFontAxes
}
