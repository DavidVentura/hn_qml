import QtQuick 2.7
import QtQuick.Layouts 1.12
import io.thp.pyotherside 1.5
import Ubuntu.Components 1.3

Page {
    property variant barColor: ['#f44336', '#d500f9', '#304ffe', '#0288d1', '#26A69A', '#00c853', '#fff3e0', '#8d6e63']
    property string pageTitle: '..'
    property string pageUrl: 'http://example.com'
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
        trailingActionBar.actions: [
            Action {
                iconName: "external-link"
                text: "open in browser"
                onTriggered: {
                    Qt.openUrlExternally(pageUrl)
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
        model: ListModel {
            id: listModel
        }

        delegate: Column {
            anchors.left: parent.left
            anchors.right: parent.right
            height: threadVisible ? childrenRect.height : 0
            Behavior on height {
                NumberAnimation {
                    duration: 200
                }
            }
            // this is instead of using spacing on the ListView
            // so that when items are hidden, the spacing also goes away
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                height: units.gu(0.3)
                color: 'white'
            }
            Row {
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
                    id: commentBody
                    width: parent.width
                    height: childrenRect.height
                    color: '#f6f6ef'
                    Column {
                        padding: units.gu(1)

                        Row {
                            id: commentHeader
                            bottomPadding: units.gu(1.2)
                            Text {
                                text: age
                                font.pointSize: units.gu(0.9)
                                color: '#999'
                            }
                            Text {
                                leftPadding: units.gu(0.8)
                                text: user
                                font.pointSize: units.gu(0.9)
                                font.bold: true
                                color: barColor[depth % 8]
                            }
                        }

                        Text {
                            id: commentText
                            wrapMode: Text.WordWrap
                            text: markup
                            width: commentBody.width - units.gu(1.5)
                            textFormat: Qt.RichText
                            onLinkActivated: Qt.openUrlExternally(link)
                        }
                        Rectangle {
                            visible: kids.count > 0
                            width: commentBody.width
                            height: 20
                            color: 'red'
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    toggleChildCommentsVisibility(comment_id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function loadThread(story_id, title, url, kids) {
        pageTitle = title
        pageUrl = url
        loadKids(story_id, kids, 0)
    }

    function loadKids(thread_id, kids, depth) {
        if (depth === 0) {
            console.log("Unloading..")
            listModel.clear()
        }

        var insertPosition = indexOfComment(thread_id) + 1

        for (var k in kids) {
            listModel.insert(insertPosition, {
                                 "depth": depth,
                                 "thread_id": thread_id.toString(),
                                 "markup": "...",
                                 "comment_id": kids[k].toString(),
                                 "user": "..",
                                 "age": "",
                                 "kids": [],
                                 "threadVisible": true
                             })
            insertPosition += 1
        }
        for (k in kids) {
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

    function toggleChildCommentsVisibility(comment_id) {
        for (var i = 0; i < listModel.count; i++) {
            const item = listModel.get(i)
            if (item.thread_id === comment_id) {
                listModel.setProperty(i, "threadVisible", !item.threadVisible)
                toggleChildCommentsVisibility(item.comment_id)
            }
        }
    }

    Python {
        id: python

        Component.onCompleted: {

            //addImportPath(Qt.resolvedUrl('../src/'))
            setHandler('comment-pop', populateComment)
        }
    }
}
