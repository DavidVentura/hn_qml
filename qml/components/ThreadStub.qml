import QtQuick 2.7
import QtQuick.Layouts 1.12

Item {
    id: stub
    signal urlClicked
    signal threadClicked
    property int t_id
    property string t_title: ".."
    property string t_url: "url"
    property int t_comments: -1
    property variant t_kids
    property string t_user: ""
    property string t_ago: ""

    height: units.gu(8.5)
    width: parent.width

    RowLayout {
        anchors.fill: parent
        spacing: 2

        Rectangle {
            color: '#f6f6ef'
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: units.gu(1.2)
                spacing: units.gu(1.2)
                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.pixelSize: units.gu(1.8)
                    text: t_title
                    wrapMode: Text.WordWrap
                }
                Row {
                    spacing: units.gu(1)
                    Layout.alignment: Qt.AlignBottom
                    Text {
                        text: t_url
                        color: '#888'
                        font.pixelSize: units.gu(1.3)
                    }
                    Text {
                        text: t_user
                        color: '#888'
                        font.pixelSize: units.gu(1.3)
                    }
                    Text {
                        text: t_ago
                        color: '#888'
                        font.pixelSize: units.gu(1.3)
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: stub.urlClicked()
            }
        }
        Rectangle {
            color: '#ffb64d'
            Layout.preferredWidth: units.gu(4.5)
            Layout.alignment: Qt.AlignRight
            Layout.fillHeight: true
            Text {
                text: t_comments
                anchors.fill: parent
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
            }
            MouseArea {
                anchors.fill: parent
                onClicked: stub.threadClicked()
            }
        }
    }
}
