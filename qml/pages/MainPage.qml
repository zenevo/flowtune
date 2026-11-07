import QtQuick 2.0
import Sailfish.Silica 1.0
import FlowTune 1.0
import QtGraphicalEffects 1.0
import "dateandtime.js" as DT

Page {
    id: root
    // The landscape cover flow owns the whole screen (all swipes go to the
    // carousel), so the system back gesture is disabled there.
    backNavigation: !appWindow.deviceLandscape
    property bool loaded: false
    // was referenced all over this page but never defined
    property bool isPortrait: height >= width

    allowedOrientations: appWindow.pagesOrientations
    // no animated size change between orientations (it made the list briefly
    // narrower than the screen when rotating back to portrait)
    defaultOrientationTransition: Transition {}
    // black page background in landscape: hides the theme background while the
    // compositor rotates the window
    backgroundColor: appWindow.deviceLandscape ? "black" : Theme.rgba(palette.overlayBackgroundColor, 0)

    canNavigateForward: database.loaded

    onStatusChanged: {
        if (status===PageStatus.Active) {
            console.log("CURRENT: " + lastGroup)
        }
    }

    property bool showSearch: false
    property string searchValue: ""
    property bool enableSearch: false

    function searchData(text) {
        searchValue = text
        misdatos.setFilter(searchValue)
        enableSearch = false
        //searchInput.text = text
        //searchInput2.text = text
    }


    Timer {
        id: artistPhotoReload
        interval: 600
        onTriggered: if (lastGroup === "artists") misdatos.loadArtists()
    }

    Connections {
        target: coversearch
        onArtistPhotoSaved: artistPhotoReload.restart()
    }

    // Landscape (album section): the cover flow replaces the list.
    LandscapeFlowPanel {
        anchors.fill: parent
        z: 500
        // only the albums section uses the landscape cover flow
        active: appWindow.deviceLandscape && lastGroup === "albums"
        // visibility and the fade/zoom-in are handled inside the panel

        onAlbumActivated: pageStack.push("SongListView.qml",
                                         {"artist": artist, "album": album, "artistcount": acount})
    }

    SilicaFlickable {
        id: mainPanel
        visible: !appWindow.deviceLandscape
        anchors.fill: parent

        PullDownMenu {
            visible: root.isPortrait

            MenuItem {
                visible: lastGroup === "artists"
                text: qsTr("Download artist photos")
                onClicked: {
                    for (var i = 0; i < misdatos.count; ++i) {
                        var nm = misdatos.titleAt(i)
                        if (nm && nm.length > 0)
                            coversearch.fetchArtistPhoto(nm)
                    }
                }
            }
            MenuItem {
                text: showSearch? qsTr("Hide search field") : qsTr("Show search field")
                onClicked: {
                    if (searchValue!="") {
                        searchValue = ""
                        misdatos.setFilter(searchValue)
                    }
                    showSearch = !showSearch
                    enableSearch = false
                }
            }
        }

        Loader {
            id: loaderpage
            anchors.fill: parent
            // Portrait uses grid/list only (the cover flow is a landscape view);
            // rotating to landscape switches to the cover flow automatically.
            sourceComponent: utils.viewmode=="list" ? viewmodeList : viewmodeGrid

        }

        ViewPlaceholder {
            enabled: misdatos.count===0 && database.loaded
            flickable: mainPanel
            text: qsTr("No music")
        }

    }


    Component {
        id: viewmodeList

        SilicaListView {
            id: listView

            anchors.fill: parent

            enabled: database.loaded? 1 : 0
            opacity: enabled? 1 : 0
            Behavior on opacity { FadeAnimation {} }

            section.property: currentListOrder=="artist" && lastGroup==="albums"? "band" : "title"
            section.criteria: currentListOrder=="artist" && lastGroup==="albums"? ViewSection.FullString : ViewSection.FirstCharacter
            section.delegate: SectionHeader { text: section }

            model: misdatos

            header: Item {
                height: head2.height + search2.height
                width: parent.width

                Header {
                    id: head2
                    title: lastGroup==="artists"? qsTr("Artists") : qsTr("Albums")
                }

                Item {
                    id: search2
                    width: parent.width
                    anchors.top: head2.bottom
                    height: showSearch? searchInput2.height : 0
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad; property: "height" } }
                    onHeightChanged: listView.positionViewAtBeginning()
                    clip: true

                    TextField {
                        id: searchInput2
                        anchors.bottom: parent.bottom
                        width: parent.width - sbutton2.width
                        //placeholderText: qsTr("Search")
                        inputMethodHints: Qt.ImhNoPredictiveText
                        //enabled: showSearch
                        //onEnabledChanged: text = ""
                        //focus: enabled
                        //visible: opacity > 0
                        opacity: showSearch ? 1 : 0
                        Behavior on opacity { FadeAnimation { duration: 200 } }
                        onTextChanged: enableSearch = searchInput2.text!==searchValue
                        EnterKey.enabled: enableSearch && searchInput2.text!==""
                        EnterKey.onClicked: searchData(searchInput2.text)
                    }

                    Connections {
                        target: misdatos
                        onLoadChanged: searchInput2.text = searchValue
                    }

                    IconButton {
                        id: sbutton2
                        smooth: true
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingMedium
                        height: Theme.itemSizeExtraSmall
                        width: height
                        icon.source: enableSearch && searchInput2.text!==""? "image://theme/icon-m-search" : "image://theme/icon-m-cancel"
                        icon.height: height -Theme.paddingMedium
                        icon.width: icon.height
                        enabled: searchInput2.text!=="" || searchValue!==""
                        onClicked: {
                            if (!enableSearch)
                                searchInput2.text = ""
                            searchData(searchInput2.text)
                        }
                    }
                }
            }

            delegate: AlbumDelegate {
                contentHeight: Theme.itemSizeMedium
                width: parent.width

                myData: model
                name: replaceText(model.title, searchValue)
                desc: replaceText(lastGroup=="albums"? model.band : model.artist, searchValue)
                img: model.coverart
                count: model.acount
                time: model.songs

                onClicked: {
                    if (lastGroup==="albums")
                        pageStack.push("SongListView.qml", {"artist":model.artist, "album":model.title, "artistcount":model.acount})
                    else
                        pageStack.push("AlbumListView.qml", {"artist":model.title})
                }
            }
        }
    }

    Component {
        id: viewmodeGrid

        SilicaGridView {
            id: gridView

            anchors.fill: parent

            enabled: database.loaded? 1 : 0
            opacity: enabled? 1 : 0
            Behavior on opacity { FadeAnimation {} }

            cellWidth: appWindow._screenWidth<appWindow._screenHeight? appWindow._screenWidth/3 : appWindow._screenWidth/5
            cellHeight: cellWidth
            cacheBuffer: 3000

            model: misdatos

            header: Item {
                height: head.height + search.height
                width: parent.width

                Header {
                    id: head
                    title: lastGroup==="artists"? qsTr("Artists") : qsTr("Albums")
                }

                Item {
                    id: search
                    anchors.top: head.bottom
                    width: parent.width
                    height: showSearch? searchInput.height : 0
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad; property: "height" } }
                    onHeightChanged: gridView.positionViewAtBeginning()
                    clip: true

                    TextField {
                        id: searchInput
                        anchors.bottom: parent.bottom
                        width: parent.width - sbutton.width
                        //placeholderText: qsTr("Search")
                        inputMethodHints: Qt.ImhNoPredictiveText
                        //enabled: showSearch
                        //onEnabledChanged: text = ""
                        //focus: enabled
                        //visible: opacity > 0
                        opacity: showSearch ? 1 : 0
                        Behavior on opacity { FadeAnimation { duration: 200 } }
                        onTextChanged: enableSearch = searchInput.text!==searchValue
                        EnterKey.enabled: enableSearch && searchInput.text!==""
                        EnterKey.onClicked: searchData(searchInput.text)
                    }

                    Connections {
                        target: misdatos
                        onLoadChanged: searchInput.text = searchValue
                    }

                    IconButton {
                        id: sbutton
                        smooth: true
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingMedium
                        height: Theme.itemSizeExtraSmall
                        width: height
                        icon.source: enableSearch && searchInput.text!==""? "image://theme/icon-m-search" : "image://theme/icon-m-cancel"
                        icon.height: height -Theme.paddingMedium
                        icon.width: icon.height
                        enabled: searchInput.text!=="" || searchValue!==""
                        onClicked: {
                            if (!enableSearch)
                                searchInput.text = ""
                            searchData(searchInput.text)
                        }
                    }
                }
            }

            delegate: CoverArtList {
                id: cvl
                height: gridView.cellHeight
                width: gridView.cellWidth
                itemimg: model.coverart
                text: model.title
                artist: model.artist
                album: model.title
                textvisible: lastGroup==="artists"

                onClicked: {
                    if (lastGroup==="albums")
                        pageStack.push("SongListView.qml", {"artist":model.artist, "album":model.title, "artistcount":model.acount})
                    else
                        pageStack.push("AlbumListView.qml", {"artist":model.title})
                }
            }
        }
    }


    Component {
        id: viewmodeFlow

        CoverFlow {
            id: view

            anchors.fill: parent
            enabled: database.loaded? 1 : 0
            opacity: enabled? 1 : 0
            Behavior on opacity { FadeAnimation {} }

            topMargin: root.isPortrait? Theme.paddingLarge*2 : Theme.paddingLarge*2

            onItemClicked: {
                var d = item.myData
                if (lastGroup==="albums")
                    pageStack.push("SongListView.qml", {"artist": d.artist, "album": d.title, "artistcount": d.acount})
                else
                    pageStack.push("AlbumListView.qml", {"artist": d.title})
            }

            model: misdatos
            clip: true
            currentIndex: 0

            Connections {
                target: misdatos

                onLoadChanged: {
                    if (misdatos.loaded && misdatos.count>0) {
                        console.log("LOAD CHANGED!!!!!!")
                        if (lastGroup=="albums") {
                            label1.text = currentItem.myData.acount==="1" ? currentItem.myData.artist : qsTr("Various artists")
                            label2.text = currentItem.myData.title
                        } else {
                            label1.text = currentItem.myData.title
                            label2.text = currentItem.myData.artist
                        }
                    }
                    view.resetIndex()
                }
            }

            delegate: Item {
                id: item
                property variant myData: model
                property string artist: model.artist
                property string album: model.title
                property string acount: model.acount

                x: view.xFor(index)
                z: view.zFor(index)
                scale: view.scaleFor(index)
                visible: view.visibleFor(index)
                // Bigger covers on large screens: use most of the screen width
                // (was Theme.itemSizeExtraLarge*2, which looked small on 1080p).
                width: Math.min(root.width * 0.62, root.width * (root.isPortrait ? 0.62 : 0.46), root.height * 0.44)
                height: root.isPortrait? width*2 : width*1.5
                //property alias imageSource: dlgImg.source

                Column  {
                    id: delegate
                    y: view.topMargin
                    spacing: 0

                    Rectangle {
                        id: delegateImage

                        width: item.width
                        height: width
                        color: (dlgImg.status === Image.Ready) ? "black" : "transparent"

                        z: reflection.z + 1

                        CoverArtList {
                            //cache: false
                            id: dlgImg
                            itemimg: model.coverart==="loading" ? "" : model.coverart
                            itemwidth: item.width
                            itemheight: itemwidth
                            artist: model.artist
                            album: model.title
                            anchors.centerIn: parent
                            text: model.title
                            clip: true
                            showBorder: true
                            //fillMode: Image.Stretch
                        }
                    }

                    Item {
                        id: reflection
                        width: item.width
                        height: item.height

                        Rectangle {
                            id: mask
                            width: item.width
                            height: width
                            visible: false
                            gradient: Gradient {
                                GradientStop { position: 0.25; color: "transparent" }
                                GradientStop { position: 1.0; color: "black" }
                            }

                        }

                        CoverArtList {
                            id: imgtomask
                            itemwidth: item.width
                            itemheight: itemwidth
                            anchors.centerIn: parent
                            artist: model.artist
                            album: model.title
                            clip: true
                            itemimg: model.coverart==="loading" ? "" : model.coverart
                            text: model.title
                            visible: false
                            showBorder: true
                            //fillMode: Image.Stretch
                        }

                        OpacityMask {
                            anchors.fill: imgtomask
                            source: imgtomask
                            maskSource: mask
                            opacity: 0.75
                            transform : Rotation {
                                origin {
                                  x: item.width / 2
                                  y: root.isPortrait? item.width / 3.97 : item.width / 2.68
                                }

                                axis {x: 1; y: 0; z: 0}
                                angle: 180
                            }
                        }
                    }
                }


                opacity: view.opacityFor(index)

                transform: Rotation {
                    origin.x: item.width / 2
                    origin.y: item.width / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: view.angleFor(index)
                }

                states: [
                    State {
                        name: "scaled"
                        PropertyChanges {
                            target: delegateImage
                            scale: 1.8
                        }
                    }
                ]

                transitions: [
                    Transition {
                        from: ""
                        to: "scaled"
                        reversible: true
                        ParallelAnimation {
                            PropertyAnimation {
                                target: delegateImage
                                properties: "scale"
                                duration: 300
                            }
                        }
                    }
                ]

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        view.currentIndex = model.index
                        if (lastGroup==="albums")
                            pageStack.push("SongListView.qml", {"artist":model.artist, "album":model.title, "artistcount":model.acount})
                        else
                            pageStack.push("AlbumListView.qml", {"artist":model.title})
                    }
                    /*onPressAndHold: {

                    }*/

                }

            }

            onCurrentIndexChanged: {
                if (lastGroup=="albums") {
                    label1.text = currentItem.myData.acount==="1" ? currentItem.myData.artist : qsTr("Various artists")
                    label2.text = currentItem.myData.title
                } else {
                    label1.text = currentItem.myData.title
                    label2.text = currentItem.myData.artist
                }
            }

            Column {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: myPlayer.state>0 ? Theme.paddingMedium : Theme.paddingLarge
                width: parent.width
                spacing: myPlayer.state>0 ? 0 : Theme.paddingMedium

                Label {
                    id: label1
                    //text: view.currentItem.myData.acount==="1" ? view.currentItem.myData.artist : qsTr("Various artists")
                    width: parent.width - Theme.paddingLarge*2
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.highlightColor
                    truncationMode: TruncationMode.Fade
                    horizontalAlignment: Text.AlignHCenter
                    visible: view.visible
                }
                Label {
                    id: label2
                    //text: view.currentItem.myData.title
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width - Theme.paddingLarge*2
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.primaryColor
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    visible: view.visible
                }

            }

        }
    }



}

