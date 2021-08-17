import QtQuick 2.0
import QtQuick.Layouts 1.12

Item {
    Column {
        id: thing
        spacing: 2
        width: parent.width
    }


    function loadThread(kids) {

        for (var k in kids) {
            var component = Qt.createComponent("Comment.qml")
            if (component.status === Component.Ready) {
                finishCreation(component, kids[k])()
            } else {
                component.statusChanged.connect(finishCreation(component,
                                                               kids[k]))
            }
        }
    }

    function finishCreation(component, thread_id) {
        function f() {
            if (component.status === Component.Ready) {
                console.log('creating top level', thread_id)
                var sprite = component.createObject(thing, {
                                                        "thread_id": thread_id
                                                    })
            } else if (component.status === Component.Error) {
                // Error Handling
                console.log("Error loading component:", component.errorString())
            }
        }
        return f
    }



}

