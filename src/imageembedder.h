#ifndef IMAGEEMBEDDER_H
#define IMAGEEMBEDDER_H

#include <QJSValue>
#include <QNetworkAccessManager>
#include <QObject>

class ImageEmbedRequest : public QObject
{
    Q_OBJECT

public:
    ImageEmbedRequest( QString const& url, QJSValue callback, QObject *parent = 0 );

    void start();

private slots:
    void onFinished();

private:
    void doRequest( QString const& url );
    void requestDone();

    QString mUrl;
    QNetworkAccessManager mQnam;
    QNetworkReply* mReply;
    QJSValue mCallback;
    QString mContentType;
    QString mEncoded;
    QString mError;
};

class ImageEmbedder : public QObject
{
    Q_OBJECT

public:
    explicit ImageEmbedder( QObject *parent = 0 );

    Q_INVOKABLE void embed( QString const& url, QJSValue callback );
};

#endif // IMAGEEMBEDDER_H
