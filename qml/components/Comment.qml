import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtGraphicalEffects 1.0

Column {
    property variant barColor: ['#f44336', '#d500f9', '#304ffe', '#0288d1', '#26A69A', '#00c853', '#fff3e0', '#8d6e63']
    property bool optionsVisible: true
    property string c_age
    property string c_author
    property string c_markup
    property string c_id
    property bool c_hasKids
    property int c_depth
    signal showChildrenToggled
    signal replyTapped
    anchors.left: parent.left
    anchors.right: parent.right

    height: {
        if (!visible)
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
        anchors.leftMargin: c_depth * units.gu(0.5)
        anchors.left: parent.left
        anchors.right: parent.right

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: units.gu(0.3)
            color: barColor[c_depth % 8]
        }
        Rectangle {
            id: commentBody
            width: parent.width
            height: childrenRect.height
            color: highlightComment == c_id ? '#e8e8d6' : '#f6f6ef'

            Column {
                padding: units.gu(1)

                RowLayout {
                    id: commentHeader
                    width: parent.parent.width - parent.padding
                    spacing: 0
                    Text {
                        text: c_age
                        font.pointSize: units.gu(1.1)
                        color: '#999'
                    }
                    Text {
                        leftPadding: units.gu(0.8)
                        text: c_author
                        font.pointSize: units.gu(1.1)
                        font.bold: true
                        color: barColor[c_depth % 8]
                    }

                    Rectangle {
                        // filler
                        Layout.fillWidth: true
                    }

                    Item {
                        visible: optionsVisible
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
                                        sharer.content = "https://news.ycombinator.com/item?id="
                                                + c_id.toString()
                                        stack.push(sharer)
                                    }
                                }
                                MenuPanelItem {
                                    iconName: "share"
                                    label: i18n.tr("Share Text")
                                    onTriggered: {
                                        const text = python.call_sync(
                                                       'example.html_to_plaintext',
                                                       [c_markup])
                                        sharer.content = text
                                        stack.push(sharer)
                                    }
                                }
                                MenuPanelItem {
                                    enabled: root.settings.cookie !== undefined
                                    iconName: "select"
                                    label: i18n.tr("Vote up")
                                    onTriggered: {
                                        toast.show('Voting..')
                                        python.call('example.vote_up',
                                                    [c_id.toString()],
                                                    function () {
                                                        toast.show('Voted successfully')
                                                    })
                                    }
                                }
                                MenuPanelItem {
                                    enabled: root.settings.cookie !== undefined
                                             && created_days_ago <= 10
                                    iconName: "mail-reply"
                                    label: i18n.tr("Reply")
                                    onTriggered: replyTapped()
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
                    text: c_markup
                    width: commentBody.width - units.gu(3)
                    textFormat: Qt.RichText
                    onLinkActivated: Qt.openUrlExternally(link)
                    readOnly: true
                    topPadding: units.gu(1)
                    // selectByMouse: true
                    // this completely breaks touch!
                }
                Rectangle {
                    visible: c_hasKids
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
                        onClicked: showChildrenToggled()
                    }
                }
            }
        }
    }
}
