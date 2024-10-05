import QtQuick 2.0
import QtQuick.Window 2.12
import prismCpp 1.0
import prism_qt_ui 1.0
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

import QtQuick.Controls 1.4 as Q1

import Qt.labs.platform 1.1 as QtPlatform

Rectangle {

    property var vm: Window.window.viewModel
    Component.onCompleted: {
        Window.window.width = 600
        Window.window.height = 200
        Window.window.visible = true
    }

    GridLayout {
        anchors.fill: parent
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.topMargin: 40
        anchors.bottomMargin: 80
        columns: 3
        Row {
            height: childrenRect.height
            Text {
                text: qsTr("项目名称:")
                anchors.verticalCenter: parent.Center
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }
            Q1.TextField {
                text: Bind.create(vm.editModel, "name")
                onTextChanged: {
                    vm.editModel.set("name", CppUtility.stdstr(text))

                    var workdir =  vm.editModel.get("workDir")
                    var regex =  /[^\/\\]+$/
                    workdir = workdir.replace(regex,text)
                    vm.editModel.set("workDir",CppUtility.stdstr(workdir))

                }
            }
        }

        Row {
            height: childrenRect.height
            Text {
                text: qsTr("batchs:")
                anchors.verticalCenter: parent.Center
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }
            Q1.SpinBox {
                decimals: 0
                width: 100
                value: Bind.create(vm.editModel, "batchs")
                onValueChanged: {
                    vm.editModel.set("batchs", value)
                }
            }
        }
        Row {
            height: childrenRect.height
            Layout.alignment: Qt.AlignRight
            Text {
                text: qsTr("epochs:")
                anchors.verticalCenter: parent.Center
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }
            Q1.SpinBox {
                decimals: 0
                width: 100
                value: Bind.create(vm.editModel, "epochs")
                onValueChanged: {
                    vm.editModel.set("epochs", value)
                }
            }
        }
        RowLayout {
            Layout.columnSpan: 3
            Q1.TextField {
                readOnly: true
                Layout.fillWidth: true
                text: Bind.create(vm.editModel, "workDir")
                Rectangle {
                    anchors.fill: parent
                    color: Style.gray40
                }
            }
            Q1.Button {
                Layout.fillWidth: false
                text: "选择目录"
                onClicked: {
                    chooseFolderDialog.open()
                }
            }
        }
    }

    Q1.Button {
        text: "保存"
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 40
        onClicked: {
            vm.parentVM.removeAvoidProject = false
            vm.save()
            Window.window.close()
        }
    }

    QtPlatform.FolderDialog {
        id: chooseFolderDialog
        title: qsTr("选择项目目录")
        acceptLabel: qsTr("确定")
        rejectLabel: qsTr("取消")
        onAccepted: {
            vm.editModel.set("workDir", CppUtility.stdstr(
                                 CppUtility.qurl2localfile(folder)+"/"+vm.editModel.get("name")))

        }
    }
}
