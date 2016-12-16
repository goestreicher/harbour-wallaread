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
import "../types"
import "../js/WallaBase.js" as WallaBase

Page {
    id: serversPage
    allowedOrientations: Orientation.All

    ServersModel {
        id: serversModel
        loaded: false

        onError: function( msg ) {
            // TODO: display this message to the user
            console.error( msg )
        }
    }

    function updateServerList() {
        serversModel.load()
    }

    function resetDatabase() {
        WallaBase.resetDatabase()
        updateServerList()
    }

    Component.onCompleted: {
        updateServerList()
    }

    SilicaListView {
        anchors.fill: parent
        spacing: Theme.paddingMedium
        model: serversModel
        visible: serversModel.loaded

        RemorsePopup {
            id: remorsePopup
        }

        PullDownMenu {
            MenuItem {
                text: qsTr( "Reset database" )
                onClicked: {
                    remorsePopup.execute(
                        qsTr( "Resetting database" ),
                        function() {
                            serversPage.resetDatabase()
                        }
                    )
                }
            }

            MenuItem {
                text: qsTr( "Settings" )
                onClicked: {
                    var page = pageStack.push( Qt.resolvedUrl( "SettingsPage.qml" ) )
                    page.serverListChanged.connect( updateServerList )
                }
            }
        }

        header: PageHeader {
            title: qsTr( "Wallabag servers" )
        }

        ViewPlaceholder {
            enabled: serversModel.loaded && serversModel.count == 0
            text: qsTr( "No servers configured yet, create your first one with the Settings menu" )
        }

        delegate: ListItem {
            id: listEntry
            width: parent.width

            Item {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: serverCountLabel
                    height: listEntry.height - 1.5 * Theme.horizontalPageMargin
                    width: height
                    radius: 2
                    color: listEntry.highlighted ? Theme.primaryColor : Theme.highlightBackgroundColor
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        anchors.centerIn: parent
                        text: model.unread
                        font.pixelSize: Theme.fontSizeSmall
                        color: listEntry.highlighted ? Theme.highlightBackgroundColor : Theme.primaryColor
                    }
                }

                Label {
                    id: serverAliasLabel
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: serverCountLabel.right
                    anchors.leftMargin: Theme.paddingMedium
                    color: listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: model.name
                }
            }

            onClicked: pageStack.push( Qt.resolvedUrl( "ServerPage.qml" ), { serverId: model.id } )
        }
    }
}
