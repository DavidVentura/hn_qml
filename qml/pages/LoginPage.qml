import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import Ubuntu.Components 1.3 as UUITK
import io.thp.pyotherside 1.3

UUITK.Page {
    property bool busy: false
    property bool error: false
    id: loginPage
    anchors.fill: parent

    header: UUITK.PageHeader {
        title: 'Log in'
        leadingActionBar.actions: [
            UUITK.Action {
                iconName: "back"
                text: "Back"
                onTriggered: {
                    stack.pop()
                }
            }
        ]
    }
    UUITK.Label {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: units.gu(2)
        anchors.rightMargin: units.gu(2)
        color: 'orange'
        font.pointSize: units.gu(1)
        wrapMode: Text.WordWrap
        horizontalAlignment: Qt.AlignHCenter
        text: "If you mis-type your password too many times, you will get blocked for a few hours"
    }
    ColumnLayout {
        anchors.centerIn: parent
        spacing: units.gu(0.2)

        UUITK.Label {
            text: "Username"
        }

        UUITK.TextField {
            id: user
            placeholderText: "user"
            color: error ? 'red' : 'black'
            Keys.onPressed: error = false
        }
        UUITK.Label {
            text: "Password"
            Layout.topMargin: units.gu(1)
        }
        UUITK.TextField {
            id: password
            placeholderText: "password"

            echoMode: TextInput.Password
            Keys.onReturnPressed: login()
            color: error ? 'red' : 'black'
            Keys.onPressed: error = false
        }
        UUITK.Button {
            text: "Log in"
            Layout.topMargin: units.gu(2)
            Layout.fillWidth: true
            onClicked: login()
        }

        UUITK.ActivityIndicator {
            Layout.topMargin: units.gu(2)
            Layout.fillWidth: true
            running: true
            visible: busy
        }
    }
    function login() {
        busy = true
        python.call("example.login_and_store_cookie",
                    [user.text, password.text], function (success) {
                        busy = false
                        if (success) {
                            stack.pop()
                        } else {
                            error = true
                        }
                    })
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'))
            importModule('example', function () {})
        }
    }
}
