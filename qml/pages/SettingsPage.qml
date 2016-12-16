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

import "../models"

Page {
    id: settingsPage
    allowedOrientations: Orientation.All

    signal serverListChanged

    onServerListChanged: updateServerList()

    ServersModel {
        id: serversModel
    }

    function updateServerList() {
        serversModel.load()
    }

    Component.onCompleted: {
        updateServerList()
    }

    SilicaListView {
        anchors.fill: parent
        spacing: Theme.paddingMedium

        model: serversModel

        PullDownMenu {
            MenuItem {
                text: qsTr( "New Server" )
                onClicked: {
                    var dlg = pageStack.push( Qt.resolvedUrl( "ServerSettingsDialog.qml" ), { serverId: -1 } )
                    dlg.accepted.connect( serverListChanged )
                }
            }
        }

        header: PageHeader {
            title: qsTr( "Settings" )
        }

        ViewPlaceholder {
            enabled: serversModel.count == 0
            text: qsTr( "No server found, use the pulley menu and select 'New Server'" )
        }

        delegate: ListItem {
            id: listEntry
            width: parent.width

            Label {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                color: listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                text: model.name
            }

            onClicked: {
                var dlg = pageStack.push( Qt.resolvedUrl( "ServerSettingsDialog.qml" ), { serverId: model.id } )
                dlg.accepted.connect( serverListChanged )
            }
        }

        VerticalScrollDecorator {
        }
    }
}
