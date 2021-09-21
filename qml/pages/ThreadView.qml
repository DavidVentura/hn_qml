import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.12
import io.thp.pyotherside 1.5
import Ubuntu.Components 1.3 as UUITK
import QtGraphicalEffects 1.0

import "../components"

UUITK.Page {
    property string pageTitle: '..'
    property string threadId
    property string pageUrl: 'http://example.com'
    property bool loading: false
    property int highlightComment

    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'))
            importModule('example', function () {})
            setHandler('fail', function (msg) {
                toast.show('Failed to fetch thread: ' + msg)
                loading = false
            })
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
                    listModel.clear()
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
            },
            UUITK.Action {
                visible: settings.cookie !== undefined
                iconName: "mail-reply"
                text: "Reply"
                onTriggered: {
                    stack.push(Qt.resolvedUrl("ReplyPage.qml"), {
                                   "c_id": threadId,
                                   "displayComment": false,
                                   "c_author": pageTitle
                               })
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
    Item {
        anchors.fill: parent
        UUITK.ActivityIndicator {
            anchors.centerIn: parent
            running: loading
            visible: loading
        }
    }
    ListView {
        id: mylv
        anchors.leftMargin: units.gu(0.5)
        anchors.rightMargin: units.gu(0.5)
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: height > 0 ? height / 2 : 0
        model: listModel
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 0
        highlightMoveVelocity: -1

        delegate: Comment {
            visible: threadVisible
            c_id: comment_id
            c_hasKids: hasKids
            c_author: author
            c_age: age
            c_markup: markup
            c_depth: depth

            onShowChildrenToggled: {
                toggleChildCommentsVisibility(comment_id)
            }
            onReplyTapped: {
                stack.push(Qt.resolvedUrl("ReplyPage.qml"), {
                               "c_id": comment_id,
                               "c_markup": markup,
                               "c_age": age,
                               "c_author": author
                           })
            }
            onUsernameTapped: {
                mylv.currentIndex = indexOfComment(comment_id)
                stack.push(Qt.resolvedUrl("UserPage.qml"), {
                               "username": author
                           })
            }
        }
        footer: Item {
            width: parent.width
            height: units.gu(0.5)
        }
    }

    function loadThread(story_id, title, url) {
        listModel.clear()
        loading = true
        python.call("example.get_story", [story_id.toString()],
                    function (story) {
                        if (story === undefined) {
                            return
                        }

                        pageTitle = story.title
                        pageUrl = story.url
                        loading = false

                        for (var i = 0; i < story.kids.length; i++) {
                            const kid = story.kids[i]
                            listModel.append(kid)
                        }
                        highlightComment = 0
                        if (story.highlight) {
                            highlightComment = story.highlight
                            const idx = indexOfComment(highlightComment)
                            if (idx === -1) {
                                return
                            }

                            mylv.currentIndex = idx
                        }
                    })
    }
    Component.onCompleted: loadThread(threadId, pageTitle, pageUrl)

    function indexOfComment(comment_id) {
        for (var i = 0; i < listModel.count; i++) {
            if (comment_id === listModel.get(i).comment_id) {
                return i
            }
        }
        return -1
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
