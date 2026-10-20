pragma ComponentBehavior: Bound
import QtQuick
import Scarlett

// the immersive player's backdrop (ArtworkBackdrop): the cover's palette
// poured into a slow fluid that swells with the bass. the field is drawn
// small, blurred there, and stretched over the window, so the blur costs next
// to nothing and the window-sized pass is one texture read. it redraws at
// 30 hz only while music plays; with the living backdrop off, or reduced
// motion, it is one still frame that changes only with the cover.
Item {
    id: root

    /// the backdrop is on screen, so it may move
    property bool shown: true
    /// the bass as the field swells with it, 0 to about 1; 0 while it holds
    readonly property real bass: flows ? clock.energy.y : 0

    readonly property bool flows: !Appearance.scarlett && Settings.livingBackdrop && !Appearance.reduceMotion
    // the blur radius is the standard deviation, in points; the field is drawn
    // at the scale that makes it about two texels, where a 13-tap blur covers it
    readonly property real sigma: Settings.backdropBlur
    readonly property real renderScale: sigma > 2 ? Math.max(1 / 8, 2 / sigma) : 1
    readonly property size textureSize: Qt.size(Math.max(1, Math.ceil(width * renderScale)),
                                                Math.max(1, Math.ceil(height * renderScale)))

    function shade(index: int): color {
        const palette = PlayerStyle.palette
        return palette.length > 0 ? palette[index % palette.length] : Appearance.colors.primary
    }

    BackdropClock {
        id: clock
        running: root.flows && root.shown && root.visible
        playing: Player.playing
        reactivity: Settings.backdropReactivity
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.scarlett ? "#000000" : "#020203"
    }

    ScarlettBackdrop {
        anchors.fill: parent
        visible: Appearance.scarlett
    }

    ShaderEffect {
        id: field
        anchors.fill: parent
        visible: !Appearance.scarlett

        property size itemSize: Qt.size(width, height)
        // the still field is the moment the mac app picked for it
        property real time: root.flows ? clock.time : 37
        property vector4d energy: root.flows ? clock.energy : Qt.vector4d(0, 0, 0, 0)
        property real lead: root.flows ? clock.lead : 0
        property color c0: root.shade(0)
        property color c1: root.shade(1)
        property color c2: root.shade(2)
        property color c3: root.shade(3)
        property color c4: root.shade(4)

        fragmentShader: "qrc:/shaders/liquid_backdrop.frag.qsb"
    }

    ShaderEffectSource {
        id: fieldTexture
        anchors.fill: parent
        sourceItem: field
        hideSource: true
        visible: false
        smooth: true
        textureSize: root.textureSize
    }

    ShaderEffect {
        id: across
        anchors.fill: parent
        visible: !Appearance.scarlett

        property variant source: fieldTexture
        property vector2d texelStep: Qt.vector2d(1 / root.textureSize.width, 0)
        property real sigma: root.sigma * root.renderScale

        fragmentShader: "qrc:/shaders/backdrop_blur.frag.qsb"
    }

    ShaderEffectSource {
        id: acrossTexture
        anchors.fill: parent
        sourceItem: across
        hideSource: true
        visible: false
        smooth: true
        textureSize: root.textureSize
    }

    ShaderEffect {
        id: down
        anchors.fill: parent
        visible: !Appearance.scarlett

        property variant source: acrossTexture
        property vector2d texelStep: Qt.vector2d(0, 1 / root.textureSize.height)
        property real sigma: root.sigma * root.renderScale

        fragmentShader: "qrc:/shaders/backdrop_blur.frag.qsb"
    }

    ShaderEffectSource {
        id: blurred
        anchors.fill: parent
        sourceItem: down
        hideSource: true
        visible: false
        smooth: true
        textureSize: root.textureSize
    }

    ShaderEffect {
        anchors.fill: parent
        visible: !Appearance.scarlett

        property variant source: blurred

        fragmentShader: "qrc:/shaders/backdrop_composite.frag.qsb"
    }
}
