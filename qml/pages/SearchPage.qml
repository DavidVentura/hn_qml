import QtQuick 2.12
import QtQuick.Controls 2.12
import Ubuntu.Components 1.3 as UUITK
import io.thp.pyotherside 1.3
import "../components"

UUITK.Page {
    id: searchPage
    header: UUITK.PageHeader {
        id: pageHeader
        contents: UUITK.TextField {
            id: textField
            placeholderText: "Search"
            anchors.fill: parent
            Keys.onReturnPressed: search()
            anchors.topMargin: units.gu(1)
            anchors.bottomMargin: units.gu(1)
        }
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
                iconName: "find"
                text: "Search"
                onTriggered: {
                    search()
                }
            }
        ]
    }
    ListView {
        id: mylv
        spacing: 1
        anchors.fill: parent
        anchors.topMargin: pageHeader.height
        cacheBuffer: height / 2

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

                threadview.loadThread(story_id)
                threadview.visible = true
            }
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'))
            importModule('example')
            setHandler('search-pop', function (stories) {
                console.log('stories', JSON.stringify(stories, null, 2))
            })
        }

        onError: {
            console.log('python error: ' + traceback)
        }
    }
    function search() {
        python.call("example.search", [textField.text], function (result) {
            for (var i = 0; i < result.length; i++) {
                listModel.append(result[i])
            }
        })
    }
}
