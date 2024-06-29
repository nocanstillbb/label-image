import QtQuick 2.0
import QtQuick.Window 2.12
import prismCpp 1.0
import prism_qt_ui 1.0
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls 1.4 as Q1
import QtQuick.Controls.Styles 1.4
import Qt.labs.platform 1.1 as QtPlatform

Rectangle {
    ColumnLayout {
        anchors.fill: parent
        Q1.SplitView {
            id: sp_view
            orientation: Qt.Vertical
            Layout.fillHeight: true
            Layout.fillWidth: true
            Item{
                Layout.margins: 5
                Layout.fillWidth: true
                Layout.fillHeight: true
                Q1.SplitView {
                    anchors.fill: parent
                    anchors.bottomMargin: 15
                    orientation: Qt.Horizontal
                    Item{
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Renderer {
                            anchors.fill: parent
                            id:renderer
                            Layout.bottomMargin: 15
                            Component.onCompleted: {
                                vm.label_img_buf_sn = CppUtility.getguid()
                                setCamSn(vm.label_img_buf_sn)
                            }
                            onInited_background: {
                                vm.displayFirstImg()
                            }
                            releaseBuferAfterRender: false
                            property int fw:100
                            property int fh:100
                            onFrameSizeChanged: function(w,h){
                                fw = w
                                fh = h
                            }

                            VideoCanvas{
                                frameHeight:  renderer.fh
                                frameWidth: renderer.fw
                                roi_height: frameHeight
                                roi_width: frameWidth
                                roi_x:  0
                                roi_y:  0
                                strokeColor: Bind.create(lv_labels.model_labels.getRowData(lv_labels.currentIndex),"color")??"red"
                                onDrawCompleted: function(x,y,w,h)
                                {
                                    if(lv_labels.currentIndex <0)
                                        return
                                    if(w <10  && h < 10)
                                        return
                                    vm.add_nms_box(rep_boxs.boxs_model,x,y,w,h,lv_labels.currentIndex)
                                }
                            }
                            Repeater{
                                id:rep_boxs
                                property var boxs_model: Bind.create(lv_train_imgs.currentRvm,"nms_boxs")
                                model: boxs_model
                                property var currentIndex
                                delegate:VideoROI2 {
                                    id:roi_root
                                    property var box_rvm: rep_boxs.boxs_model.getRowData(index)
                                    property int classificationid : Bind.create(box_rvm,"classificationId") ?? -1
                                    property var label_rvm: lv_labels.model_labels.getRowData(classificationid)
                                    color: "transparent"
                                    borderWidth: 2
                                    frameHeight:  renderer.fh
                                    frameWidth: renderer.fw

                                    Component.onCompleted: {
                                        mouseArea_drag.forceActiveFocus()
                                        //console.log(classificationid)
                                    }

                                    roi_x:(Bind.create(box_rvm,"x"))??0
                                                                       onRoi_xChanged: if(box_rvm)  box_rvm.set("x",roi_x)

                                    roi_y:(Bind.create(box_rvm,"y"))??0
                                                                       onRoi_yChanged: if(box_rvm) box_rvm.set("y",roi_y)

                                    roi_width:(Bind.create(box_rvm,"width"))??0
                                                                               onRoi_widthChanged: if(box_rvm) box_rvm.set("width",roi_width)

                                    roi_height:(Bind.create(box_rvm,"height"))??0
                                                                                 onRoi_heightChanged: if(box_rvm) box_rvm.set("height",roi_height)

                                    onClicked: function(realx,realy){
                                        rep_boxs.currentIndex = index
                                    }
                                    onDeleteKeyup: function(e){
                                        rep_boxs.boxs_model.removeItemAt(index)
                                    }


                                    borderColor:  Bind.create(label_rvm,"color")??"red"
                                    Text {
                                        x:roi_root.rect_roi.x
                                        y:roi_root.rect_roi.y - implicitHeight -5
                                        color: parent.borderColor
                                        text: Bind.create(label_rvm,"name")??"red"
                                    }
                                }
                            }
                        }
                    }
                    Rectangle{
                        Layout.fillHeight: true
                        Layout.maximumWidth: 300
                        Layout.minimumWidth: 200
                        width: 250
                        id:container_label
                        border.width: 1
                        border.color: Style.black

                        ListView {
                            id: lv_labels
                            clip: true
                            spacing: 0
                            anchors.fill: parent
                            property var model_labels: Bind.create(proj, "classifications")??null
                            model: model_labels
                            boundsBehavior: ListView.StopAtBounds
                            ScrollBar.vertical: ScrollBar {
                                id: label_view_vertical_scrollbar
                                width: 8
                                active: true
                                policy: lv_labels.contentHeight
                                        > container_label.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                            }

                            delegate: Item {
                                id: label_row_root
                                clip: true
                                height: 30
                                width: lv_labels.width - (label_view_vertical_scrollbar.policy
                                                            == ScrollBar.AlwaysOn ? 8 : 0)
                                property var rvm: lv_labels.model_labels.getRowData(model.index)

                                property bool isSelected: ListView.isCurrentItem

                                //border rect
                                Rectangle {
                                    anchors.fill: parent
                                    clip: true
                                    color: label_row_root.isSelected ? Style.gray50 : ma_row.containsMouse ? Style.gray20 : "transparent"
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
                                            lv_labels.currentIndex = index
                                        }
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: {
                                            if (mouse.button == Qt.RightButton) {
                                                menu_editLabel.popup()
                                            }
                                        }

                                        onDoubleClicked: {
                                            //vm.openEditProjectWin(rvm)
                                            //vm.saveProjects()
                                        }
                                    }
                                    RowLayout{
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        Q1.TextField {
                                            id:tb_label_name
                                            focus: true
                                            Layout.fillHeight: true
                                            Layout.fillWidth: true
                                            verticalAlignment: Text.AlignVCenter
                                            text: Bind.create(label_row_root.rvm,"name")
                                            onActiveFocusChanged: {
                                                if(activeFocus)
                                                {
                                                    tb_label_name.forceActiveFocus()
                                                    lv_labels.currentIndex = index
                                                }
                                            }
                                            onEditingFinished: {
                                                var regex  = /\s+/g
                                                var str = text.replace(regex,"")
                                                label_row_root.rvm.set("name",CppUtility.stdstr(str))
                                                if(label_row_root.rvm.get("name")==="")
                                                {
                                                    label_row_root.rvm.set("name",CppUtility.stdstr("新的分类"))
                                                }
                                                vm.saveProjects()
                                            }

                                            style: TextFieldStyle
                                            {
                                                textColor: Bind.create(label_row_root.rvm, "color")
                                                background:null
                                            }

                                        }

                                        IconButton {
                                            Layout.preferredHeight: 20
                                            Layout.preferredWidth: 20
                                            Layout.alignment: Qt.AlignVCenter
                                            mipmap:true
                                            ToolTip.visible: ma.containsMouse
                                            ToolTip.text: "选择颜色"
                                            ToolTip.delay: 300
                                            color: Bind.create(label_row_root.rvm, "color")
                                            hoveredColor: JsEx.setColorAlpha(color,0.5)
                                            icon: "qrc:/prism_qt_ui/svg/color_palette.svg"
                                            onClicked: {
                                                colorDialog.open();
                                                colorDialog.rvm = label_row_root.rvm
                                            }
                                        }
                                        IconButton {
                                            Layout.preferredHeight: 20
                                            Layout.preferredWidth: 20
                                            Layout.alignment: Qt.AlignVCenter
                                            mipmap:true
                                            ToolTip.visible: ma.containsMouse
                                            ToolTip.text: "删除分类"
                                            ToolTip.delay: 300
                                            color: Bind.create(label_row_root.rvm, "color")
                                            hoveredColor: JsEx.setColorAlpha(color,0.5)
                                            icon: "qrc:/prism_qt_ui/svg/menu_delete.svg"
                                            onClicked: {
                                                lv_labels.model_labels.removeItemAt(lv_labels.currentIndex);
                                                vm.saveProjects()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        QtPlatform.ColorDialog
                        {
                            id: colorDialog
                            title: "Select a color"
                            visible: false
                            property var rvm

                            // 当用户选择颜色时，更新矩形的颜色
                            onAccepted: {
                                rvm.set("color",CppUtility.stdstr(CppUtility.qcolor2qstring(colorDialog.color)))
                                vm.saveProjects()
                            }
                        }
                        DesktopMenu {
                            id: menu_editLabel
                            showIcon: false
                            popupWidth: 200

                            DesktopMenuItem {
                                text: qsTr("删除")
                                iconMipmap: true
                                iconColor: Style.black80
                                iconSource: CppUtility.transUrl(
                                                "qrc:/prism_qt_ui/svg/menu_delete.svg")
                                onTriggered: {
                                    if (!vm)
                                        return
                                    //vm.removeLabel(lv_labels.currentIndex)
                                    lv_labels.model_labels.removeItemAt(lv_labels.currentIndex);
                                    vm.saveProjects()
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
                            ToolTip.text: "添加分类"
                            ToolTip.delay: 300
                            color: Style.black100
                            hoveredColor: Style.black50
                            icon: "qrc:/prism_qt_ui/svg/plush.svg"
                            onClicked: {
                                var index = vm.add_classification()
                                vm.saveProjects()
                                lv_labels.currentIndex = index
                                lv_labels.positionViewAtIndex(index, ListView.Beginning)
                            }
                        }
                    }
                }
                Text {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    text: Bind.create(lv_train_imgs.currentRvm, "fullPath")
                }
            }
            ListView {
                id: lv_train_imgs
                height: 100
                property real itemWidth: height
                Layout.maximumHeight: 250
                Layout.minimumHeight: 100
                clip: true
                spacing: 15
                property var trainImgs: Bind.create(proj, "trainImgs")
                property var currentRvm: trainImgs.getRowData(
                                             lv_train_imgs.currentIndex)
                model: trainImgs
                boundsBehavior: ListView.StopAtBounds
                orientation: ListView.Horizontal
                ScrollBar.horizontal: ScrollBar {
                    orientation: Qt.Horizontal
                    height: 8
                    active: true
                    policy: lv_train_imgs.contentWidth
                            > lv_train_imgs.width ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                }

                delegate: Item {
                    width: lv_train_imgs.itemWidth
                    height: lv_train_imgs.height
                    Rectangle {
                        id: delegateRoot
                        property bool isSelected: parent.ListView.isCurrentItem
                        anchors.fill: parent
                        anchors.topMargin: 5
                        color: parent.ListView.isCurrentItem ? "blue" : "transparent"
                        property var trainImgRvm: lv_train_imgs.trainImgs.getRowData(
                                                      index)
                        //color: "lightblue"
                        Image {
                            sourceSize.width: parent.width
                            sourceSize.height: parent.height
                            x: parent.width / 2 - width / 2
                            y: parent.height / 2 - height / 2
                            source: "file://" + Bind.create(
                                        delegateRoot.trainImgRvm, "fullPath")
                            //Text {
                            //    text: Bind.create(delegateRoot.trainImgRvm,"displayName")
                            //}
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    lv_train_imgs.currentIndex = model.index
                                    vm.onclickImg(delegateRoot.trainImgRvm)
                                }
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                            }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.leftMargin: 5
                Layout.bottomMargin: 5
                text: Bind.create(proj,
                                  "workDir") + "/" + proj.get("trainFolder")
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                Layout.rightMargin: 5
                Layout.bottomMargin: 5
                text: Bind.create(proj, "status")
            }
        }
    }
}
