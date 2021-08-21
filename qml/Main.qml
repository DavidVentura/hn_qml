
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
import Ubuntu.Components 1.3
import Qt.labs.settings 1.0
import "./pages"

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'hnr.davidv.dev'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    StackView {
        id: stack
        initialItem: newspage
        anchors.fill: parent
    }

    ThreadView {
        visible: false
        id: threadview
    }
    NewsPage {
        visible: false
        id: newspage
    }

    Connections {
        target: UriHandler

        onOpened: {
            console.log('Open from UriHandler')

            if (uris.length > 0) {
                console.log('Incoming call from UriHandler ' + uris[0])
                const threadId = /id=(\d+)/.exec(uris[0])[1]
                stack.push(threadview)

                threadview.loadThread(threadId)
                threadview.visible = true
            }
        }
    }
}
