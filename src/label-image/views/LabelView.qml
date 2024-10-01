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
    QtPlatform.FolderDialog {
        id: chooseFolderDialog
        title: qsTr("选择图片目录")
        acceptLabel: qsTr("确定")
        rejectLabel: qsTr("取消")
        onAccepted: {
            proj.set("imageDir", CppUtility.stdstr(CppUtility.qurl2localfile(folder)))
            vm.saveProjects()
            vm.loadImages(CppUtility.qurl2localfile(folder))

        }
    }
    ColumnLayout {
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            Text {
                Layout.leftMargin: 5
                Layout.fillWidth: false
                text: "图片目录"
            }
            Text {
                id:tb_iamgedir
                Layout.leftMargin: 5
                Layout.fillWidth: true
                Layout.preferredHeight: 25
                verticalAlignment: Text.AlignVCenter
                text: Bind.create(proj, "imageDir")
                Rectangle{
                    anchors.fill: parent
                    color: "#33808080"
                }
            }
            Q1.Button{
                Layout.fillWidth: false
                text: "选择图片目录"
                onClicked: {
                    chooseFolderDialog.open();
                }
            }
            Q1.Button{
                Layout.fillWidth: false
                text: "重新加载"
                onClicked: {
                    vm.loadImages(tb_iamgedir.text)
                    lv_train_imgs.currentIndex = -1
                }
            }
            Q1.Button{
                Layout.fillWidth: false
                text: "打开图片目录"
                onClicked: {
                    CppUtility.openPath(tb_iamgedir.text)
                }
            }
        }
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
                                //vm.displayFirstImg()
                            }
                            releaseBuferAfterRender: false
                            property int fw:100
                            property int fh:100
                            onFrameSizeChanged: function(w,h){
                                fw = w
                                fh = h
                            }
                            DesktopMenu {
                                id: menu_canvas
                                showIcon: false
                                popupWidth: 200

                                DesktopMenuItem {
                                    text: qsTr("上一张")
                                    iconMipmap: true
                                    iconColor: Style.black80
                                    //iconSource: CppUtility.transUrl(
                                    //                "qrc:/prism_qt_ui/svg/menu_delete.svg")
                                    onTriggered: {
                                       var previous = lv_train_imgs.currentIndex -1
                                        if(previous > -1)
                                        {
                                            lv_train_imgs.currentIndex = previous
                                            vm.onclickImg(lv_train_imgs.trainImgs.getRowData(previous))
                                        }
                                    }
                                }
                                DesktopMenuItem {
                                    text: qsTr("下一张")
                                    iconMipmap: true
                                    iconColor: Style.black80
                                    //iconSource: CppUtility.transUrl(
                                    //                "qrc:/prism_qt_ui/svg/menu_delete.svg")
                                    onTriggered: {

                                       var next = lv_train_imgs.currentIndex +1
                                        if(next < lv_train_imgs.trainImgs.length())
                                        {
                                            lv_train_imgs.currentIndex = next
                                            vm.onclickImg(lv_train_imgs.trainImgs.getRowData(next))
                                        }
                                    }
                                }

                            }
                            MouseArea{
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(mouse) {
                                    if (mouse.button == Qt.RightButton) {
                                       menu_canvas.popup()
                                    }

                                }
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

                                      var imagePath = lv_train_imgs.currentRvm.get("fullPath")
                                      vm.add_nms_box(rep_boxs.boxs_model,x,y,w,h,lv_labels.currentIndex,frameWidth,frameHeight,CppUtility.stdstr(imagePath))
                                      lv_current_image_boxs.currentIndex = lv_current_image_boxs.model_boxs.length()-1
                                      vm.save_nms_box(rep_boxs.boxs_model,tb_imaeg_path.text)
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
                                    property bool isSelected: Bind.create(box_rvm,"isSelected")
                                    onIsSelectedChanged: {
                                        if(isSelected)
                                        {
                                            roi_root.forceActiveFocus()
                                            roi_root.mouseArea_drag.forceActiveFocus()
                                            lv_current_image_boxs.currentIndex = index
                                        }
                                    }
                                    color: "transparent"
                                    borderWidth: isSelected ? 2 :1

                                    frameHeight:  renderer.fh
                                    frameWidth: renderer.fw

                                    Component.onDestruction: {
                                        vm.save_nms_box(rep_boxs.boxs_model,tb_imaeg_path.text)
                                    }

                                    roi_x:(Bind.create(box_rvm,"x"))??0

                                                                       onRoi_xChanged:
                                                                       {
                                                                           if(box_rvm)
                                                                           {
                                                                               box_rvm.set("x",roi_x)
                                                                               vm.save_nms_box(rep_boxs.boxs_model,tb_imaeg_path.text)
                                                                           }
                                                                       }

                                    roi_y:(Bind.create(box_rvm,"y"))??0
                                                                       onRoi_yChanged:
                                                                       {
                                                                           if(box_rvm)
                                                                           {
                                                                               box_rvm.set("y",roi_y)
                                                                               vm.save_nms_box(rep_boxs.boxs_model,tb_imaeg_path.text)
                                                                           }
                                                                       }

                                    roi_width:(Bind.create(box_rvm,"width"))??0
                                                                               onRoi_widthChanged:
                                                                               {
                                                                                   if(box_rvm)
                                                                                   {
                                                                                       box_rvm.set("width",roi_width)
                                                                                       vm.save_nms_box(rep_boxs.boxs_model,tb_imaeg_path.text)
                                                                                   }
                                                                               }

                                    roi_height:(Bind.create(box_rvm,"height"))??0
                                                                                 onRoi_heightChanged:
                                                                                 {
                                                                                     if(box_rvm)
                                                                                     {
                                                                                         box_rvm.set("height",roi_height)
                                                                                         vm.save_nms_box(rep_boxs.boxs_model,tb_imaeg_path.text)
                                                                                     }
                                                                                 }

                                    onClicked: function(realx,realy){
                                        rep_boxs.currentIndex = index
                                        lv_current_image_boxs.currentIndex = index
                                    }
                                    onDeleteKeyup: function(e){
                                        if(vm)
                                        {
                                            rep_boxs.boxs_model.removeItemAt(index)
                                        }
                                    }


                                    borderColor:  Bind.create(label_rvm,"color")??"red"
                                                                                   Text {
                                                                                       x:roi_root.rect_roi.x
                                                                                       y:roi_root.rect_roi.y - implicitHeight -5
                                                                                       color: parent.borderColor
                                                                                       text: Bind.create(label_rvm,"name")??"未知:"+classificationid
                                                                                   }
                                }
                            }
                        }
                    }
                    Rectangle{
                        Layout.fillHeight: true
                        Layout.minimumWidth: 200
                        width: 250
                        id:container_label
                        border.width: 1
                        border.color: Style.black

                        Q1.SplitView{
                            anchors.fill: parent
                            orientation: Qt.Vertical
                            //lables
                            Q1.GroupBox{
                                title: "分类"
                                implicitHeight: 0
                                implicitWidth: 0
                                Layout.minimumHeight: 150
                                height: 150
                            ListView {
                                id: lv_labels
                                anchors.fill: parent
                                clip: true
                                spacing: 0
                                property var model_labels: Bind.create(proj, "classifications")??null
                                                                                                  model: model_labels
                                boundsBehavior: ListView.StopAtBounds
                                ScrollBar.vertical: ScrollBar {
                                    id: label_view_vertical_scrollbar
                                    width: 8
                                    active: true
                                    policy: lv_labels.contentHeight
                                            > lv_labels.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
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
                                                    //menu_editLabel.popup()
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
                            //boxs
                            Q1.GroupBox{
                                title: "标记"
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                implicitHeight: 0
                                implicitWidth: 0
                                ListView {
                                    id: lv_current_image_boxs
                                    currentIndex: -1
                                    anchors.fill: parent
                                    clip: true
                                    spacing: 0
                                    property var model_boxs: rep_boxs.boxs_model??null
                                                                                   model: model_boxs
                                    boundsBehavior: ListView.StopAtBounds
                                    ScrollBar.vertical: ScrollBar {
                                        id: lv_current_image_boxs_vertical_scrollbar
                                        width: 8
                                        active: true
                                        policy: lv_current_image_boxs.contentHeight
                                                > lv_current_image_boxs.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                                    }

                                    delegate: Item {
                                        id: box_row_root
                                        clip: true
                                        height: 30
                                        width: lv_current_image_boxs.width - (lv_current_image_boxs_vertical_scrollbar.policy
                                                                              == ScrollBar.AlwaysOn ? 8 : 0)
                                        property var rvm: lv_current_image_boxs.model_boxs.getRowData(model.index)



                                        property bool isSelected: ListView.isCurrentItem
                                        onIsSelectedChanged: {
                                            if(rvm)
                                                rvm.set("isSelected",isSelected)
                                        }

                                        //border rect
                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.topMargin: -1
                                            anchors.leftMargin: -1
                                            anchors.rightMargin: -1
                                            clip: true
                                            color: box_row_root.isSelected ? Style.gray50 : box_ma_row.containsMouse ? Style.gray20 : "transparent"
                                            border.color: Style.black
                                            border.width: 1
                                            MouseArea {
                                                id: box_ma_row
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onPressed: {
                                                    lv_current_image_boxs.currentIndex = index
                                                }
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: {
                                                    //if (mouse.button == Qt.RightButton) {
                                                    //    menu_editLabel.popup()
                                                    //}
                                                }

                                                onDoubleClicked: {
                                                    //vm.openEditProjectWin(rvm)
                                                    //vm.saveProjects()
                                                }
                                            }
                                            RowLayout{
                                                anchors.fill: parent
                                                spacing: 0
                                                Text {
                                                    focus: true
                                                    Layout.fillHeight: true
                                                    Layout.fillWidth: true
                                                    Layout.margins: 5
                                                    verticalAlignment: Text.AlignVCenter
                                                    property var classificationId:  Bind.create(box_row_root.rvm,"classificationId")??-1
                                                    property var lable_rvm : classificationId>=0? lv_labels.model_labels.getRowData(classificationId):null
                                                    text: lable_rvm?Bind.create(lable_rvm,"name"):"未知"+classificationId
                                                    color: lable_rvm?Bind.create(lable_rvm,"color"):"red"

                                                }
                                                IconButton {
                                                    Layout.preferredHeight: 20
                                                    Layout.preferredWidth: 20
                                                    Layout.alignment: Qt.AlignVCenter
                                                    mipmap:true
                                                    ToolTip.visible: ma.containsMouse
                                                    ToolTip.text: "删除标记"
                                                    ToolTip.delay: 300
                                                    property var classificationId:  Bind.create(box_row_root.rvm,"classificationId")??-1
                                                    property var lable_rvm : classificationId>=0? lv_labels.model_labels.getRowData(classificationId):null
                                                    color: Bind.create(lable_rvm, "color")??color
                                                    hoveredColor: JsEx.setColorAlpha(color,0.5)
                                                    icon: "qrc:/prism_qt_ui/svg/menu_delete.svg"
                                                    onClicked: {
                                                        lv_current_image_boxs.model_boxs.removeItemAt(index);
                                                        vm.saveProjects()
                                                    }
                                                }
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

                    }
                }
                Text {
                    id:tb_imaeg_path
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    text: Bind.create(lv_train_imgs.currentRvm, "fullPath")
                }
            }
            ListView {
                id: lv_train_imgs
                currentIndex: -1
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
                    property bool isSelected: ListView.isCurrentItem
                    Rectangle {
                        id: delegateRoot
                        anchors.fill: parent
                        anchors.topMargin: 5
                        border.width: 2
                        border.color: (lv_train_imgs.currentIndex!==-1 && isSelected) ?"blue" :"transparent"
                        property var trainImgRvm: lv_train_imgs.trainImgs.getRowData(index)
                        //color: "lightblue"
                        Image {
                            anchors.margins: 5
                            sourceSize.width: parent.width - 10
                            sourceSize.height: parent.height - 10
                            x: parent.width / 2 - width / 2
                            y: parent.height / 2 - height / 2
                            source:delegateRoot.trainImgRvm && delegateRoot.trainImgRvm.get("fullPath") !== null ?"file://" + Bind.create( delegateRoot.trainImgRvm, "fullPath"):""
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
        Item {
            Layout.preferredHeight: 5
        }
        //RowLayout {
        //    Layout.fillWidth: true
        //    Item {
        //        Layout.fillWidth: true
        //    }
        //    Text {
        //        Layout.rightMargin: 5
        //        Layout.bottomMargin: 5
        //        text: Bind.create(proj, "status")
        //    }
        //}
    }
}
