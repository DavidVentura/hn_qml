import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import Ubuntu.Components 1.3 as UITK
import io.thp.pyotherside 1.3
import "../components"

UITK.Page {
    property bool displayComment: true

    property alias c_id: comment.c_id
    property alias c_markup: comment.c_markup
    property alias c_age: comment.c_age
    property alias c_author: comment.c_author

    header: UITK.PageHeader {
        title: 'Reply to ' + c_author
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

    Column {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: units.gu(2)
        spacing: units.gu(2)
        Comment {
            visible: displayComment
            id: comment
            c_depth: 0
            optionsVisible: false
        }

        UITK.TextArea {
            id: reply
            anchors.left: parent.left
            anchors.right: parent.right
            Layout.fillHeight: true
        }
        UITK.Button {
            text: "Submit"
            anchors.right: parent.right
            onClicked: {
                enabled = false
                python.call('example.send_reply', [c_id, reply.text],
                            function (success, message) {
                                if (!success) {
                                    enabled = true
                                    toast.show(message)
                                    return
                                }
                                toast.show("Successfully replied. Reload to see the comment.")
                                stack.pop()
                            })
            }
        }
    }
    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'))
            importModule('example', function () {})
        }
    }
}
