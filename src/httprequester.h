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

#ifndef HTTPREQUESTER_H
#define HTTPREQUESTER_H

#include <QJSValue>
#include <QNetworkAccessManager>
#include <QObject>
#include <QString>

class HttpBaseRequest : public QObject
{
    Q_OBJECT

public:
    HttpBaseRequest( QString const& url, QString const& token, QJSValue callback );

    virtual void start() = 0;

    QString mUrl;
    QString mToken;
    QJSValue mCallback;

signals:
    void done( QString content, QString error );
};

class HttpPatchRequest : public HttpBaseRequest
{
    Q_OBJECT

public:
    HttpPatchRequest( QString const& url, QString const& token, QString const& content, QJSValue callback );

    virtual void start() override;

    QByteArray mContent;

private slots:
    void onRequestDone();

private:
    QNetworkAccessManager mQnam;
    QIODevice* mContentIO;
    QNetworkReply* mReply;
};

class HttpDeleteRequest : public HttpBaseRequest
{
    Q_OBJECT

public:
    HttpDeleteRequest( QString const& url, QString const& token, QJSValue callback );

    virtual void start() override;

private slots:
    void onRequestDone();

private:
    QNetworkAccessManager mQnam;
    QNetworkReply* mReply;
};

class HttpRequester : public QObject
{
    Q_OBJECT
public:
    explicit HttpRequester( QObject *parent = 0 );

    Q_INVOKABLE void patch( QString const& url, QString const& token, QString const& content, QJSValue callback );
    Q_INVOKABLE void del( QString const& url, QString const& token, QJSValue callback );

private slots:
    void onRequestDone( QString const& content, QString const& error );
};

#endif // HTTPREQUESTER_H
