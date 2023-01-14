
/*
 * Copyright (C) 2021  David Ventura
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * hnr is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.12
import QtQuick.Controls 2.12
import Lomiri.Components 1.3
import Qt.labs.settings 1.0
import io.thp.pyotherside 1.3

import "./pages"

MainView {
    property variant settings: {

    }
    id: root
    objectName: 'mainView'
    applicationName: 'hnr.davidv.dev'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    StackView {
        id: stack
        anchors.fill: parent
    }

    Popup {
        id: toast
        padding: units.dp(12)

        x: stack.width / 2 - width / 2
        y: stack.height - height - units.dp(14)

        background: Rectangle {
            color: "#000"
            opacity: 0.8
            radius: units.dp(28)
        }

        Text {
            id: popupLabel
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            color: "#ffffff"
            font.pixelSize: units.dp(14)
        }

        Timer {
            id: popupTimer
            interval: 2000
            running: true
            onTriggered: {
                toast.close()
            }
        }

        function show(text) {
            popupLabel.text = text
            open()
            popupTimer.restart()
        }
    }

    Component.onCompleted: stack.push(Qt.resolvedUrl("pages/NewsPage.qml"))
    Connections {
        target: UriHandler

        onOpened: {
            console.log('Open from UriHandler')

            if (uris.length > 0) {
                console.log('Incoming call from UriHandler ' + uris[0])
                const threadId = /id=(\d+)/.exec(uris[0])[1]
                stack.push(Qt.resolvedUrl("pages/ThreadView.qml"), {
                               "threadId": threadId,
                               "pageTitle": "..",
                               "pageUrl": uris[0]
                           })
            }
        }
    }
    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'))
            setHandler('settings', function (_settings) {
                settings = _settings
                console.log('New settings', JSON.stringify(_settings, null, 2))
            })
            importModule('example', function () {
                python.call('example.get_settings', [])
            })
        }
    }
}
