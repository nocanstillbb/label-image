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
    id:lableview_root
    property var vm2: vm
    property int isbusy: Bind.create(proj,"isbusy")
    property int tab0_model_index: 0
    onIsbusyChanged: {
        if(!isbusy)
        {
            if(vm.tabindex0reloadImages )//预测结束
            {
                vm.mainTabIndex = 0
                vm2.reloading = true
                var backindex = lv_train_imgs.currentIndex
                vm.loadImages(tb_iamgedir.text)
                //JsEx.delay(lableview_root,10000,function(){
                    lv_train_imgs.currentIndex = -1
                    lv_train_imgs.currentIndex = backindex
                    vm2.reloading = false
                    vm.tabindex0reloadImages = false
                    lv_logModel.currentIndex = tab0_model_index
                //})
            }
            else //训练结束
            {
                vm.loadModelList()
            }
        }
    }
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
                    vm2.reloading = true
                    var backindex = lv_train_imgs.currentIndex
                    vm.loadImages(tb_iamgedir.text)
                    lv_train_imgs.currentIndex = -1
                    lv_train_imgs.currentIndex = backindex
                    vm2.reloading = false
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
                Layout.fillWidth: true
                Layout.fillHeight: true
                Q1.SplitView {
                    anchors.fill: parent
                    orientation: Qt.Horizontal

                    ColumnLayout{
                        Layout.fillHeight: true
                        width: 300
                        spacing: 0
                        Q1.GroupBox
                        {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            implicitHeight: 0
                            implicitWidth: 0
                            title: "模型"
                            ListView {
                                id: lv_logModel
                                anchors.fill: parent
                                currentIndex: -1
                                clip: true
                                spacing: 0
                                property var model_models: vm.modelList??null
                                                                          model: model_models
                                property var currentRvm: model_models.getRowData(currentIndex)
                                boundsBehavior: ListView.StopAtBounds
                                ScrollBar.vertical: ScrollBar {
                                    id: lv_logModelvertical_scrollbar
                                    width: 8
                                    active: true
                                    policy: lv_logModel.contentHeight
                                            > lv_logModel.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                                }

                                delegate: Item {
                                    id: model_row_root
                                    clip: true
                                    height: (Bind.create(rvm,"epochs")??-1) === -1? 35 : 60
                                    width: lv_logModel.width - (lv_logModelvertical_scrollbar.policy
                                                                == ScrollBar.AlwaysOn ? 8 : 0)
                                    property var rvm: lv_logModel.model_models.getRowData(model.index)



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
                                        color: model_row_root.isSelected ? Style.gray50 : model_ma_row.containsMouse ? Style.gray20 : "transparent"
                                        border.color: Style.black
                                        border.width: 1
                                        MouseArea {
                                            id: model_ma_row
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onPressed: {
                                                lv_logModel.currentIndex = index
                                                //var modelpath = model_row_root.rvm.get("fullPath")
                                                //proj.set("modelName", CppUtility.stdstr(modelpath) )
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

                                            ColumnLayout{
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                Layout.alignment: Qt.AlignVCenter
                                                Text {
                                                    focus: true
                                                    text: Bind.create(model_row_root.rvm,"displayName")

                                                }
                                                Text {
                                                    focus: true
                                                    visible: Bind.create(model_row_root.rvm,"epochs")!==-1 && Bind.create(model_row_root.rvm,"batchs")!==-1
                                                    text: "epochs:"+Bind.create(model_row_root.rvm,"epochs") + " batch:" +Bind.create(model_row_root.rvm,"batchs")

                                                }
                                                RowLayout{
                                                    visible: Bind.create(model_row_root.rvm,"baseOn")!==""
                                                    Layout.fillWidth: true
                                                    Text {
                                                        focus: true
                                                        elide: Text.ElideLeft
                                                        text: "基于模型: "

                                                    }
                                                    Text {
                                                        focus: true
                                                        Layout.fillWidth: true
                                                        elide: Text.ElideLeft
                                                        text:  Bind.create(model_row_root.rvm,"baseOn")

                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout{
                            Text {
                                text: qsTr("置信度:")
                            }
                            Q1.SpinBox{
                                id:sb_conf
                                value:0.5
                                stepSize: 0.1
                                decimals: 1
                            }
                        }
                        Row{
                            Layout.preferredHeight: childrenRect.height
                            Layout.alignment: Qt.AlignRight
                            Layout.bottomMargin: 5
                            Q1.Button{
                                id:btn_predict_single
                                text: "预测单张"
                                enabled: lv_train_imgs.currentIndex!=-1 && lv_logModel.currentIndex!=-1 && !lableview_root.isbusy
                                onClicked: {
                                    if(!lv_train_imgs.currentRvm)
                                        return
                                    lv_logModel.currentRvm = lv_logModel.model_models.getRowData(lv_logModel.currentIndex)
                                    if(!lv_logModel.currentRvm)
                                        return
                                    lableview_root.tab0_model_index = lv_logModel.currentIndex
                                    vm.tabindex0reloadImages = true
                                    vm.mainTabIndex =1
                                    var currentImagePath =lv_train_imgs.currentRvm.get("fullPath")
                                    var currentImageDirPath =proj.get("imageDir") + "/"
                                    //console.log("currentImageDirPath:",currentImageDirPath)
                                    var cmdRmPredictDir = 'rm -rf "'+ currentImageDirPath+'predict"'
                                    //console.log("cmdRmPredictDir:",cmdRmPredictDir)
                                    //console.log(lv_logModel.currentIndex)
                                    lv_logModel.currentRvm = lv_logModel.model_models.getRowData(lv_logModel.currentIndex)
                                    //console.log(lv_logModel.currentRvm)
                                    var cmdPredict = 'yolo detect predict '+
                                            'model="'+ lv_logModel.currentRvm.get("fullPath")+ '" '+
                                            'source="'+currentImagePath+'" '+
                                            'project="'+currentImageDirPath+'" '+
                                            'name=predict  save=false save_txt=true save_conf=true conf='+sb_conf.value + ' device='+ proj.get("device")

                                    //console.log(cmdPredict)

                                    var cmdRename ="find \""+ currentImageDirPath +"predict\" -name \"*.txt\" -exec sh -c 'mv \"$0\" \"${0%.txt}.predict\"' {} \\;"
                                    //console.log(cmdRename)

                                    var cmd_overwrite = 'cp -rf "'+ currentImageDirPath+'predict/labels/"' + ' "' + currentImageDirPath +'"'
                                    //console.log(cmd_overwrite)


                                    var cmd_all=  cmdRmPredictDir+" && "+ cmdPredict + " && " + cmdRename +" && "+ cmd_overwrite
                                    //console.log(cmd_all)

                                    //vm.sendText2term(cmdRename+" \n")
                                    vm.sendText2term(cmd_all+" \n")
                                    lv_logModel.currentIndex = -1
                                    proj.set("isbusy",true)
                                }
                            }
                            Q1.Button{
                                text: "预测全部"
                                enabled: lv_logModel.currentIndex!=-1 &&  !lableview_root.isbusy
                                onClicked: {
                                    if(!lv_train_imgs.currentRvm)
                                        return

                                    lv_logModel.currentRvm = lv_logModel.model_models.getRowData(lv_logModel.currentIndex)
                                    if(!lv_logModel.currentRvm)
                                        return
                                    lableview_root.tab0_model_index = lv_logModel.currentIndex
                                    vm.tabindex0reloadImages = true
                                    vm.mainTabIndex =1
                                    var currentImagePath =lv_train_imgs.currentRvm.get("fullPath")
                                    var currentImageDirPath =proj.get("imageDir") + "/"
                                    //console.log("currentImageDirPath:",currentImageDirPath)
                                    var cmdRmPredictDir = 'rm -rf "'+ currentImageDirPath+'predict"'
                                    //console.log("cmdRmPredictDir:",cmdRmPredictDir)
                                    //console.log(lv_logModel.currentIndex)
                                    lv_logModel.currentRvm = lv_logModel.model_models.getRowData(lv_logModel.currentIndex)
                                    //console.log(lv_logModel.currentRvm)
                                    var cmdPredict = 'yolo detect predict '+
                                            'model="'+ lv_logModel.currentRvm.get("fullPath")+ '" '+
                                            'source="'+currentImageDirPath+'" '+
                                            'project="'+currentImageDirPath+'" '+
                                            'name=predict  save=false save_txt=true save_conf=true conf='+sb_conf.value + ' device='+ proj.get("device")

                                    //console.log(cmdPredict)

                                    var cmdRename ="find \""+ currentImageDirPath +"predict\" -name \"*.txt\" -exec sh -c 'mv \"$0\" \"${0%.txt}.predict\"' {} \\;"
                                    //console.log(cmdRename)

                                    var cmd_overwrite = 'cp -rf "'+ currentImageDirPath+'predict/labels/"' + ' "' + currentImageDirPath +'"'
                                    //console.log(cmd_overwrite)


                                    var cmd_all=  cmdRmPredictDir+" && "+ cmdPredict + " && " + cmdRename +" && "+ cmd_overwrite
                                    //console.log(cmd_all)

                                    //vm.sendText2term(cmdRename+" \n")
                                    vm.sendText2term(cmd_all+" \n")
                                    lv_logModel.currentIndex = -1
                                    proj.set("isbusy",true)
                                }
                            }

                        }
                        Row{
                            Layout.preferredHeight: childrenRect.height
                            Layout.alignment: Qt.AlignRight
                            Layout.bottomMargin: 5
                            Q1.Button{
                                text: "删除所有预测文件"
                                enabled: !lableview_root.isbusy
                                onClicked: {
                                    vm.reloading = true
                                    vm.removeAllPredictFiles()
                                    var backindex = lv_train_imgs.currentIndex
                                    vm.loadImages(tb_iamgedir.text)
                                    lv_train_imgs.currentIndex = -1
                                    lv_train_imgs.currentIndex = backindex
                                    vm.reloading = false
                                }
                            }
                            Q1.Button{
                                text: "转化所有预测为标记"
                                enabled:  !lableview_root.isbusy
                                onClicked: {
                                    vm.reloading = true
                                    vm.mergeAllPredictFiles()
                                    var backindex = lv_train_imgs.currentIndex
                                    vm.loadImages(tb_iamgedir.text)
                                    lv_train_imgs.currentIndex = -1
                                    lv_train_imgs.currentIndex = backindex
                                    vm.reloading = false
                                }
                            }
                        }
                    }
                    Item{
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        ColumnLayout{
                            anchors.fill: parent
                            Renderer {
                                id:renderer
                                Layout.fillHeight: true
                                Layout.fillWidth: true
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
                                            vm.reloading = true
                                            var previous = lv_train_imgs.currentIndex -1
                                            if(previous > -1)
                                            {
                                                lv_train_imgs.currentIndex = previous
                                                vm.onclickImg(lv_train_imgs.trainImgs.getRowData(previous))
                                            }

                                            vm.reloading = false
                                        }
                                    }
                                    DesktopMenuItem {
                                        text: qsTr("下一张")
                                        iconMipmap: true
                                        iconColor: Style.black80
                                        //iconSource: CppUtility.transUrl(
                                        //                "qrc:/prism_qt_ui/svg/menu_delete.svg")
                                        onTriggered: {

                                            vm.reloading = true
                                            var next = lv_train_imgs.currentIndex +1
                                            if(next < lv_train_imgs.trainImgs.length())
                                            {
                                                lv_train_imgs.currentIndex = next
                                                vm.onclickImg(lv_train_imgs.trainImgs.getRowData(next))
                                            }
                                            vm.reloading = false

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
                                    id:videocanvas
                                    frameHeight:  renderer.fh
                                    frameWidth: renderer.fw
                                    roi_height: frameHeight
                                    roi_width: frameWidth
                                    roi_x:  0
                                    roi_y:  0
                                    strokeColor: Bind.create(lv_labels.model_labels.getRowData(lv_labels.currentIndex),"color")??"red"
                                                                                                                                  Keys.enabled: true
                                    Keys.onReleased:function(e) {
                                        if(e.key === Qt.Key_Left)
                                        {
                                            vm2.reloading = true
                                            var previous = lv_train_imgs.currentIndex -1
                                            if(previous > -1)
                                            {
                                                lv_train_imgs.currentIndex = previous
                                                vm2.onclickImg(lv_train_imgs.trainImgs.getRowData(previous))
                                            }
                                            vm2.reloading = false
                                        }
                                        else if(e.key === Qt.Key_Right)
                                        {

                                            vm2.reloading = true
                                            var next = lv_train_imgs.currentIndex +1
                                            if(next < lv_train_imgs.trainImgs.length())
                                            {
                                                lv_train_imgs.currentIndex = next
                                                vm2.onclickImg(lv_train_imgs.trainImgs.getRowData(next))
                                            }
                                            vm2.reloading = false
                                        }
                                    }
                                    onDrawCompleted: function(x,y,w,h)
                                    {
                                        if(lv_labels.currentIndex <0)
                                            return
                                        if(w <10  && h < 10)
                                            return

                                        var imagePath = lv_train_imgs.currentRvm.get("fullPath")
                                        vm.add_nms_box(rep_boxs.boxs_model,x,y,w,h,lv_labels.currentIndex,frameWidth,frameHeight,imagePath)
                                        lv_current_image_boxs.currentIndex = lv_current_image_boxs.model_boxs.length()-1
                                        vm.save_boxs(rep_boxs.boxs_model,imagePath,"txt")
                                    }
                                }

                                //nms boxs
                                Repeater{
                                    id:rep_boxs
                                    property var boxs_model: Bind.create(lv_train_imgs.currentRvm,"nms_boxs")
                                    model: boxs_model
                                    property var currentIndex

                                    delegate:VideoROI2 {
                                        id:roi_root
                                        property var vm2: vm
                                        property var lv_train_imgs2: lv_train_imgs
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


                                        roi_x:(Bind.create(box_rvm,"x"))??0

                                                                           onRoi_xChanged:
                                                                           {
                                                                               if(box_rvm && !vm2.reloading)
                                                                               {
                                                                                   box_rvm.set("x",roi_x)
                                                                                   vm.save_boxs(rep_boxs.boxs_model,roi_root.box_rvm.get("img_path"),"txt")
                                                                               }
                                                                           }

                                        roi_y:(Bind.create(box_rvm,"y"))??0
                                                                           onRoi_yChanged:
                                                                           {
                                                                               if(box_rvm && !vm2.reloading)
                                                                               {
                                                                                   box_rvm.set("y",roi_y)
                                                                                   vm.save_boxs(rep_boxs.boxs_model,roi_root.box_rvm.get("img_path"),"txt")
                                                                               }
                                                                           }

                                        roi_width:(Bind.create(box_rvm,"width"))??0
                                                                                   onRoi_widthChanged:
                                                                                   {
                                                                                       if(box_rvm && !vm2.reloading)
                                                                                       {
                                                                                           box_rvm.set("width",roi_width)
                                                                                           vm.save_boxs(rep_boxs.boxs_model,roi_root.box_rvm.get("img_path"),"txt")
                                                                                       }
                                                                                   }

                                        roi_height:(Bind.create(box_rvm,"height"))??0
                                                                                     onRoi_heightChanged:
                                                                                     {
                                                                                       if(box_rvm && !vm2.reloading)
                                                                                         {
                                                                                             box_rvm.set("height",roi_height)
                                                                                             vm.save_boxs(rep_boxs.boxs_model,roi_root.box_rvm.get("img_path"),"txt")
                                                                                         }
                                                                                     }

                                        onClicked: function(realx,realy){
                                            rep_boxs.currentIndex = index
                                            lv_current_image_boxs.currentIndex = index
                                        }
                                        onDeleteKeyup: function(e){
                                            if(vm)
                                            {
                                                var imagepath = roi_root.box_rvm.get("img_path")
                                                var model = rep_boxs.boxs_model
                                                rep_boxs.boxs_model.removeItemAt(index)
                                                vm2.save_boxs(model,imagepath,"txt")
                                            }
                                        }
                                        onLeftKeyup: function(e)
                                        {
                                            vm2.reloading = true
                                            var previous = lv_train_imgs2.currentIndex -1
                                            if(previous > -1)
                                            {
                                                lv_train_imgs2.currentIndex = previous
                                                vm2.onclickImg(lv_train_imgs2.trainImgs.getRowData(previous))
                                            }
                                            vm2.reloading = false
                                        }
                                        onRightKeyup: function(e)
                                        {
                                            lableview_root.vm2.reloading = true
                                            var next = lv_train_imgs2.currentIndex +1
                                            if(next < lv_train_imgs2.trainImgs.length())
                                            {
                                                lv_train_imgs2.currentIndex = next
                                                vm2.onclickImg(lv_train_imgs2.trainImgs.getRowData(next))
                                            }
                                            vm2.reloading = false
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
                                //predict box
                                Repeater{
                                    id:rep_predict_boxs
                                    property var predict_model: Bind.create(lv_train_imgs.currentRvm,"predict_boxs")
                                    model: predict_model
                                    property var currentIndex

                                    delegate:VideoROI2 {
                                        id:roi_predict_root
                                        disableDragAndResize: true
                                        property var vm2: vm
                                        property var lv_train_imgs2: lv_train_imgs
                                        property var box_rvm: rep_predict_boxs.predict_model.getRowData(index)
                                        property int classificationid : Bind.create(box_rvm,"classificationId") ?? -1
                                        property var label_rvm: lv_labels.model_labels.getRowData(classificationid)
                                        property bool isSelected: Bind.create(box_rvm,"isSelected")
                                        onIsSelectedChanged: {
                                            if(isSelected)
                                            {
                                                roi_predict_root.forceActiveFocus()
                                                roi_predict_root.mouseArea_drag.forceActiveFocus()
                                                lv_current_image_predict_boxs.currentIndex = index
                                            }
                                        }


                                        color: "transparent"
                                        borderWidth: isSelected ? 2 :1

                                        frameHeight:  renderer.fh
                                        frameWidth: renderer.fw


                                        roi_x:(Bind.create(box_rvm,"x"))??0

                                                                           onRoi_xChanged:
                                                                           {
                                                                               if(box_rvm && !vm2.reloading)
                                                                               {
                                                                                   box_rvm.set("x",roi_x)
                                                                                   vm.save_boxs(rep_predict_boxs.predict_model,roi_predict_root.box_rvm.get("img_path"),"predict")
                                                                               }
                                                                           }

                                        roi_y:(Bind.create(box_rvm,"y"))??0
                                                                           onRoi_yChanged:
                                                                           {
                                                                               if(box_rvm && !vm2.reloading)
                                                                               {
                                                                                   box_rvm.set("y",roi_y)
                                                                                   vm.save_boxs(rep_predict_boxs.predict_model,roi_predict_root.box_rvm.get("img_path"),"predict")
                                                                               }
                                                                           }

                                        roi_width:(Bind.create(box_rvm,"width"))??0
                                                                                   onRoi_widthChanged:
                                                                                   {
                                                                                       if(box_rvm && !vm2.reloading)
                                                                                       {
                                                                                           box_rvm.set("width",roi_width)
                                                                                           vm.save_boxs(rep_predict_boxs.predict_model,roi_predict_root.box_rvm.get("img_path"),"predict")
                                                                                       }
                                                                                   }

                                        roi_height:(Bind.create(box_rvm,"height"))??0
                                                                                     onRoi_heightChanged:
                                                                                     {
                                                                                       if(box_rvm && !vm2.reloading)
                                                                                         {
                                                                                             box_rvm.set("height",roi_height)
                                                                                             vm.save_boxs(rep_predict_boxs.predict_model,roi_predict_root.box_rvm.get("img_path"),"predict")
                                                                                         }
                                                                                     }

                                        onClicked: function(realx,realy){
                                            rep_predict_boxs.currentIndex = index
                                            lv_current_image_predict_boxs.currentIndex = index
                                        }
                                        onDeleteKeyup: function(e){
                                            if(vm)
                                            {
                                                var imgpath = roi_predict_root.box_rvm.get("img_path")
                                                var model = rep_predict_boxs.predict_model
                                                rep_predict_boxs.predict_model.removeItemAt(index)
                                                vm2.save_boxs(model,imgpath,"predict")
                                            }
                                        }
                                        onLeftKeyup: function(e)
                                        {
                                            vm2.reloading = true
                                            var previous = lv_train_imgs2.currentIndex -1
                                            if(previous > -1)
                                            {
                                                lv_train_imgs2.currentIndex = previous
                                                vm2.onclickImg(lv_train_imgs2.trainImgs.getRowData(previous))
                                            }
                                            vm2.reloading = false
                                        }
                                        onRightKeyup: function(e)
                                        {

                                            vm2.reloading = true
                                            var next = lv_train_imgs2.currentIndex +1
                                            if(next < lv_train_imgs2.trainImgs.length())
                                            {
                                                lv_train_imgs2.currentIndex = next
                                                vm2.onclickImg(lv_train_imgs2.trainImgs.getRowData(next))
                                            }
                                            vm2.reloading = false
                                        }


                                        borderColor:  Bind.create(label_rvm,"color")??"red"
                                                                                       Text {
                                                                                           x:roi_predict_root.rect_roi.x
                                                                                           y:roi_predict_root.rect_roi.y - implicitHeight -5
                                                                                           color: parent.borderColor
                                                                                           text: Bind.create(label_rvm,"name")??"未知:"+classificationid + "  ["+(Bind.create(roi_predict_root.box_rvm,"confidence")??0).toFixed(2)+"]"
                                                                                       }
                                    }
                                }
                            }
                            Text {
                                id:tb_imaeg_path
                                Layout.fillWidth: true
                                text: Bind.create(lv_train_imgs.currentRvm, "fullPath")
                                onTextChanged: {
                                    videocanvas.forceActiveFocus()
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
                                Layout.minimumHeight: 200
                                Layout.maximumHeight: 300
                                height: 200
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
                                                    color: Bind.create(lable_rvm, "color")??"red"
                                                    hoveredColor: JsEx.setColorAlpha(color,0.5)
                                                    icon: "qrc:/prism_qt_ui/svg/menu_delete.svg"
                                                    onClicked: {
                                                        var imgpath = box_row_root.rvm.get("img_path")
                                                        lv_current_image_boxs.model_boxs.removeItemAt(index);
                                                        vm.save_boxs(rep_boxs.boxs_model,imgpath,"txt")
                                                        vm.saveProjects()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            //predict boxs
                            Q1.GroupBox{
                                title: "预测"
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                implicitHeight: 0
                                implicitWidth: 0
                                ListView {
                                    id: lv_current_image_predict_boxs
                                    currentIndex: -1
                                    anchors.fill: parent
                                    clip: true
                                    spacing: 0
                                    property var predict_model: rep_predict_boxs.predict_model??null
                                    model: predict_model
                                    boundsBehavior: ListView.StopAtBounds
                                    ScrollBar.vertical: ScrollBar {
                                        id: lv_current_image_predict_boxs_vertical_scrollbar
                                        width: 8
                                        active: true
                                        policy: lv_current_image_predict_boxs.contentHeight
                                                > lv_current_image_predict_boxs.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                                    }

                                    delegate: Item {
                                        id: predict_box_row_root
                                        clip: true
                                        height: 30
                                        width: lv_current_image_predict_boxs.width - (lv_current_image_predict_boxs_vertical_scrollbar.policy
                                                                              == ScrollBar.AlwaysOn ? 8 : 0)
                                        property var rvm: lv_current_image_predict_boxs.predict_model.getRowData(model.index)



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
                                            color: predict_box_row_root.isSelected ? Style.gray50 : predict_box_ma_row.containsMouse ? Style.gray20 : "transparent"
                                            border.color: Style.black
                                            border.width: 1
                                            MouseArea {
                                                id: predict_box_ma_row
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onPressed: {
                                                    lv_current_image_predict_boxs.currentIndex = index
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
                                                    property var classificationId:  Bind.create(predict_box_row_root.rvm,"classificationId")??-1
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
                                                    ToolTip.text: "删除预测"
                                                    ToolTip.delay: 300
                                                    property var classificationId:  Bind.create(predict_box_row_root.rvm,"classificationId")??-1
                                                    property var lable_rvm : classificationId>=0? lv_labels.model_labels.getRowData(classificationId):null
                                                    color: Bind.create(lable_rvm, "color")??"red"
                                                    hoveredColor: JsEx.setColorAlpha(color,0.5)
                                                    icon: "qrc:/prism_qt_ui/svg/menu_delete.svg"
                                                    onClicked: {
                                                        var imgpath =  predict_box_row_root.rvm.get("img_path")
                                                        lv_current_image_predict_boxs.predict_model.removeItemAt(index);
                                                        vm.save_boxs(rep_predict_boxs.predict_model,imgpath,"predict")
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
                                    vm2.reloading = true
                                    lv_train_imgs.currentIndex = model.index
                                    vm.onclickImg(delegateRoot.trainImgRvm)
                                    vm2.reloading = false
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
