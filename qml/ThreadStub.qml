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

    height: units.gu(9)
    width: parent.width

    RowLayout {
        anchors.fill: parent
        spacing: 2

        Rectangle {
            color: '#f6f6ef'
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    Layout.topMargin: units.gu(1)
                    Layout.leftMargin: units.gu(1.2)
                    font.pixelSize: units.gu(1.8)
                    text: t_title
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.parent.width * 0.95
                }
                Text {
                    Layout.leftMargin: units.gu(1.2)
                    Layout.alignment: Qt.AlignBottom

                    text: t_url
                    color: '#888'
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: stub.urlClicked()
            }
        }
        Rectangle {
            color: '#ffb64d'
            Layout.preferredWidth: units.gu(4)
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
