pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// A black, clean backdrop with an original procedural blood moon and a warm
// halo. It uses the same shader in the main window and immersive player.
ShaderEffect {
    id: root

    property size itemSize: Qt.size(width, height)

    fragmentShader: "qrc:/shaders/blood_moon.frag.qsb"
}
