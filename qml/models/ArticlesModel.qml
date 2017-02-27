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

ListModel {
    id: articlesModel

    property bool loaded: false
    property bool showAll: false
    property bool showRead: false
    property bool showStarred: false
    property int sortOrder: WallaBase.ArticlesSort.Created
    property bool sortAsc: true

    signal error( string message )

    function load( serverId ) {
        loaded = false
        var filter = 0;

        if ( showAll ) {
            filter = WallaBase.ArticlesFilter.All
        }
        else {
            if ( showRead )
                filter |= WallaBase.ArticlesFilter.Read

            if ( showStarred )
                filter |= WallaBase.ArticlesFilter.Starred
        }

        WallaBase.getArticles( serverId, onArticlesLoaded, filter, sortOrder, sortAsc )
    }

    function onArticlesLoaded( articles, err ) {
        loaded = true
        if ( err !== null ) {
            error( err )
        }
        else {
            clear()
            for ( var i = 0; i < articles.length; ++i ) {
                append( articles[i] )
            }
        }
    }
}
