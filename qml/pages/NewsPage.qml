import QtQuick 2.7
import Ubuntu.Components 1.3
import io.thp.pyotherside 1.3

Page {
    id: newsPage
    anchors.fill: parent
    header: PageHeader {
        id: pageHeader
        title: 'Top Stories'
    }
    ListView {
        spacing: 1
        anchors.top: pageHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
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
                threadview.loadThread(story_id, title, url, kids.split(','))
                threadview.visible = true
            }
        }
    }
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
                console.log('thread pop')
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
}
