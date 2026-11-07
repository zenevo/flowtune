import QtQuick 2.0
import Sailfish.Silica 1.0

// Landscape cover flow panel used by the album and tracks pages.
//
// The panel owns its own appearance animation: the black backdrop fades in
// first, then the covers fade/zoom in. On the way out the covers fade first and
// the backdrop follows, so there is no black flash.
Item {
    id: panel

    signal albumActivated(string artist, string album, string acount)

    property bool active: appWindow.deviceLandscape

    property real backdropOpacity: 0
    property real contentOpacity: 0
    property real contentScale: 0.94

    visible: backdropOpacity > 0.001 || contentOpacity > 0.001

    states: State {
        name: "on"
        when: panel.active
        PropertyChanges {
            target: panel
            backdropOpacity: 1
            contentOpacity: 1
            contentScale: 1.0
        }
    }

    transitions: [
        Transition {
            to: "on"
            SequentialAnimation {
                // instant: hide the rotating application UI right away
                NumberAnimation {
                    target: panel; property: "backdropOpacity"
                    to: 1; duration: 1
                }
                PauseAnimation { duration: 110 }
                ParallelAnimation {
                    NumberAnimation {
                        target: panel; property: "contentOpacity"
                        to: 1; duration: 560; easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: panel; property: "contentScale"
                        to: 1; duration: 650; easing.type: Easing.OutCubic
                    }
                }
            }
        },
        Transition {
            from: "on"
            // exit without animation (instant hide)
            SequentialAnimation {
                NumberAnimation { target: panel; property: "contentOpacity"; to: 0; duration: 1 }
                NumberAnimation { target: panel; property: "backdropOpacity"; to: 0; duration: 1 }
            }
        }
    ]

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: panel.backdropOpacity
    }

    LandscapeFlow {
        anchors.fill: parent
        opacity: panel.contentOpacity
        scale: panel.contentScale
        transformOrigin: Item.Center
        onAlbumActivated: panel.albumActivated(artist, album, acount)
    }
}
