import QtQuick 2.12
import QtQuick.Layouts 1.12
import io.thp.pyotherside 1.5
import Ubuntu.Components 1.3

Page {
    property variant barColor: ['#f44336', '#d500f9', '#304ffe', '#0288d1', '#26A69A', '#00c853', '#fff3e0', '#8d6e63']
    property string pageTitle: '..'
    property string pageUrl: 'http://example.com'
    property int pageId
    property variant pageKids: []
    property bool shouldRefresh: false

    Python {
        id: python

        Component.onCompleted: {
            setHandler('comment-pop', updateComment)
        }
    }

    header: PageHeader {
        id: header
        title: pageTitle

        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: "Back"
                onTriggered: {
                    python.call("example.purge_queued_comments")
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
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: height / 2
        model: ListModel {
            id: listModel
        }

        delegate: Column {
            anchors.left: parent.left
            anchors.right: parent.right
            height: threadVisible ? childrenRect.height : 0
            visible: threadVisible

            Component.onCompleted: {
                if (!initialized && threadVisible) {
                    initialized = true
                    python.call("example.fetch_comment",
                                [pageId, thread_id, comment_id, depth])
                }
            }

            //            Behavior on height {
            //                NumberAnimation {
            //                    duration: 100
            //                }
            //            }
            // animation is fairly wonky

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

                        TextEdit {
                            id: commentText
                            wrapMode: Text.WordWrap
                            text: markup
                            width: commentBody.width - units.gu(1.5)
                            textFormat: Qt.RichText
                            onLinkActivated: Qt.openUrlExternally(link)
                            readOnly: true
                            // selectByMouse: true
                            // this completely breaks touch!
                        }
                        Rectangle {
                            visible: kids.count > 0
                            width: commentBody.width - units.gu(1.5)
                            height: units.gu(2.5)
                            color: 'transparent'
                            Text {
                                text: 'Tap to toggle replies'
                                color: '#aaa'
                                anchors.fill: parent
                                font.pointSize: units.gu(1)
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignBottom
                            }

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
        pageId = story_id
        pageKids = kids
        listModel.clear()
        loadKids(story_id, kids, 0)
    }

    function loadKids(thread_id, kids, depth) {
        var insertPosition = indexOfComment(thread_id) + 1
        var kid_ids = []
        var i
        if ((kids + "").startsWith('QQmlListModel')) {
            for (i = 0; i < kids.count; i++) {
                kid_ids.push(kids.get(i).id)
            }
        } else {
            kid_ids = kids.map(function (x) {
                return x.id
            })
        }

        for (i in kid_ids) {

            listModel.insert(insertPosition, {
                                 "depth": depth,
                                 "thread_id": thread_id.toString(),
                                 "markup": "...",
                                 "comment_id": kid_ids[i].toString(),
                                 "user": "..",
                                 "age": "",
                                 "kids": [],
                                 "threadVisible": true,
                                 "initialized": false
                             })
            insertPosition += 1
        }
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

        loadKids(comment.comment_id, comment.kids, comment.depth + 1)
    }

    function toggleChildCommentsVisibility(comment_id) {

        let depth = 0
        for (var i = 0; i < listModel.count; i++) {
            const item = listModel.get(i)
            if (item.depth < depth)
                break

            if (item.parent_id === comment_id) {
                if (depth === 0) {
                    depth = item.depth
                    console.log(depth)
                }
            }
            if (depth) {
                listModel.setProperty(i, "threadVisible", !item.threadVisible)
            }
        }
    }
}
