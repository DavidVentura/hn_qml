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
    property bool shouldRefresh: false

    Python {
        id: python
    }

    header: UUITK.PageHeader {
        id: header
        title: pageTitle

        leadingActionBar.actions: [
            UUITK.Action {
                iconName: "back"
                text: "Back"
                onTriggered: {
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
        cacheBuffer: height > 0 ? height / 2 : 0
        model: listModel

        delegate: Column {
            anchors.left: parent.left
            anchors.right: parent.right

            height: threadVisible ? childrenRect.height : 0
            visible: threadVisible

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
                                                sharer.content = "https://news.ycombinator.com/item?id=" + id
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
    }

    function loadThread(story_id, title, url) {
        pageTitle = title
        python.call("example.get_story", [story_id], function (story) {
            pageTitle = story.title
            pageUrl = story.url
            listModel.clear()
            for (var i = 0; i < story.kids.length; i++) {
                const kid = story.kids[i]
                listModel.append(kid)
            }
        })
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
