/*
 * WallaRead - A Wallabag 2+ client for SailfishOS
 * © 2016 Grégory Oestreicher <greg@kamago.net>
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

import "../js/WallaBase.js" as WallaBase

QtObject {
    property int serverId: -1
    property string name
    property string url
    property string user
    property string password
    property string clientId
    property string clientSecret

    signal error( string message )

    onServerIdChanged: {
        if ( serverId !== -1 ) {
            console.debug( "Loading information for server " + serverId )
            WallaBase.getServerSettings( serverId, onServerSettingsLoaded )
        }
        else {
            name = null
            url = null
            user = null
            password = null
            clientId = null
            clientSecret = null
        }
    }

    function onServerSettingsLoaded( props, err ) {
        if ( err !== null ) {
            error( qsTr( "Failed to load server settings: " ) + err )
        }
        else {
            name = props.name
            url = props.url
            user = props.user
            password = props.password
            clientId = props.clientId
            clientSecret = props.clientSecret
        }
    }
}
