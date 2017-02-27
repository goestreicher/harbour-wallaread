/*
 * WallaRead - A Wallabag 2+ client for SailfishOS
 * © 2017 Grégory Oestreicher <greg@kamago.net>
 *
 * This file is part of WallaRead.
 *
 * WallaRead is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * WallaRead is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with WallaRead.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: serverShowDialog
    allowedOrientations: Orientation.All
    canAccept: true

    property variant preferences

    onDone: {
        if ( result === DialogResult.Accepted ) {
            preferences.read = showReadSwitch.checked
            preferences.starred = showStarredSwitch.checked
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        width: parent.width

        Column {
            id: column
            width: parent.width

            DialogHeader {
                acceptText: qsTr( "Filter view" )
            }

            TextSwitch {
                id: showReadSwitch
                width: parent.width
                checked: preferences.read
                text: qsTr( "Read articles" )
            }

            TextSwitch {
                id: showStarredSwitch
                width: parent.width
                checked: preferences.starred
                text: qsTr( "Starred articles" )
            }
        }
    }
}
