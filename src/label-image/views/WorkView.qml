import QtQuick 2.0
import QtQuick.Window 2.12
import prismCpp 1.0
import prism_qt_ui 1.0
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

import QtQuick.Controls 1.4 as Q1
import QtQuick.Controls.Styles 1.4

import Qt.labs.platform 1.1 as QtPlatform

Item {
    property var proj: vm? vm.activeProject:null
    Q1.TabView {
        //enabled: !Bind.create(proj,"isbusy")
        id:tv
        currentIndex: vm.mainTabIndex
        onCurrentIndexChanged: {
            if(vm.mainTabIndex!== currentIndex)
            {
                vm.mainTabIndex = tv.currentIndex
            }
        }
        anchors.fill: parent
        style: TabViewStyle {
            frameOverlap: -5
            tab: Rectangle {
                color: styleData.selected ? "steelblue" :"lightsteelblue"
                border.color:  "steelblue"
                implicitWidth: Math.max(text.width + 4, 80)
                implicitHeight: 20
                radius: 2
                Text {
                    id: text
                    anchors.centerIn: parent
                    text: styleData.title
                    color: styleData.selected ? "white" : "black"
                }
            }
            frame: Rectangle { color: "white" }
        }


        Q1.Tab {
            title: "标注/预测"
            LiveLoader{
                id:ld_labelview
                source: CppUtility.transUrl("qrc:/label-image/views/LabelView.qml")
                showButton: true
            }
        }
        Q1.Tab {
            title: "训练"
            LiveLoader{
                id:ld_trainView
                source: CppUtility.transUrl("qrc:/label-image/views/TrainView.qml")
                showButton: true
                Connections {
                    target: tv
                    onCurrentIndexChanged: {
                        if(tv.currentIndex==1)
                            ld_trainView.activeChanged() //当切换时,获取键盘焦点
                    }
                }
            }
        }
        //Q1.Tab{
        //    title: "预测"
        //    LiveLoader{
        //        id:ld_predictView
        //        source: CppUtility.transUrl("qrc:/label-image/views/PredictView.qml")
        //        showButton: true
        //    }
        //}
        //Q1.Tab {
        //    title: "模型转换"
        //    TransModelView{}
        //}
    }

    Rectangle{
        z:100
        anchors.fill: parent
        visible:  Bind.create(proj,"isbusy")
        color: "#33ffffff"
        BusyIndicator{
            width: 100
            height: 100
            anchors.centerIn: parent
            running: Bind.create(proj,"isbusy")
        }
    }
}
