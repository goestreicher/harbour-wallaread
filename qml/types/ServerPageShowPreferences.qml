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

QtObject {
    property bool read: false
    property bool starred: false

    function getVisibleDescription() {
        var ret = ""

        if ( read )
            ret += qsTr( "read" )
        else
            ret += qsTr( "unread" )

        ret += "/"

        if ( starred )
            ret += qsTr( "starred" )
        else
            ret += qsTr( "all" )

        return ret
    }
}
