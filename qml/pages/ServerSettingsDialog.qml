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
import Sailfish.Silica 1.0

import "../types"
import "../js/WallaBase.js" as WallaBase

Dialog {
    id: serverSettingsDialog
    allowedOrientations: Orientation.All
    canAccept: true

    property int serverId

    ServerSettings {
        id: serverSettings
        serverId: serverSettingsDialog.serverId

        onError: {
            // TODO: display this message to the user
            console.error( message )
        }
    }

    onAccepted: {
        var props = {
            name: nameField.text,
            url: urlField.text,
            user: userField.text,
            password: passwordField.text,
            clientId: clientIdField.text,
            clientSecret: clientSecretField.text
        }

        if ( serverId === -1 )
            WallaBase.addNewServer( props )
        else
            WallaBase.updateServer( serverId, props )
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        width: parent.width

        Column {
            id: column
            width: parent.width

            DialogHeader {
                acceptText: qsTr( "Save" )
            }

            TextField {
                id: nameField
                width: parent.width
                label: qsTr( "Server Alias" )
                placeholderText: qsTr( "Server Alias" )
                text: serverSettings.name
                focus: true
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: urlField.focus = true
            }

            TextField {
                id: urlField
                width: parent.width
                label: qsTr( "URL" )
                placeholderText: qsTr( "Server URL" )
                text: serverSettings.url
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: userField.focus = true
            }

            TextField {
                id: userField
                width: parent.width
                label: qsTr( "Login" )
                placeholderText: qsTr( "User Login" )
                text: serverSettings.user
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: passwordField.focus = true
            }

            PasswordField {
                id: passwordField
                width: parent.width
                label: "Password"
                text: serverSettings.password
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: clientIdField.focus = true
            }

            TextField {
                id: clientIdField
                width: parent.width
                label: qsTr( "Client ID" )
                placeholderText: qsTr( "Client ID" )
                text: serverSettings.clientId
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: clientSecretField.focus = true
            }

            TextField {
                id: clientSecretField
                width: parent.width
                label: qsTr( "Client Secret" )
                placeholderText: qsTr( "Client Secret" )
                text: serverSettings.clientSecret
            }
        }
    }
}
