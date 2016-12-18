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

.pragma library
.import QtQuick.LocalStorage 2.0 as Storage

/*
  Exposed variable
 */

var ArticlesFilter = {
    All: 1,
    Read: 2,
    Starred: 4
}

/*
  Servers management
 */

function getServers( cb )
{
    var db = getDatabase();

    db.readTransaction(
        function( tx ) {
            var servers = new Array;
            var err = null;

            try {
                var res = tx.executeSql( "SELECT id, name FROM servers ORDER BY NAME" );
                for ( var i = 0; i < res.rows.length; ++i ) {
                    var current = res.rows.item( i );
                    var server = { id: current.id, name: current.name, unread: 0 };
                    var countRes = tx.executeSql( "SELECT COUNT(*) as count FROM articles WHERE server=? AND archived=0", [ current.id ] );
                    server.unread = countRes.rows[0].count;
                    servers.push( server );
                }
            }
            catch( e ) {
                err = e.message;
            }

            cb( servers, err );
        }
    );
}

function getServer( id, cb )
{
    var err = null;
    var db = getDatabase();

    db.readTransaction(
        function( tx ) {
            var server = null;
            try {
                var res = tx.executeSql( "SELECT id, name, url, lastSync FROM servers WHERE id=?", [ id ] );
                if ( res.rows.length === 0 ) {
                    err = "No server with this ID found";
                }
                else {
                    server = res.rows.item( 0 );
                }
            }
            catch( e ) {
                err = e.message;
            }

            cb( server, err );
        }
    );
}

function getServerSettings( id, cb )
{
    var err = null;
    var db = getDatabase();

    db.readTransaction(
        function( tx ) {
            var server = null;
            try {
                var res = tx.executeSql( "SELECT * FROM servers WHERE id=?", [ id ] );
                if ( res.rows.length === 0 ) {
                    err = "No server with this ID found";
                }
                else {
                    server = res.rows.item( 0 );
                }
            }
            catch( e ) {
                err = e.message;
            }

            cb( server, err );
        }
    );
}

function addNewServer( props )
{
    var db = getDatabase();

    db.transaction(
        function( tx ) {
            // TODO: try/catch here when error management is in place in the UI
            tx.executeSql( "INSERT INTO servers(name, url, user, password, clientId, clientSecret) VALUES(?, ?, ?, ?, ?, ?)",
                           [
                              props.name,
                              props.url,
                              props.user,
                              props.password,
                              props.clientId,
                              props.clientSecret
                           ]
                         );
        }
    );
}

function updateServer( id, props )
{
    var db = getDatabase();

    db.transaction(
        function( tx ) {
            // TODO: try/catch here when error management is in place in the UI
            tx.executeSql( "UPDATE servers SET " +
                           "name=?, " +
                           "url=?, " +
                           "user=?, " +
                           "password=?, " +
                           "clientId=?, " +
                           "clientSecret=? " +
                           "WHERE id=?",
                           [
                              props.name,
                              props.url,
                              props.user,
                              props.password,
                              props.clientId,
                              props.clientSecret,
                              id
                           ]
                         );
        }
    );
}

function deleteServer( id )
{
    var db = getDatabase();

    db.transaction(
        function( tx ) {
            console.debug( "Deleting server " + id );
            // TODO: try/catch here when error management is in place in the UI
            tx.executeSql( "DELETE FROM articles WHERE server=?", [ id ] );
            tx.executeSql( "DELETE FROM servers WHERE id=?", [ id ] );
        }
    );
}

function setServerLastSync( id, last )
{
    var db = getDatabase();

    db.transaction(
        function( tx ) {
            tx.executeSql( "UPDATE servers SET lastSync=? WHERE id=?", [ last, id ] );
        }

    )
}

function connectToServer( id, cb )
{
    var db = getDatabase();

    db.readTransaction(
        function( tx ) {
            var err = null;
            try {
                var res = tx.executeSql( "SELECT url, user, password, clientId, clientSecret FROM servers WHERE id=?", [ id ] );
                if ( res.rows.length === 0 ) {
                    err = "No server with ID " + id + " found";
                }
                else {
                    _sendAuthRequest( res.rows.item( 0 ), cb );
                }
            }
            catch( e ) {
                err = e.message;
            }

            if ( err !== null )
                cb( null, err );
        }
    );
}

function _sendAuthRequest( props, cb )
{
    var url = props.url;
    if ( url.charAt( url.length - 1 ) !== "/" )
        url += "/";
    url += "oauth/v2/token";
    console.debug( "Sending auth request to " + url );

    var http = new XMLHttpRequest();
    var params = "grant_type=password";
    params += "&username=" + escape( props.user );
    params += "&password=" + escape( props.password );
    params += "&client_id=" + escape( props.clientId );
    params += "&client_secret=" + escape( props.clientSecret );

    http.onreadystatechange = function() {
        if ( http.readyState === XMLHttpRequest.DONE ) {
            console.debug( "Auth request response status is " + http.status );
            var json = null;
            var err = null;

            if ( http.status === 200 ) {
                try {
                    json = JSON.parse( http.responseText )
                }
                catch( e ) {
                    json = null;
                    err = "Failed to parse server response: " + e.message
                }
            }
            else {
                if ( http.responseText.length ) {
                    try {
                        json = JSON.parse( http.responseText )
                    }
                    catch( e ) {
                        json = http.responseText
                    }
                }

                err = "HTTP request failed: " + http.status;
            }

            cb( json, err );
        }
    };

    http.open( "POST", url, true );
    http.setRequestHeader( "Content-type", "application/x-www-form-urlencoded" );
    http.setRequestHeader( "Content-length", params.length );
    http.setRequestHeader( "Connection", "close" );

    http.send( params );
}

/*
  Articles management
 */

function syncDeletedArticles( timerSource, props, cb )
{
    var db = getDatabase();

    db.readTransaction(
        function( tx ) {
            var res = tx.executeSql( "SELECT id, url FROM articles WHERE server=?", [ props.id ] );
            var articles = new Array;

            for ( var i = 0; i < res.rows.length; ++i ) {
                articles.push( res.rows[i] );
            }

            var working = false;

            function processArticlesList() {
                if ( !working && articles.length === 0 ) {
                    cb();
                }
                else {
                    if ( !working )
                        timerSource.setTimeout( _checkNextArticle, 100 );
                    timerSource.setTimeout( processArticlesList, 500 );
                }
            }

            function _checkNextArticle() {
                working = true;
                var article = articles.pop();

                var url = props.url;
                if ( url.charAt( url.length - 1 ) !== "/" )
                    url += "/";
                url += "api/entries/exists.json";

                var params = "url=";
                params += encodeURIComponent( article.url );
                url += "?" + params;

                var http = new XMLHttpRequest;

                http.onreadystatechange = function() {
                    if ( http.readyState === XMLHttpRequest.DONE ) {
                        console.debug( "Checking if article " + article.id + " exists, response status is " + http.status );
                        var json = null;

                        if ( http.status === 200 ) {
                            try {
                                json = JSON.parse( http.responseText )
                            }
                            catch( e ) {
                                json = null;
                            }

                            if ( !json.exists ) {
                                console.debug( "Article " + article.id + " has been deleted" );
                                deleteArticle( props.id, article.id );
                            }
                        }
                        // In case of error let's assume that the article exists

                        working = false;
                    }
                };

                http.open( "GET", url, true );
                http.setRequestHeader( "Authorization:", "Bearer " + props.token );
                http.setRequestHeader( "Accept", "application/json" );
                http.setRequestHeader( "Connection", "close" );

                http.send();
            }

            timerSource.setTimeout( processArticlesList, 500 );
        }
    );
}

function getArticles( serverId, cb, filter )
{
    var db = getDatabase();

    db.readTransaction(
        function( tx ) {
            var articles = new Array
            var err = null;
            var where = "";

            if ( filter & ArticlesFilter.Read )
                where += " AND archived=1";
            else
                where += " AND archived=0";

            if ( filter & ArticlesFilter.Starred )
                where += " AND starred=1";

            try {
                var res = tx.executeSql( "SELECT * FROM articles WHERE server=?" + where, [ serverId ] );
                for ( var i = 0; i < res.rows.length; ++i ) {
                    articles.push( res.rows[i] );
                }
            }
            catch( e ) {
            }

            cb( articles, err );
        }
    );
}

function articleExists( server, id, cb )
{
    var db = getDatabase();

    db.readTransaction(
        function( tx ) {
            var exists = false;
            var err = null;

            try {
                var res = tx.executeSql( "SELECT COUNT(*) AS count FROM articles WHERE id=? AND server=?", [ id, server ] );
                if ( res.rows.length === 1 ) {
                    exists = ( res.rows[0].count === 0 ? false : true );
                }
                else {
                    err = "Failed to get article from database when checking its existence";
                }
            }
            catch( e ) {
                err = e.message;
            }

            cb( exists, err );
        }
    );
}

function saveArticle( props )
{
    articleExists(
        props.server,
        props.id,
        function( exists, err ) {
            if ( err !== null ) {
                // TODO: if a callback is used to notify the caller of an error
                //   then in Server.qml the articles will have to be reported individually
                //   through a signal / slot mechanism
            }
            else {
                if ( exists )
                    _updateArticle( props );
                else
                    _insertArticle( props );
            }
        }

    );
}

function _insertArticle( props )
{
    var db = getDatabase();

    db.transaction(
        function( tx ) {
            tx.executeSql(
                            "INSERT INTO articles(id,server,created,updated,mimetype,language,readingTime,url,domain,archived,starred,title,content) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)",
                            [
                                props.id,
                                props.server,
                                props.created,
                                props.updated,
                                props.mimetype,
                                props.language,
                                props.readingTime,
                                props.url,
                                props.domain,
                                props.archived,
                                props.starred,
                                props.title,
                                props.content
                            ]
                         );
        }
    );
}

function _updateArticle( props )
{
    var db = getDatabase();

    db.transaction(
        function( tx ) {
            tx.executeSql(
                            "UPDATE articles SET created=?, updated=?, mimetype=?, language=?, readingTime=?, url=?, domain=?, archived=?, starred=?, title=?, content=? WHERE id=? AND server=?",
                            [
                                props.created,
                                props.updated,
                                props.mimetype,
                                props.language,
                                props.readingTime,
                                props.url,
                                props.domain,
                                props.archived,
                                props.starred,
                                props.title,
                                props.content,
                                props.id,
                                props.server
                            ]
                         );
        }
    );
}

function deleteArticle( server, id )
{
    var db = getDatabase();

    db.transaction(
        function( tx ) {
            console.debug( "Delete article " + id + " from database" );
            tx.executeSql( "DELETE FROM articles WHERE id=? AND server=?", [ id, server ] );
        }
    );
}

function downloadArticles( props, cb )
{
    var url = props.url;
    if ( url.charAt( url.length - 1 ) !== "/" )
        url += "/";
    url += "api/entries.json";
    url += "?since=" + props.since;
    url += "&perPage=10";

    var articles = new Array;

    _downloadNextArticles(
        url,
        props.accessToken,
        1,
        function( arts, done, err ) {
            if ( err !== null ) {
                cb( null, err )
            }
            else {
                if ( arts.length )
                    articles.push.apply( articles, arts );
                if ( done )
                    cb( articles, null );
            }
        }
    );
}

function _downloadNextArticles( url, token, page, cb )
{
    var pageUrl = url;
    pageUrl += "&page=" + page;
    console.debug( "Getting articles at " + pageUrl );

    var http = new XMLHttpRequest();

    http.onreadystatechange = function() {
        if ( http.readyState === XMLHttpRequest.DONE ) {
            console.debug( "Articles download status code is " + http.status )
            var json = null;
            var articles = null;
            var done = true;
            var err = null;

            if ( http.status === 200 ) {
                try {
                    json = JSON.parse( http.responseText )
                    articles = json._embedded.items;
                    if ( page < json.pages )
                        done = false;
                }
                catch( e ) {
                    json = null;
                    err = "Failed to parse server response: " + e.message
                }
            }
            else {
                if ( http.responseText.length ) {
                    try {
                        articles = JSON.parse( http.responseText )
                    }
                    catch( e ) {
                        articles = http.responseText
                    }
                }

                err = "HTTP request failed: " + http.status;
            }

            cb( articles, done, err );

            if ( !done )
                _downloadNextArticles( url, token, page+1, cb );
        }
    }

    http.open( "GET", pageUrl, true );
    http.setRequestHeader( "Authorization:", "Bearer " + token );
    http.setRequestHeader( "Accept", "application/json" );
    http.setRequestHeader( "Connection", "close" );

    http.send();
}

function setArticleStar( server, id, star )
{
    var db = getDatabase();

    db.transaction(
        function( tx ) {
            tx.executeSql( "UPDATE articles SET starred=? WHERE id=? AND server=?", [ star, id, server ] );
        }
    );
}

function setArticleRead( server, id, read )
{
    var db = getDatabase();

    db.transaction(
        function( tx ) {
            tx.executeSql( "UPDATE articles SET archived=? WHERE id=? AND server=?", [ read, id, server ] );
        }
    );
}

/*
  Internal functions
 */

var DBVERSION = "0.3"
var _db = null;

function getDatabase()
{
    if ( _db === null ) {
        console.debug( "Opening new connection to the database" );
        _db = Storage.LocalStorage.openDatabaseSync( "WallaRead", "", "WallaRead", 1000000 );
        checkDatabaseStatus( _db );
    }

    return _db;
}

function checkDatabaseStatus( db )
{
    if ( db.version === "" ) {
        createLatestDatabase( db );
    }
    else if ( db.version === "0.2" ) {
        _updateSchema_v3( db );
    }
}

function createLatestDatabase( db )
{
    var version = db.version;

    if ( version !== DBVERSION ) {
        db.transaction(
            function( tx ) {
                tx.executeSql( "CREATE TABLE IF NOT EXISTS servers (" +
                               "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                               "name TEXT NOT NULL, " +
                               "url TEXT NOT NULL, " +
                               "user TEXT NOT NULL, " +
                               "password TEXT NOT NULL, " +
                               "clientId TEXT NOT NULL, " +
                               "clientSecret TEXT NOT NULL, " +
                               "lastSync INTEGER DEFAULT 0" +
                               ")"
                             );

                tx.executeSql(
                                "CREATE TABLE IF NOT EXISTS articles (" +
                                "id INTEGER, " +
                                "server INTEGER REFERENCES servers(id), " +
                                "created TEXT, " +
                                "updated TEXT, " +
                                "mimetype TEXT, " +
                                "language TEXT, " +
                                "readingTime INTEGER DEFAULT 0, " +
                                "url TEXT, " +
                                "domain TEXT, " +
                                "archived INTEGER DEFAULT 0, " +
                                "starred INTEGER DEFAULT 0, " +
                                "title TEXT, " +
                                "previewPicture BLOB, " +
                                "content TEXT, " +
                                "PRIMARY KEY(id, server)" +
                                ")"
                             );

                db.changeVersion( version, DBVERSION );
            }
        );
    }
}

function resetDatabase()
{
    var db = getDatabase();
    var version = db.version;

    db.transaction(
        function( tx ) {
            tx.executeSql( "DROP TABLE IF EXISTS servers" );
            tx.executeSql( "DROP TABLE IF EXISTS articles" );
            db.changeVersion( version, "" );
            createLatestDatabase( db );
        }
    );
}

function _updateSchema_v3( db )
{
    db.transaction(
        function( tx ) {
            tx.executeSql(
                            "CREATE TABLE IF NOT EXISTS articles_next (" +
                            "id INTEGER, " +
                            "server INTEGER REFERENCES servers(id), " +
                            "created TEXT, " +
                            "updated TEXT, " +
                            "mimetype TEXT, " +
                            "language TEXT, " +
                            "readingTime INTEGER DEFAULT 0, " +
                            "url TEXT, " +
                            "domain TEXT, " +
                            "archived INTEGER DEFAULT 0, " +
                            "starred INTEGER DEFAULT 0, " +
                            "title TEXT, " +
                            "previewPicture BLOB, " +
                            "content TEXT, " +
                            "PRIMARY KEY(id, server)" +
                            ")"
                         );
            tx.executeSql( "INSERT INTO articles_next SELECT * FROM articles" );
            tx.executeSql( "DROP TABLE articles" );
            tx.executeSql( "ALTER TABLE articles_next RENAME TO articles" );
        },
        function() {
        },
        function() {
            db.changeVersion( version, "0.3" );
        }
    );
}
