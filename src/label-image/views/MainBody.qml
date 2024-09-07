import QtQuick 2.0
import QtQuick.Controls 2.12
import QtQuick.Controls 1.4 as Q1
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.12
import prismCpp 1.0
import prism_qt_ui 1.0
import "."

//Q1.SplitView {
//    orientation: Qt.Horizontal
//    //项目管理视图
//    ProjectPropertiesView {
//        id: view_project
//        width: 300
//        Layout.minimumWidth: 300
//    }
//}
//项目视图
Item {
    LiveLoader {
        anchors.fill: parent
        property var proj: vm? vm.activeProject :null
        onProjChanged: {
            if (proj) {
                source = CppUtility.transUrl(
                            "qrc:/label-image/views/WorkView.qml")
                updateUrl()
            } else {
                source = "qrc:/label-image/views/NoneProject.qml"
                updateUrl()
            }
        }
    }
}
