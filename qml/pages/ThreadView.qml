import QtQuick 2.7
import QtQuick.Layouts 1.12
import io.thp.pyotherside 1.5
import Ubuntu.Components 1.3

Page {
    property variant barColor: ['#f44336', '#d500f9', '#304ffe', '#0288d1', '#26A69A', '#00c853', '#fff3e0', '#8d6e63']
    property string pageTitle: '..'
    header: PageHeader {
        id: header
        title: pageTitle
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: "Back"
                onTriggered: {
                    stack.pop()
                }
            }
        ]
    }

    ListView {
        anchors.leftMargin: units.gu(0.5)
        anchors.rightMargin: units.gu(0.5)
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: units.gu(0.3)
        model: ListModel {
            id: listModel
        }

        delegate: Row {
            id: comment
            anchors.leftMargin: depth * units.gu(0.5)
            anchors.left: parent.left
            anchors.right: parent.right

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: units.gu(0.3)
                color: barColor[depth % 8]
            }
            Rectangle {

                width: parent.width
                height: childrenRect.height
                color: '#f6f6ef'

                Text {
                    wrapMode: Text.WordWrap
                    text: markup
                    padding: units.gu(1)
                    width: parent.width
                    textFormat: Qt.RichText
                    onLinkActivated: Qt.openUrlExternally(link)
                }
            }
        }
    }

    function loadThread(story_id, title, url, kids) {
        pageTitle = title
        url = url
        loadKids(story_id, kids, 0)
    }

    function loadKids(thread_id, kids, depth) {
        if (depth === 0) {
            console.log("Unloading..")
            listModel.clear()
        }

        console.log("Loading thread", thread_id, depth)
        var insertPosition = indexOfComment(thread_id) + 1

        for (var k in kids) {
            listModel.insert(insertPosition, {
                                 "depth": depth,
                                 "thread_id": thread_id.toString(),
                                 "markup": "...",
                                 "comment_id": kids[k].toString()
                             })
            insertPosition += 1
        }
        for (k in kids) {
            console.log("Loading kid", kids[k])
            python.call("example.get_comment_and_submit",
                        [thread_id, kids[k], depth], function () {})
        }
    }
    function populateComment(comment) {
        updateComment(comment)
        loadKids(comment.comment_id, comment.kids, comment.depth + 1)
    }

    function indexOfComment(comment_id) {
        for (var i = 0; i < listModel.count; i++) {
            if (comment_id === listModel.get(i).comment_id) {
                return i
            }
        }
        return -1
    }

    function updateComment(comment) {
        const idx = indexOfComment(comment.comment_id)
        listModel.set(idx, comment)
    }

    Python {
        id: python

        Component.onCompleted: {

            //addImportPath(Qt.resolvedUrl('../src/'))
            setHandler('comment-pop', populateComment)
        }
    }
}
