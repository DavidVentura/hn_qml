import QtQuick 2.7
import QtQuick.Layouts 1.12
import io.thp.pyotherside 1.5

Item {
    property variant color: ['#f44336', '#d500f9', '#304ffe', '#0288d1', '#26A69A', '#00c853', '#fff3e0', '#8d6e63']

    ListView {
        anchors.fill: parent

        model: ListModel {
            id: listModel
        }

        delegate: Text {
            wrapMode: Text.WordWrap
            x: depth * 10
            text: markup
            padding: 10
            width: parent.width - x
        }
    }

    function loadThread(thread_id, kids, depth) {
        console.log("Loading thread", thread_id, depth)
        var insertPosition = indexOfComment(thread_id) + 1

        for (var k in kids) {
            //console.log("For", kids[k], 'child of', thread_id, 'position is', insertPosition)
            listModel.insert(insertPosition, {
                                 "depth": depth,
                                 "thread_id": thread_id.toString(),
                                 "markup": "aaaaaaaa",
                                 "comment_id": kids[k].toString()
                             })
            insertPosition += 1
        }
        for (k in kids) {

            console.log("Loading kid", kids[k])
            python.call("example.get_comment", [thread_id, kids[k]],
                        function (comment) {
                            // console.log("Got kid", comment.comment_id, "grandkids", comment.kids)

                            //console.log(JSON.stringify(comment))
                            updateComment(comment)

                            loadThread(comment.comment_id, comment.kids,
                                       depth + 1)
                        })
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
    }

    Python {
        id: python

        Component.onCompleted: {

            //addImportPath(Qt.resolvedUrl('../src/'))
        }
    }
}
