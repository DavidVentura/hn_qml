import QtQuick 2.12
import Ubuntu.Components 1.3
import Ubuntu.Content 1.3

Page {
    property string content: "empty"
    ContentPeerPicker {
        id: peerPicker
        handler: ContentHandler.Share
        contentType: ContentType.Text
        onPeerSelected: {
            var activeTransfer = peer.request()
            let item = component.createObject(null, {
                                                  "text": content
                                              })
            activeTransfer.items = [item]
            activeTransfer.state = ContentTransfer.Charged

            stack.pop()
        }
        onCancelPressed: stack.pop()
    }
    Component {
        id: component
        ContentItem {}
    }
}
