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
                popover.show('Failed to fetch thread: ' + msg)
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

        delegate: Column {
            anchors.left: parent.left
            anchors.right: parent.right

            height: {
                if (!threadVisible)
                    return 0
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
                    color: highlightComment == comment_id ? '#e8e8d6' : '#f6f6ef'

                    Column {
                        padding: units.gu(1)

                        RowLayout {
                            id: commentHeader
                            width: parent.parent.width - parent.padding
                            spacing: 0
                            Text {
                                text: age
                                font.pointSize: units.gu(1.1)
                                color: '#999'
                            }
                            Text {
                                leftPadding: units.gu(0.8)
                                text: author
                                font.pointSize: units.gu(1.1)
                                font.bold: true
                                color: barColor[depth % 8]
                            }

                            Rectangle {
                                // filler
                                Layout.fillWidth: true
                            }

                            Item {
                                Layout.minimumWidth: units.gu(5)
                                height: units.gu(2.4)

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
                                                sharer.content = "https://news.ycombinator.com/item?id=" + comment_id.toString()
                                                stack.push(sharer)
                                            }
                                        }
                                        MenuPanelItem {
                                            iconName: "share"
                                            label: i18n.tr("Share Text")
                                            onTriggered: {
                                                const text = python.call_sync(
                                                               'example.html_to_plaintext',
                                                               [markup])
                                                sharer.content = text
                                                stack.push(sharer)
                                            }
                                        }
                                        MenuPanelItem {
                                            enabled: root.settings.cookie !== undefined
                                            iconName: "select"
                                            label: i18n.tr("Vote up")
                                            onTriggered: {
                                                popover.show('Voting..')
                                                python.call('example.vote_up',
                                                            [comment_id.toString(
                                                                 )],
                                                            function () {
                                                                popover.show('Voted successfully')
                                                            })
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
                            visible: hasKids
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
                                    toggleChildCommentsVisibility(id)
                                }
                            }
                        }
                    }
                }
            }
        }
        footer: Item {
            width: parent.width
            height: units.gu(0.5)
        }
    }

    Popup {
        id: popover
        padding: units.dp(12)

        x: parent.width / 2 - width / 2
        y: parent.height - height - units.dp(14)

        background: Rectangle {
            color: "#000"
            opacity: 0.6
            radius: units.dp(28)
        }

        Text {
            id: popupLabel
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            color: "#ffffff"
            font.pixelSize: units.dp(14)
        }

        Timer {
            id: popupTimer
            interval: 2000
            running: true
            onTriggered: {
                popover.close()
            }
        }

        function show(text) {
            popupLabel.text = text
            open()
            popupTimer.restart()
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
