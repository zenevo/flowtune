import QtQuick 2.0
import Sailfish.Silica 1.0
import FlowTune 1.0

// CoverFlow implemented after iCarousel's iCarouselTypeCoverFlow transform:
//   tilt = 0.9, spacing = 0.25 (in item widths), perspective m34 = -1/500
//   x     = (clamp(off,-1,1) * 0.5 * tilt + off * spacing) * itemWidth
//   z     = -|clamp(off,-1,1)| * itemWidth * 0.5
//   angle = -clamp(off,-1,1) * PI/2 * tilt   (rotation around Y)
// The perspective is applied with a Matrix4x4 built in matrixFor().
Item {
    id: coverFlow

    property int topMargin: 0
    property var model
    property Component delegate
    property int currentIndex: 0
    property Item currentItem

    // parameters after rit3zh/expo-coverflow-carousel
    property real tilt: 64          // max rotateY in degrees
    property real spacing: 0.2      // stackSpacing = itemWidth * spacing
    property real perspective: 1000 // 3D perspective distance
    property real handoffPower: 1.29
    property real itemWidth: Math.min(width * 0.62, height * 0.62)

    // continuous scroll position, in items
    property real scrollOffset: 0

    signal itemClicked(var item)

    function clampOff(v) { return Math.max(-1.0, Math.min(1.0, v)) }

    function offsetFor(i) { return i - scrollOffset }

    // --- 4x4 helpers (row-major, Qt.matrix4x4 order) ---
    function mul(a, b) {
        var r = new Array(16)
        for (var i = 0; i < 4; i++)
            for (var j = 0; j < 4; j++) {
                var s = 0
                for (var k = 0; k < 4; k++)
                    s += a[i * 4 + k] * b[k * 4 + j]
                r[i * 4 + j] = s
            }
        return r
    }
    function translation(x, y, z) { return [1,0,0,x, 0,1,0,y, 0,0,1,z, 0,0,0,1] }
    function persp() { return [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,perspective,1] }
    function rotY(a) {
        var c = Math.cos(a), s = Math.sin(a)
        return [c,0,s,0, 0,1,0,0, -s,0,c,0, 0,0,0,1]
    }

    function matrixFor(i) {
        var off = offsetFor(i)
        var cl = clampOff(off)
        var tx = (cl * 0.5 * tilt + off * spacing) * itemWidth
        var tz = -Math.abs(cl) * itemWidth * 0.5
        var ang = -cl * Math.PI / 2.0 * tilt
        var w = itemWidth, h = itemWidth
        var m = translation(w / 2, h / 2, 0)
        m = mul(m, persp())
        m = mul(m, translation(tx, 0, tz))
        m = mul(m, rotY(ang))
        m = mul(m, translation(-w / 2, -h / 2, 0))
        return Qt.matrix4x4(m[0],m[1],m[2],m[3], m[4],m[5],m[6],m[7],
                            m[8],m[9],m[10],m[11], m[12],m[13],m[14],m[15])
    }

    function zFor(i) { return 1000 - Math.abs(offsetFor(i)) * 100 }

    // coverflow-carousel style layout (no 3D perspective: plain x/rotate/scale,
    // which renders reliably with the app's clipped cover items)
    function easedFor(i) {
        var d = offsetFor(i)
        var a = Math.min(Math.abs(d), 1.0)
        var pr = 1.0 - Math.pow(1.0 - a, handoffPower)
        return d < 0 ? -pr : pr
    }
    function xFor(i) {
        var d = offsetFor(i)
        var cl = Math.max(-1, Math.min(1, d))
        var tx = easedFor(i) * itemWidth * 0.66 + (d - cl) * itemWidth * 0.2
        return (width - itemWidth) / 2 + tx
    }
    function angleFor(i) { return -easedFor(i) * tilt }
    function scaleFor(i) { return 1.0 - Math.abs(easedFor(i)) * 0.12 }
    function opacityFor(i) {
        var a = Math.abs(offsetFor(i))
        if (a <= 2.4) return 1.0
        if (a >= 3.6) return 0.0
        return 1.0 - (a - 2.4) / 1.2
    }
    function visibleFor(i) { return Math.abs(offsetFor(i)) < 3.6 }

    function setIndex(i, animate) {
        var t = Math.max(0, Math.min(count() - 1, i))
        if (animate) {
            snapAnimation.to = t
            snapAnimation.start()
        } else {
            scrollOffset = t
        }
        currentItem = rep.itemAt(t)
        currentIndex = t
    }
    function count() { return rep.count }
    function resetIndex() { setIndex(0, false) }

    NumberAnimation {
        id: snapAnimation
        target: coverFlow
        property: "scrollOffset"
        duration: 250
        easing.type: Easing.OutCubic
        onStopped: coverFlow.currentIndex = Math.round(coverFlow.scrollOffset)
    }

    Repeater {
        id: rep
        model: coverFlow.model
        delegate: coverFlow.delegate
    }

    MouseArea {
        // Above the delegates (which use large z values for stacking), otherwise
        // their own MouseAreas swallow the drag gestures.
        z: 10000
        anchors.fill: parent
        property real pressX: 0
        property real pressOffset: 0
        property bool dragging: false
        // Sailfish reserves the screen edges for the compositor's back/next
        // gestures; never start a carousel drag inside those zones.
        // Landscape (the dedicated cover flow view) uses the edges for the
        // carousel; portrait keeps them free for the system gestures.
        readonly property real edgeZone: coverFlow.width > coverFlow.height ? 0 : 60
        property bool fromEdge: false
        onPressed: {
            pressX = mouse.x
            pressOffset = coverFlow.scrollOffset
            dragging = false
            fromEdge = (mouse.x < edgeZone || mouse.x > coverFlow.width - edgeZone)
        }
        onPositionChanged: {
            var dx = mouse.x - pressX
            if (!dragging && !fromEdge && Math.abs(dx) > 10)
                dragging = true
            if (dragging) {
                coverFlow.scrollOffset = Math.max(-0.5, Math.min(rep.count - 0.5,
                        pressOffset - dx / (coverFlow.itemWidth * 0.62)))
            }
        }
        onReleased: {
            if (dragging) {
                coverFlow.setIndex(Math.round(coverFlow.scrollOffset), true)
            } else {
                var i = Math.round(coverFlow.scrollOffset)
                var it = rep.itemAt(i)
                if (it)
                    coverFlow.itemClicked(it)
            }
        }

        onCanceled: {
            if (dragging)
                coverFlow.setIndex(Math.round(coverFlow.scrollOffset), true)
            dragging = false
        }
    }

    onCurrentIndexChanged: {
        if (Math.abs(scrollOffset - currentIndex) > 0.01 && !snapAnimation.running) {
            snapAnimation.to = currentIndex
            snapAnimation.start()
        }
    }

    Component.onCompleted: setIndex(0, false)
}
