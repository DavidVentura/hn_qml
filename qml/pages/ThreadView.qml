import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.12
import io.thp.pyotherside 1.5
import Ubuntu.Components 1.3 as UUITK
import QtGraphicalEffects 1.0

import "../components"

UUITK.Page {
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

    header: UUITK.PageHeader {
        id: header
        title: pageTitle

        leadingActionBar.actions: [
            UUITK.Action {
                iconName: "back"
                text: "Back"
                onTriggered: {
                    python.call("example.purge_queued_comments")
                    stack.pop()
                }
            }
        ]
        trailingActionBar.actions: [
            UUITK.Action {
                iconName: "external-link"
                text: "open in browser"
                onTriggered: {
                    Qt.openUrlExternally(pageUrl)
                }
            }
        ]
    }

    SharePage {
        id: sharer
    }

    ListModel {
        id: listModel
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
        model: listModel

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

                        RowLayout {
                            id: commentHeader
                            width: parent.parent.width - parent.padding
                            spacing: 0
                            Text {
                                text: age
                                font.pointSize: units.gu(1)
                                color: '#999'
                            }
                            Text {
                                leftPadding: units.gu(0.8)
                                text: user
                                font.pointSize: units.gu(1)
                                font.bold: true
                                color: barColor[depth % 8]
                            }

                            Rectangle {
                                // filler
                                Layout.fillWidth: true
                            }

                            Item {
                                Layout.minimumWidth: units.gu(2)
                                height: units.gu(2.2)

                                Image {
                                    source: "../../assets/options.svg"
                                    anchors.fill: parent
                                    asynchronous: true
                                    cache: true
                                    fillMode: Image.PreserveAspectFit
                                    Menu {
                                        id: menu
                                        width: units.gu(20)

                                        background: Rectangle {
                                            id: bgRectangle

                                            layer.enabled: true
                                            layer.effect: DropShadow {
                                                width: bgRectangle.width
                                                height: bgRectangle.height
                                                x: bgRectangle.x
                                                y: bgRectangle.y
                                                visible: bgRectangle.visible

                                                source: bgRectangle

                                                horizontalOffset: 0
                                                verticalOffset: 5
                                                radius: 10
                                                samples: 20
                                                color: "#999"
                                            }
                                        }

                                        MenuPanelItem {
                                            iconName: "share"
                                            label: i18n.tr("Share Link")
                                            onTriggered: {
                                                sharer.content = "https://news.ycombinator.com/item?id=" + comment_id
                                                stack.push(sharer)
                                            }
                                        }
                                        MenuPanelItem {
                                            iconName: "share"
                                            label: i18n.tr("Share Text")
                                            onTriggered: {
                                                sharer.content = markup
                                                stack.push(sharer)
                                            }
                                        }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: menu.open()
                                }
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
                            topPadding: units.gu(1)
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

    function loadThread(story_id) {
        python.call("example.get_story", [story_id], function (story) {
            pageTitle = story.title
            pageUrl = story.url
            pageId = story_id
            pageKids = story.kids
            listModel.clear()
            loadKids(story_id, story.kids, 0)
        })
    }

    function loadKids(thread_id, kids, depth) {
        var insertPosition = indexOfComment(thread_id) + 1
        const kid_ids = kids.map(function (x) {
            return x.id
        })

        for (var i in kid_ids) {
            const item = {
                "depth": depth,
                "thread_id": thread_id.toString(),
                "markup": "...",
                "comment_id": kid_ids[i].toString(),
                "user": "..",
                "age": "",
                "kids": [],
                "threadVisible": true,
                "initialized": false
            }
            listModel.insert(insertPosition, item)
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
                }
            }
            if (depth) {
                listModel.setProperty(i, "threadVisible", !item.threadVisible)
            }
        }
    }
}
