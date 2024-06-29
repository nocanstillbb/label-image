import QtQuick 2.0
import QtQuick.Window 2.12
import prismCpp 1.0
import prism_qt_ui 1.0
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

import QtQuick.Controls 1.4 as Q1

import Qt.labs.platform 1.1 as QtPlatform

Item {
    property var proj: vm? vm.activeProject:null
    Q1.TabView {
        id:tv
        anchors.fill: parent
        Q1.Tab {
            title: "标注"
            LabelView {}
        }
        Q1.Tab {
            title: "训练"
            TrainView{
                Connections {
                    target: tv
                    onCurrentIndexChanged: {
                        if(tv.currentIndex==1)
                            activeChanged()
                    }
                }
            }
        }
        Q1.Tab {
            title: "预测"
        }
        Q1.Tab {
            title: "测试"
        }
    }
}
