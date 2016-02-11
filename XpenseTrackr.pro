TEMPLATE = app

QT += qml quick widgets sql

CONFIG += c++11

SOURCES += main.cpp

RESOURCES += qml.qrc
RESOURCES += /Users/dfranca/workspace/Qt/qml-material/modules/Material.qrc
RESOURCES += /Users/dfranca/workspace/Qt/qml-material/modules/MaterialQtQuick.qrc
RESOURCES += /Users/dfranca/workspace/Qt/qml-material/modules/Icons.qrc
RESOURCES += /Users/dfranca/workspace/Qt/qml-material/modules/FontAwesome.qrc
RESOURCES += /Users/dfranca/workspace/Qt/qml-material/modules/FontRoboto.qrc

QTPLUGIN += qsvg

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH = /Users/dfranca/workspace/Qt/qml-material/modules

# Default rules for deployment.
include(deployment.pri)

