import QtQuick 2.0
import Lomiri.Components 1.3 as UITK
import io.thp.pyotherside 1.5

UITK.Page {
    property string username
    property string karma
    property string submission_count
    property string comment_count
    property string about
    property bool loaded: false
    header: UITK.PageHeader {
        id: header
        title: username + "'s profile"
        leadingActionBar.actions: [
            UITK.Action {
                iconName: "back"
                text: "Back"
                onTriggered: {
                    stack.pop()
                }
            }
        ]
    }
    UITK.ActivityIndicator {
        running: !loaded
        visible: !loaded
        anchors.centerIn: parent
    }

    Column {
        visible: loaded
        anchors.fill: parent
        anchors.margins: units.gu(2)
        anchors.topMargin: header.height + anchors.margins

        Text {
            text: "Karma: " + karma
        }
        Text {
            text: "Submitted: " + submission_count
        }
        Text {
            text: "Comments: " + comment_count
        }

        TextEdit {
            readOnly: true
            textFormat: TextEdit.RichText
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.WordWrap
            visible: about && about.length
            text: "About:<br/>" + about
        }
    }
    Python {

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'))
            importModule('example', function () {
                call("example.get_user_profile", [username], function (u) {
                    loaded = true
                    karma = u.karma
                    submission_count = u.submission_count
                    comment_count = u.comment_count
                    about = u.about
                })
            })
            setHandler('fail', function (msg) {
                toast.show('Failed to fetch thread: ' + msg)
                loading = false
            })
        }
    }
}
