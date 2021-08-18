

/*
 * Copyright (C) 2021  David Ventura
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * hnr is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.7
import QtQuick.Controls 2.7
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import io.thp.pyotherside 1.3

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'hnr.davidv.dev'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'))
            importModule('example', function () {
                python.call('example.top_stories', [], function (result) {
                    for (var i = 0; i < result.length; i++) {
                        listModel.append(result[i])
                    }
                })
            })
            setHandler('comment-pop',
                       function () {}) // this is handled in ThreadView.qml
            setHandler('thread-pop', function (id, data) {
                for (var i = 0; i < listModel.count; i++) {
                    var item = listModel.get(i)
                    if (item.story_id !== id) {
                        continue
                    }

                    item.title = data.title
                    item.url_domain = data.url_domain
                    item.url = data.url
                    item.comment_count = data.comment_count
                    item.kids = data.kids.join(',')
                    break
                }
            })
        }

        onError: {
            console.log('python error: ' + traceback)
        }
        onReceived: console.log('Main-Event' + data)
    }
    Page {
        anchors.fill: parent
        header: PageHeader {
            id: pageHeader
            title: 'Top Stories'
            //            StyleHints {
            //                foregroundColor: UbuntuColors.orange
            //                backgroundColor: "black"
            //                dividerColor: UbuntuColors.slate
            //            }
            leadingActionBar.actions: [
                Action {
                    iconName: "back"
                    text: "Back"
                    onTriggered: {
                        stack.pop()
                    }
                    visible: stack.depth > 0
                }
            ]
            //            contents: Rectangle {
            //                anchors.fill: parent
            //                color: UbuntuColors.red
            //                Label {
            //                    anchors.centerIn: parent
            //                    text: pageHeader.title
            //                    color: "white"
            //                }
            //            }
        }

        StackView {
            id: stack
            initialItem: lv
            anchors.fill: parent
            anchors.topMargin: pageHeader.height
        }

        ListView {
            id: lv
            spacing: 1
            visible: false

            model: ListModel {
                id: listModel
            }

            delegate: ThreadStub {
                t_id: story_id
                t_title: title
                t_url: url_domain
                t_comments: comment_count
                onUrlClicked: {
                    console.log("urlclicked mainqml", url)
                    Qt.openUrlExternally(url)
                }
                onThreadClicked: {
                    stack.push(threadview)
                    threadview.loadThread(story_id, kids.split(','), 0)
                    threadview.visible = true
                }
            }
        }

        ThreadView {
            visible: false
            id: threadview
        }
    }
}
