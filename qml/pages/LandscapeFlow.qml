import QtQuick 2.0
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import FlowTune 1.0

// Global landscape cover flow: shown over every page (except Settings) when the
// device is rotated to landscape. Always shows every album in the library.
Item {
    id: root

    signal albumActivated(string artist, string album, string acount)

    property string artistText
    property string albumText

    // Reference layout: exactly what the cover flow looks like on the 5T in
    // landscape (2160x1080, 670 px covers). Everything is scaled uniformly from
    // this design so other resolutions keep the same proportions.
    readonly property size designSize: Qt.size(2160, 1080)
    readonly property real uiScale: Math.min(width / designSize.width,
                                             height / designSize.height)

    Datos {
        id: allAlbums
    }

    function reload() {
        if (database.loaded)
            allAlbums.loadAlbums(utils.order)
    }

    // The flow delegates are created once and stay alive while covers are
    // downloaded, so replacing a cover file on disk does not refresh them by
    // itself. Bump a token (debounced, bulk downloads emit one signal per
    // cover) and every delegate re-reads its image.
    property int coverRevision: 0

    Timer {
        id: coverRefresh
        interval: 700
        repeat: false
        onTriggered: root.coverRevision++
    }

    Connections {
        target: coversearch
        onImageChanged: coverRefresh.restart()
    }

    Connections {
        target: missing
        onAlbumCoverChanged: coverRefresh.restart()
    }

    Connections {
        target: lfm
        onBioImageChanged: coverRefresh.restart()
    }

    Component.onCompleted: reload()

    Connections {
        target: database
        onLoadChanged: if (database.loaded) root.reload()
    }

    CoverFlow {
        id: flow
        anchors.fill: parent
        model: allAlbums
        clip: true
        currentIndex: 0
        itemWidth: 670 * root.uiScale

        onItemClicked: {
            var d = item.myData
            root.albumActivated(d.artist, d.title, d.acount)
        }

        Connections {
            target: allAlbums
            onLoadChanged: {
                if (allAlbums.loaded) {
                    flow.resetIndex()
                    var it = flow.currentItem
                    if (it && it.myData) {
                        root.artistText = (it.myData.acount === "1") ? it.myData.artist : qsTr("Various artists")
                        root.albumText = it.myData.title
                    }
                }
            }
        }

        delegate: Item {
            id: item
            property variant myData: model
            property string artist: model.artist
            property string album: model.title
            property string acount: model.acount

            x: flow.xFor(index)
            // the box contains only the front cover and is centred on the
            // screen; the reflection hangs below it (overflowing the box)
            anchors.verticalCenter: flow.verticalCenter
            z: flow.zFor(index)
            scale: flow.scaleFor(index)
            visible: flow.visibleFor(index)
            // the delegate box is just the cover: it is what gets centred.
            // the reflection hangs below it and may overflow the box.
            width: flow.itemWidth
            height: width

            Rectangle {
                id: delegateImage
                width: item.width
                height: width
                color: (dlgImg.status === Image.Ready) ? "black" : "transparent"

                CoverArtList {
                    id: dlgImg
                    itemimg: model.coverart==="loading" ? "" : model.coverart
                    refreshToken: root.coverRevision
                    itemwidth: item.width
                    itemheight: itemwidth
                    artist: model.artist
                    album: model.title
                    anchors.centerIn: parent
                    text: model.title
                    clip: true
                    showBorder: true
                }
            }

            // mirrored reflection hanging under the cover (opaque where it
            // touches the cover, fading to black towards the bottom)
            Item {
                id: reflection
                y: item.width + 2
                width: item.width
                height: item.width * 0.55
                clip: true

                Item {
                    id: srcCover
                    width: item.width
                    height: item.width
                    visible: false

                    CoverArtList {
                        id: reflCover
                        itemwidth: item.width
                        itemheight: item.width
                        artist: model.artist
                        album: model.title
                        itemimg: model.coverart==="loading" ? "" : model.coverart
                        refreshToken: root.coverRevision
                        text: model.title
                        showBorder: true
                        anchors.centerIn: parent
                    }
                }

                Rectangle {
                    id: reflMask
                    width: item.width
                    height: item.width
                    visible: false
                    // alpha mask: after the 180 degree flip the opaque end is at
                    // the top (touching the cover); the fade covers ~70% of the
                    // visible reflection and then stays fully transparent.
                    gradient: Gradient {
                        GradientStop { position: 0.000; color: "#00ffffff" }
                        GradientStop { position: 0.615; color: "#00ffffff" }
                        GradientStop { position: 0.740; color: "#1affffff" }
                        GradientStop { position: 0.850; color: "#66ffffff" }
                        GradientStop { position: 0.920; color: "#b3ffffff" }
                        GradientStop { position: 1.000; color: "#ffffffff" }
                    }
                }

                OpacityMask {
                    width: item.width
                    height: item.width
                    source: srcCover
                    maskSource: reflMask
                    transform: Rotation {
                        origin.x: item.width / 2
                        origin.y: item.width / 2
                        axis { x: 1; y: 0; z: 0 }
                        angle: 180
                    }
                }
            }

            transform: Rotation {
                origin.x: item.width / 2
                origin.y: item.width / 2
                axis { x: 0; y: 1; z: 0 }
                angle: flow.angleFor(index)
            }
        }
    }

    // current album labels (white on black; artist bold)
    Column {
        id: infoColumn
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge * root.uiScale
        }
        spacing: Theme.paddingSmall * root.uiScale

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.artistText
            color: "white"
            font.bold: true
            font.pixelSize: Theme.fontSizeMedium * root.uiScale
            horizontalAlignment: Text.AlignHCenter
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.albumText
            color: "white"
            font.pixelSize: Theme.fontSizeSmall * root.uiScale
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Connections {
        target: flow
        onCurrentIndexChanged: {
            var it = flow.currentItem
            if (it && it.myData) {
                var d = it.myData
                root.artistText = (d.acount === "1") ? d.artist : qsTr("Various artists")
                root.albumText = d.title
            }
        }
    }
}
