import QtQuick 2.0

// Replacement for com.jolla.mediaplayer's MediaKey, so that FlowTune does not
// need the jolla-mediaplayer package. The original type grabbed one media key
// while it was enabled; Shortcut does the same at window level, which is what
// the page already acquired through Resource.HeadsetButtons.
Item {
    id: mediaKey

    property bool enabled: false
    property int key: 0

    signal pressed()
    signal released()
    signal repeat()

    visible: false
    width: 0
    height: 0

    readonly property string keySequence: {
        switch (key) {
        case Qt.Key_MediaTogglePlayPause: return "MediaTogglePlayPause"
        case Qt.Key_MediaPlay: return "MediaPlay"
        case Qt.Key_MediaPause: return "MediaPause"
        case Qt.Key_MediaStop: return "MediaStop"
        case Qt.Key_MediaNext: return "MediaNext"
        case Qt.Key_MediaPrevious: return "MediaPrevious"
        case Qt.Key_ToggleCallHangup: return "ToggleCallHangup"
        default: return ""
        }
    }

    Shortcut {
        enabled: mediaKey.enabled && mediaKey.keySequence.length > 0
        sequence: mediaKey.keySequence
        context: Qt.WindowShortcut
        onActivated: {
            mediaKey.pressed()
            mediaKey.released()
        }
    }
}
