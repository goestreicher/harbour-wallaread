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

Page {
    id: articlePage
    allowedOrientations: Orientation.All

    property string title
    property string content

    SilicaWebView {
        id: webview
        anchors.fill: parent

        Component.onCompleted: {
            loadHtml( wrapArticleContent() )
        }
    }

    function wrapArticleContent() {
        var html =
            "<html>" +
            "<head>" +
                "<style type=\"text/css\">" +
                "article { font-family: sans-serif; font-size: 16px; }" +
                "article h1 { font-size: 32px; }" +
                "</style>" +
            "</head>" +
            "<body>" +
                "<article>" +
                "<h1>" + articlePage.title + "</h1>" +
                articlePage.content +
                "</article>" +
            "</body>" +
            "</html>"

        return html
    }
}
