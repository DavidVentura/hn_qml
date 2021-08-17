import QtQuick 2.0

Item {
    property int thread_id
    property string mytext: ".."
    property int depth: 0
    width: parent.width
    height: 140

    Column {
        // height of the item should be natural, not 140
        id: col
        width: parent.width
        spacing: 2
        Rectangle {
            width: 3
            height: 30
            x: 20*depth
            color: ['#f44336', '#d500f9', '#304ffe', '#0288d1', '#26A69A', '#00c853', '#fff3e0', '#8d6e63'][depth]

            Text {
                verticalAlignment: Qt.AlignVCenter
                text: mytext
            }
        }

    }

    Component.onCompleted: {
        console.log("i am ", thread_id, depth);
        loadComment();
    }

    function loadComment() {
        console.log("loading comment", thread_id);
        mytext = thread_id;
        python.call('example.get_comment', [thread_id], function (result) {
            for (var k in result.kids) {
                const kid = result.kids[k];
                console.log('loading kid', kid);
                var component = Qt.createComponent("Comment.qml")
                if (component.status === Component.Ready) {
                    finishCreation(component, kid)()
                } else {
                    component.statusChanged.connect(finishCreation(component,
                                                                   kid))
                }
            }


        })
    }

    function finishCreation(component, thread_id) {
        function f() {
            if (component.status === Component.Ready) {
                var sprite = component.createObject(col, {
                                                        "thread_id": thread_id,
                                                        "depth": depth + 1,
                                                    })
            } else if (component.status === Component.Error) {
                // Error Handling
                console.log("Error loading component:", component.errorString())
            } else {
                console.log('wtf')
            }
        }
        return f
    }
}
