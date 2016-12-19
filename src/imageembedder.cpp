#include "imageembedder.h"

#include <QDebug>
#include <QNetworkReply>
#include <QNetworkRequest>

/*
 * ImageEmbedRequest
 */

ImageEmbedRequest::ImageEmbedRequest( QString const& url, QJSValue callback, QObject* parent )
    : QObject( parent ), mUrl( url ), mReply( NULL ), mCallback( callback )
{
}

void ImageEmbedRequest::start()
{
    this->doRequest( mUrl );
}

void ImageEmbedRequest::onFinished()
{
    if ( mReply->error() ) {
        mError = mReply->errorString();
        requestDone();
        return;
    }

    int status = mReply->attribute( QNetworkRequest::HttpStatusCodeAttribute ).toInt();

    if ( status == 301 || status == 302 || status == 303 || status == 307 ) {
        // Welp, we've been redirected, let's see if we can follow it
        if ( !mReply->hasRawHeader( QByteArray( "Location" ) ) ) {
            mError = tr( "Failed to find the image source" );
            requestDone();
            return;
        }

        QString location = mReply->rawHeader( QByteArray( "Location" ) );
        doRequest( location );
    }
    else {
        mContentType = mReply->rawHeader( "Content-Type" );
        QByteArray content = mReply->readAll();
        mEncoded = content.toBase64();
        requestDone();
    }
}

void ImageEmbedRequest::doRequest( QString const& url )
{
    if ( mReply != NULL ) {
        mReply->deleteLater();
        mReply = NULL;
    }

    QNetworkRequest rq( url );
    rq.setRawHeader( QByteArray( "Connection" ), QByteArray( "close" ) );

    mReply = mQnam.get( rq );
    connect( mReply, &QNetworkReply::finished, this, &ImageEmbedRequest::onFinished );
}

void ImageEmbedRequest::requestDone()
{
    QJSValueList args;
    args << mContentType;
    args << mEncoded;
    if ( mError.isEmpty() )
        args << QJSValue::NullValue;
    else
        args << mError;
    mCallback.call( args );
}

/*
 * ImageEmbedder
 */

ImageEmbedder::ImageEmbedder( QObject *parent )
    : QObject( parent )
{
}

void ImageEmbedder::embed( QString const& url, QJSValue callback )
{
    ImageEmbedRequest *rq = new ImageEmbedRequest( url, callback );
    rq->start();
}
