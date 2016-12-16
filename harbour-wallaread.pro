# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-wallaread

CONFIG += sailfishapp c++11

SOURCES += src/harbour-wallaread.cpp \
    src/httprequester.cpp

OTHER_FILES += qml/harbour-wallaread.qml \
    qml/cover/CoverPage.qml \
    rpm/harbour-wallaread.changes.in \
    rpm/harbour-wallaread.spec \
    rpm/harbour-wallaread.yaml \
    translations/*.ts \
    harbour-wallaread.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-wallaread-de.ts

HEADERS += \
    src/httprequester.h

DISTFILES += \
    qml/js/WallaBase.js \
    qml/models/ArticlesModel.qml \
    qml/models/ServersModel.qml \
    qml/pages/ArticlePage.qml \
    qml/pages/ServerPage.qml \
    qml/pages/ServerSettingsDialog.qml \
    qml/pages/ServersPage.qml \
    qml/pages/SettingsPage.qml \
    qml/types/Server.qml \
    qml/types/ServerSettings.qml
