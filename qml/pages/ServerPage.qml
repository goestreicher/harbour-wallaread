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
    id: serverPage
    allowedOrientations: Orientation.All

    property int serverId
    property alias server: server

    Server {
        id: server
        serverId: serverPage.serverId

        onArticlesDownloaded: {
            serverPage.updateArticlesList()
        }

        onError: {
            showError( message )
        }
    }

    ArticlesModel {
        id: articlesModel

        onError: {
            showError( message )
        }
    }

    function updateArticlesList() {
        articlesModel.load( serverId )
    }

    function showError( message ) {
        // TODO: display this message to the user
        console.error( message )
    }

    Component.onCompleted: {
        updateArticlesList()
    }

    Rectangle {
        id: busyContainer
        visible: !articlesModel.loaded
        anchors.fill: parent
        color: "black"
        opacity: 0.6
        z: 5

        MouseArea {
            anchors.fill: parent
        }

        BusyIndicator {
            id: serversBusyIndicator
            running: busyContainer.visible
            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
        }
    }

    MouseArea {
        id: addArticleContainer
        width: parent.width
        height: listView.height
        x: 0
        y: listView.height
        z: 5

        ParallelAnimation {
            id: showAddArticleContainer

            PropertyAnimation {
                target: addArticleContainer
                property: "y"
                to: 0
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }

        ParallelAnimation {
            id: hideAddArticleContainer

            PropertyAnimation {
                target: addArticleContainer
                property: "y"
                to: listView.height
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }

        Rectangle {
            height: addArticleUrl.height + addArticleUrl.anchors.topMargin + addArticlesButtonRow.height
            width: parent.width
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            color: "black"
            opacity: 0.9
        }

        Item {
            height: addArticleUrl.height + addArticleUrl.anchors.topMargin + addArticlesButtonRow.height
            width: parent.width
            anchors.bottom: parent.bottom
            anchors.left: parent.left

            TextField {
                id: addArticleUrl
                width: parent.width
                anchors.top: parent.top
                anchors.topMargin: Theme.horizontalPageMargin
                placeholderText: qsTr( "Article URL" )
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhUrlCharactersOnly
            }

            Row {
                id: addArticlesButtonRow
                anchors.top: addArticleUrl.bottom
                spacing: 2 * Theme.paddingLarge
                width: addArticleCancel.width + addArticleConfirm.width + Theme.paddingLarge
                x: ( parent.width / 2 ) - ( ( 2 * spacing + addArticleCancel.width + addArticleConfirm.width ) / 2 )

                IconButton {
                    id: addArticleCancel
                    icon.source: "image://theme/icon-m-dismiss"

                    onClicked: {
                        addArticleUrl.text = ""
                        hideAddArticleContainer.start()
                    }
                }

                IconButton {
                    id: addArticleConfirm
                    icon.source: "image://theme/icon-m-acknowledge"

                    onClicked: {
                        serverPage.server.uploadArticle(
                            addArticleUrl.text,
                            function() {
                                addArticleUrl.text = ""
                                hideAddArticleContainer.start()
                            }
                        )
                    }
                }
            }
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        spacing: Theme.paddingMedium
        model: articlesModel

        PullDownMenu {
            MenuItem {
                text: articlesModel.showStarred ? qsTr( "Show unstarred articles" ) : qsTr( "Show only starred articles" )
                onClicked: {
                    articlesModel.showStarred = !articlesModel.showStarred
                    serverPage.updateArticlesList()
                }
            }

            MenuItem {
                text: articlesModel.showRead ? qsTr( "Show unread articles" ) : qsTr( "Show read articles" )
                onClicked: {
                    articlesModel.showRead = !articlesModel.showRead
                    serverPage.updateArticlesList()
                }
            }

            MenuItem {
                text: qsTr( "Refresh" )
                onClicked: {
                    articlesModel.loaded = false
                    server.syncDeletedArticles(
                        function() {
                            server.getUpdatedArticles()
                        }
                    )
                }
            }

            MenuItem {
                text: qsTr( "Add article" )
                onClicked: {
                    showAddArticleContainer.start()
                    addArticleUrl.focus = true
                }
            }
        }

        header: PageHeader {
            title: server.name
        }

        ViewPlaceholder {
            enabled: articlesModel.count == 0
            text: qsTr( "No articles saved on this server yet" )
        }

        delegate: ListItem {
            id: listEntry
            width: parent.width
            contentHeight: titleLabel.height + infoRow.height

            RemorseItem {
                id: remorse
            }

            function showRemorse( idx ) {
                remorse.execute(
                    listEntry,
                    qsTr( "Deleting" ),
                    function() {
                        var id = articlesModel.get( idx ).id
                        articlesModel.remove( idx )
                        serverPage.server.deleteArticle(
                            id,
                            function( err ) {
                                if ( err !== null ) {
                                    showError( err )
                                    // Just reload the whole list. May be inefficient though
                                    serverPage.updateArticlesList()
                                }
                            }
                        )
                    }
                )
            }

            menu: ContextMenu {
                id: articleMenu

                Row {
                    id: actionsRow
                    width: parent.width
                    spacing: Theme.paddingLarge
                    x: ( width / 2 ) - ( ( 2 * spacing + starButton.width + toggleReadButton.width + deleteButton.width ) / 2 )

                    IconButton {
                        id: starButton
                        icon.source: model.starred ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"

                        onClicked: {
                            starButton.enabled = false

                            serverPage.server.toggleArticleStar(
                                model,
                                function( star, err ) {
                                    articleMenu.hide()

                                    if ( err !== null ) {
                                        showError( err )
                                    }
                                    else {
                                        serverPage.updateArticlesList()
                                    }
                                }
                            )
                        }
                    }

                    IconButton {
                        id: toggleReadButton
                        icon.source: "image://theme/icon-m-acknowledge" + ( model.archived ? "?" + Theme.secondaryColor : "" )

                        onClicked: {
                            toggleReadButton.enabled = false

                            serverPage.server.toggleArticleRead(
                                model,
                                function( read, err ) {
                                    articleMenu.hide()

                                    if ( err !== null ) {
                                        showError( err )
                                    }
                                    else {
                                        serverPage.updateArticlesList()
                                    }
                                }
                            )
                        }
                    }

                    IconButton {
                        id: deleteButton
                        icon.source: "image://theme/icon-m-delete"

                        onClicked: {
                            articleMenu.hide()
                            listEntry.showRemorse( index )
                        }
                    }
                }
            }

            Column {
                width: parent.width - 2*Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                Label {
                    id: titleLabel
                    width: parent.width
                    color: listEntry.highlighted ? Theme.highlightColor : Theme.primaryColor
                    wrapMode: Text.WordWrap
                    text: model.title
                }

                Item {
                    id: infoRow
                    width: parent.width
                    height: Math.max( readingTimeIcon.height, readingTimeLabel.height )

                    Row {
                        id: readingTimeRow
                        anchors.left: parent.left

                        Image {
                            id: readingTimeIcon
                            source: "image://theme/icon-s-duration"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            id: readingTimeLabel
                            font.pixelSize: Theme.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.secondaryColor
                            text: " " + model.readingTime
                        }
                    }

                    Label {
                        id: domainLabel
                        anchors.right: parent.right
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                        text: model.domain
                    }
                }
            }

            onClicked: {
                pageStack.push( Qt.resolvedUrl( "ArticlePage.qml" ), model )
            }
        }
    }
}
