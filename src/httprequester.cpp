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

#include "httprequester.h"

#include <QBuffer>
#include <QJSValueList>
#include <QNetworkReply>
#include <QNetworkRequest>

/*
 * HttpBaseRequest
 */

HttpBaseRequest::HttpBaseRequest( QString const& url, QString const& token, QJSValue callback )
    : mUrl( url ), mToken( token ), mCallback( callback )
{
}

/*
 * HttpPatchRequest
 */

HttpPatchRequest::HttpPatchRequest( QString const& url, QString const& token, QString const& content, QJSValue callback )
    : HttpBaseRequest( url, token, callback ), mContent( content.toUtf8() ), mReply( NULL )
{
    mContentIO = new QBuffer( &mContent, this );
}

void HttpPatchRequest::start()
{
    QByteArray authHeader( "Bearer " );
    authHeader.append( mToken );

    QNetworkRequest rq( mUrl );
    rq.setRawHeader( QByteArray( "Authorization" ), authHeader );
    rq.setRawHeader( QByteArray( "Accept" ), QByteArray( "application/json" ) );
    rq.setHeader( QNetworkRequest::ContentLengthHeader, mContent.length() );
    rq.setHeader( QNetworkRequest::ContentTypeHeader, QStringLiteral( "application/json" ) );
    rq.setRawHeader( QByteArray( "Connection" ), QByteArray( "close" ) );

    mReply = mQnam.sendCustomRequest( rq, QByteArray( "PATCH" ), mContentIO );
    connect( mReply, &QNetworkReply::finished, this, &HttpPatchRequest::onRequestDone );
}

void HttpPatchRequest::onRequestDone()
{
    QString content;
    QString error;

    if ( mReply->error() ) {
        error = "Network error: ";
        error.append( mReply->errorString() );
    }
    else {
        content = QString( mReply->readAll() );
    }

    mReply->deleteLater();
    mReply = NULL;

    emit done( content, error );
}

/*
 * HttpDeleteRequest
 */

HttpDeleteRequest::HttpDeleteRequest( QString const& url, QString const& token, QJSValue callback )
    : HttpBaseRequest( url, token, callback )
{
}

void HttpDeleteRequest::start()
{
    QByteArray authHeader( "Bearer " );
    authHeader.append( mToken );

    QNetworkRequest rq( mUrl );
    rq.setRawHeader( QByteArray( "Authorization" ), authHeader );
    rq.setRawHeader( QByteArray( "Accept" ), QByteArray( "application/json" ) );
    rq.setRawHeader( QByteArray( "Connection" ), QByteArray( "close" ) );

    mReply = mQnam.sendCustomRequest( rq, QByteArray( "DELETE" ) );
    connect( mReply, &QNetworkReply::finished, this, &HttpDeleteRequest::onRequestDone );
}

void HttpDeleteRequest::onRequestDone()
{
    QString content;
    QString error;

    if ( mReply->error() ) {
        error = "Network error: ";
        error.append( mReply->errorString() );
    }

    mReply->deleteLater();
    mReply = NULL;

    emit done( content, error );
}

/*
 * HttpRequester
 */

HttpRequester::HttpRequester( QObject *parent )
    : QObject( parent )
{
}

void HttpRequester::patch( QString const& url, QString const& token, QString const& content, QJSValue callback )
{
    HttpPatchRequest *req = new HttpPatchRequest( url, token, content, callback );
    connect( req, &HttpPatchRequest::done, this, &HttpRequester::onRequestDone );
    req->start();
}

void HttpRequester::del( QString const& url, QString const& token, QJSValue callback )
{
    HttpDeleteRequest *req = new HttpDeleteRequest( url, token, callback );
    connect( req, &HttpDeleteRequest::done, this, &HttpRequester::onRequestDone );
    req->start();
}

void HttpRequester::onRequestDone( QString const& content, QString const& error )
{
    HttpBaseRequest *req = qobject_cast<HttpBaseRequest*>( QObject::sender() );
    QJSValueList args;
    args << content;
    if ( error.isEmpty() )
        args << QJSValue::NullValue;
    else
        args << error;
    req->mCallback.call( args );
    req->deleteLater();
}
