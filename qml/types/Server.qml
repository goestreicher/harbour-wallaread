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
import net.kamago.harbour.wallaread 1.0

import "../js/WallaBase.js" as WallaBase

Item {
    property int serverId: -1
    property string name
    property string url
    property int lastSync: 0
    property string accessToken
    property string refreshToken
    property string tokenType
    property int tokenExpiry: 0

    signal articlesDownloaded( var list )
    signal connected
    signal error( string message )

    onServerIdChanged: {
        if ( serverId !== -1 ) {
            console.debug( "Loading information for server " + serverId )
            WallaBase.getServer( serverId, onServerLoaded )
        }
        else {
            name = null
            url = null
            lastSync = 0
            accessToken = null
            refreshToken = null
            tokenType = null
            tokenExpiry = 0
        }
    }

    HttpRequester {
        id: httpRequester
    }

    function onServerLoaded( props, err ) {
        if ( err !== null ) {
            error( qsTr( "Failed to load server information: " ) + err )
        }
        else {
            name = props.name
            url = props.url
            lastSync = props.lastSync
        }
    }

    function connect( cb ) {
        var now = Math.floor( (new Date).getTime() / 1000 )
        if ( tokenExpiry <= now ) {
            console.debug( "Opening connection for server " + serverId )
            WallaBase.connectToServer(
                serverId,
                function( props, err ) {
                    onConnectionDone( props, err, cb )
                }
            )
        }
        else {
            cb( null );
        }
    }

    function onConnectionDone( props, err, cb ) {
        if ( err === null ) {
            console.debug( "Successfully connected to server " + serverId )
            accessToken = props.access_token
            refreshToken = props.refresh_token
            tokenType = props.token_type
            tokenExpiry = Math.floor( (new Date).getTime() / 1000 ) + props.expires_in
        }

        cb( err )
    }

    function isConnected() {
        return tokenExpiry > Math.floor( (new Date).getTime() / 1000 )
    }

    function getArticles() {
        connect(
            function( err ) {
                if ( err !== null ) {
                    error( qsTr( "Failed to connect to server: " ) + err)
                }
                else {
                    console.debug( "Downloading articles changes since last sync" )
                    var props = { url: url, since: lastSync, accessToken: accessToken }
                    WallaBase.downloadArticles( props, onGetArticlesDone )
                }
            }
        )
    }

    function onGetArticlesDone( articles, err ) {
        if ( err !== null ) {
            error( qsTr( "Failed to download articles: " ) + err )
        }
        else {
            console.debug( "Retrieved " + articles.length + " new/updated articles" )
            var ret = new Array

            for ( var i = 0; i < articles.length; ++i ) {
                var current = articles[i];
                var article = {
                    id: current.id,
                    server: serverId,
                    created: current.created_at,
                    updated: current.updated_at,
                    mimetype: current.mimetype,
                    language: current.language,
                    readingTime: current.reading_time,
                    url: current.url,
                    domain: current.domain_name,
                    archived: current.is_archived,
                    starred: current.is_starred,
                    title: current.title,
                    previewPicture: current.previewPicture,
                    content: current.content
                }
                WallaBase.saveArticle( article )
                ret.push( article )
            }

            WallaBase.setServerLastSync( serverId, Math.floor( (new Date).getTime() / 1000 ) )
            articlesDownloaded( ret )
        }
    }

    function toggleArticleStar( article, cb ) {
        connect(
            function( err ) {
                if ( err !== null ) {
                    cb( null, qsTr( "Failed to connect to server: " ) + err );
                }
                else {
                    var articleUrl = url
                    if ( articleUrl.charAt( articleUrl.length - 1 ) !== "/" )
                        articleUrl += "/"
                    articleUrl += "api/entries/" + article.id + ".json"

                    var json = {}
                    json.starred = ( article.starred ? 0 : 1 )

                    console.debug( "Setting starred to " + json.starred + " on article " + article.id )

                    httpRequester.patch(
                        articleUrl,
                        accessToken,
                        JSON.stringify( json ),
                        function( patchResponse, patchError ) {
                            onToggleArticleStarDone( patchResponse, patchError, article, cb )
                        }
                    )
                }
            }
        )
    }

    function onToggleArticleStarDone( content, err, article, cb ) {
        if ( err !== null ) {
            cb( null, qsTr( "Failed to set star status on article: " ) + err )
        }
        else {
            console.debug( "Done toggling starred status for article " + article.id )
            var json = JSON.parse( content )
            WallaBase.setArticleStar( article.id, json.is_starred )
            cb( json.is_starred, null )
        }
    }

    function toggleArticleRead( article, cb ) {
        connect(
            function( err ) {
                if ( err !== null ) {
                    cb( null, qsTr( "Failed to connect to server: " ) + err )
                }
                else {
                    var articleUrl = url
                    if ( articleUrl.charAt( articleUrl.length - 1 ) !== "/" )
                        articleUrl += "/"
                    articleUrl += "api/entries/" + article.id + ".json"

                    var json = {}
                    json.archive = ( article.archived ? 0 : 1 )

                    console.debug( "Setting archived to " + json.archived + " on article " + article.id )

                    httpRequester.patch(
                        articleUrl,
                        accessToken,
                        JSON.stringify( json ),
                        function( patchResponse, patchError ) {
                            onToggleArticleReadDone( patchResponse, patchError, article, cb )
                        }
                    )
                }
            }
        )
    }

    function onToggleArticleReadDone( content, err, article, cb ) {
        if ( err !== null ) {
            cb( null, qsTr( "Failed to set read status on article: " ) + err )
        }
        else {
            console.debug( "Done toggling archived status for article " + article.id )
            var json = JSON.parse( content )
            WallaBase.setArticleRead( article.id, json.is_archived )
            cb( json.is_archived, null )
        }
    }

    function deleteArticle( id, cb ) {
        connect(
            function( err ) {
                if ( err !== null ) {
                    cb( qsTr( "Failed to connect to server: " ) + err )
                }
                else {
                    var articleUrl = url
                    if ( articleUrl.charAt( articleUrl.length - 1 ) !== "/" )
                        articleUrl += "/"
                    articleUrl += "api/entries/" + id + ".json"

                    console.debug( "Deleting article " + id )

                    httpRequester.del(
                        articleUrl,
                        accessToken,
                        function( delResponse, delError ) {
                            onDeleteArticleDone( delResponse, delError, id, cb )
                        }

                    )
                }
            }
        )
    }

    function onDeleteArticleDone( content, err, id, cb ) {
        if ( err !== null ) {
            cb( qsTr( "Failed to delete article: " ) + err )
        }
        else {
            console.debug( "Done deleting article " + id )
            WallaBase.deleteArticle( id )
            cb( null )
        }
    }
}
