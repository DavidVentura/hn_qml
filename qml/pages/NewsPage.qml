import QtQuick 2.8
import Ubuntu.Components 1.3
import io.thp.pyotherside 1.3
import ".."

Page {
    id: newsPage
    anchors.fill: parent
    header: PageHeader {
        id: pageHeader
        title: 'Top Stories'
    }
    ListView {
        id: mylv
        spacing: 1
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        cacheBuffer: height / 2

        header: Text {
            id: refreshLabel
            text: "Drag to refresh"
            height: pageHeader.height
        }
        onContentYChanged: {
            if (contentY >= 0)
                return
            if (contentY < -units.gu(18)) {
                headerItem.text = "Release to refresh"
            } else if (contentY >= -units.gu(18)) {
                headerItem.text = "Drag to refresh"
            }
        }
        onDragEnded: {

            if (contentY < -units.gu(18)) {
                headerItem.text = "Drag to refresh"
                loadStories()
            }
        }

        model: ListModel {
            id: listModel
        }

        delegate: ThreadStub {
            t_id: story_id
            t_title: title
            t_url: url_domain
            t_comments: comment_count
            Component.onCompleted: {
                if (!initialized) {
                    initialized = true
                    python.call("example.bg_fetch_story", [story_id])
                }
            }
            onUrlClicked: {
                console.log("urlclicked mainqml", url)
                Qt.openUrlExternally(url)
            }
            onThreadClicked: {
                stack.push(threadview)

                threadview.loadThread(story_id, title, url, kids)
                threadview.visible = true
            }
        }
    }

    function loadStories() {
        listModel.clear()
        python.call('example.top_stories', [], function (result) {
            for (var i = 0; i < result.length; i++) {
                listModel.append(result[i])
            }
        })
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'))
            importModule('example', function () {
                loadStories()
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
                    item.kids = data.kids
                    break
                }
            })
        }

        onError: {
            console.log('python error: ' + traceback)
        }
        onReceived: console.log('Main-Event' + data)
    }
}
