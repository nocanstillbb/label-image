import QtQuick 2.0
import prismCpp 1.0
import prism_qt_ui 1.0
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

BorderlessWindow_mac {
    id: projects_view_root
    width: 480
    height: 640
    maximumWidth: 480
    title: "打开项目"
    color: "white"
    ListView {
        id: lv_projects
        clip: true
        spacing: 0
        anchors.fill: parent
        anchors.topMargin: 30
        model: vm ? vm.appConf.get("projects") : null
        boundsBehavior: ListView.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            id: projects_view_vertical_scrollbar
            width: 8
            active: true
            policy: lv_projects.contentHeight
                    > projects_view_root.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        }

        delegate: Item {
            id: row_root
            clip: true
            height: 60
            width: lv_projects.width - (projects_view_vertical_scrollbar.policy
                                        == ScrollBar.AlwaysOn ? 8 : 0)
            property var rvm: vm.appConf.get("projects").getRowData(model.index)

            property bool isSelected: ListView.isCurrentItem

            //border rect
            Rectangle {
                anchors.fill: parent
                clip: true
                color: row_root.isSelected ? Style.gray50 : ma_row.containsMouse ? Style.gray20 : "transparent"
                border.color: Style.black
                border.width: 1
                anchors.topMargin: -1
                anchors.leftMargin: -1
                anchors.rightMargin: -1
                MouseArea {
                    id: ma_row
                    anchors.fill: parent
                    hoverEnabled: true
                    onPressed: {
                        lv_projects.currentIndex = index
                    }
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: {
                        if (mouse.button == Qt.RightButton) {
                            menu_editProject.popup()
                        }
                    }

                    onDoubleClicked: {

                        vm.openEditProjectWin(rvm)
                        vm.saveProjects()
                    }
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.topMargin: 10
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    //Item {
                    //    Layout.preferredWidth: 24
                    //    Layout.fillHeight: true
                    //    IconButton {
                    //        width: 20
                    //        height: 20
                    //        anchors.centerIn: parent
                    //        anchors.verticalCenterOffset: -7

                    //        mipmap: true
                    //        ToolTip.visible: ma.containsMouse
                    //        ToolTip.text: "激活项目"
                    //        ToolTip.delay: 300
                    //        property var isactived: Bind.create(rvm, "actived")
                    //        color: isactived ? Style.lightblue70 : Style.lightgray70
                    //        hoveredColor: isactived ? Style.lightblue30 : Style.lightgray40
                    //        icon: "qrc:/prism_qt_ui/svg/star.svg"
                    //        onClicked: {
                    //            vm.activeProjectRvm(rvm)
                    //            lv_projects.currentIndex = index
                    //        }
                    //    }
                    //}
                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 15
                            Text {
                                text: Bind.create(row_root.rvm, "name")
                            }
                            Text {
                                text: "batchs:" + Bind.create(row_root.rvm,
                                                              "batchs")
                            }
                            Text {
                                text: "epochs:" + Bind.create(row_root.rvm,
                                                              "epochs")
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: Bind.create(row_root.rvm, "workDir")
                            elide: Text.ElideLeft
                        }
                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }
            }
        }
    }

    IconButton {
        width: 40
        height: 40

        mipmap: true
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: ma.pressed ? 8 : 10
        anchors.bottomMargin: ma.pressed ? 8 : 10
        ToolTip.visible: ma.containsMouse
        ToolTip.text: "添加新项目"
        ToolTip.delay: 300
        color: Style.black100
        hoveredColor: Style.black50
        icon: "qrc:/prism_qt_ui/svg/plush.svg"
        onClicked: {
            var index = vm.addProject()
            vm.saveProjects()
            lv_projects.currentIndex = index
            lv_projects.positionViewAtIndex(index, ListView.Beginning)
        }
    }

    DesktopMenu {
        id: menu_editProject
        showIcon: false
        popupWidth: 200

        DesktopMenuItem {
            text: qsTr("编辑")
            iconMipmap: true
            iconColor: Style.black80
            iconSource: CppUtility.transUrl(
                            "qrc:/prism_qt_ui/svg/menu_edit.svg")
            onTriggered: {
                if (!vm)
                    return
                var m = vm.appConf.get("projects")
                var r = m.getRowData(lv_projects.currentIndex)
                vm.openEditProjectWin(r)
                vm.saveProjects()
            }
        }
        DesktopMenuItem {
            text: qsTr("删除")
            iconMipmap: true
            iconColor: Style.black80
            iconSource: CppUtility.transUrl(
                            "qrc:/prism_qt_ui/svg/menu_delete.svg")
            onTriggered: {
                if (!vm)
                    return
                vm.removeProject(lv_projects.currentIndex)
                vm.saveProjects()
            }
        }
        DesktopMenuItem {
            text: qsTr("打开项目")
            iconMipmap: true
            iconColor: Style.black80
            iconSource: CppUtility.transUrl(
                            "qrc:/prism_qt_ui/svg/menu_delete.svg")
            onTriggered: {
                if (!vm)
                    return
                var m = vm.appConf.get("projects")
                var r = m.getRowData(lv_projects.currentIndex)
                vm.activeProjectRvm(r)
                projects_view_root.close()
            }
        }
    }
}
