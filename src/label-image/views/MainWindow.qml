import QtQuick 2.15
import QtQuick.Window 2.15
import prism_qt_ui 1.0
import prismCpp 1.0

BorderlessWindow_mac {
    visible: true
    title: qsTr("label image")
    minimumWidth: 1024
    minimumHeight: 720
    contentUrl: CppUtility.transUrl("qrc:/label-image/views/MainContent.qml")

}
