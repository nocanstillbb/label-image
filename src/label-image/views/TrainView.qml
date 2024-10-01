import QtQml 2.12
import QtQml.Models 2.12
import QtQuick 2.0
import QtQuick.Window 2.12
import prismCpp 1.0
import prism_qt_ui 1.0
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls 1.4 as Q1
import QtQuick.Controls.Styles 1.4
import Qt.labs.platform 1.1 as QtPlatform
import "qrc:/"

Rectangle {
    anchors.fill: parent
    anchors.topMargin: 5
    id: terminalWindow
    signal activeChanged
    color: "white"
    property bool isForgroundShell: true
    onIsForgroundShellChanged: {
        if(isForgroundShell)
            vm.loadModelList()
    }
    onActiveChanged: {
        terminalContainer.qterminal.forceActiveFocus()
    }
    Connections{
        target: vm
        onWindowClose: function(closeEvent) {
            var pid =terminalContainer.qterminalSession.getShellPID()
            var result = CppUtility.killProceById(pid)
            CppUtility.clearQmlCache()
        }
    }
    Timer {
        id: timer
        interval: 1000 // 时间间隔，单位为毫秒 (1000 毫秒 = 1 秒)
        running: true // 启动定时器
        repeat: true // 设置定时器重复执行
        onTriggered: {
            var pid =terminalContainer.qterminalSession.getShellPID()
            terminalWindow.isForgroundShell  = CppUtility.isForegroundShell(pid)
        }
    }

    Action {
        id: showMenubarAction
        text: qsTr("Show Menubar")
        enabled: !appSettings.isMacOS
        shortcut: "Ctrl+Shift+M"
        checkable: true
        checked: appSettings.showMenubar
        onTriggered: appSettings.showMenubar = !appSettings.showMenubar
    }
    Action {
        id: fullscreenAction
        text: qsTr("Fullscreen")
        enabled: !appSettings.isMacOS
        shortcut: "Alt+F11"
        onTriggered: appSettings.fullscreen = !appSettings.fullscreen
        checkable: true
        checked: appSettings.fullscreen
    }
    Action {
        id: quitAction
        text: qsTr("Quit")
        shortcut: "Ctrl+Shift+Q"
        onTriggered: Qt.quit()
    }
    Action {
        id: showsettingsAction
        text: qsTr("Settings")
        onTriggered: {
            settingswindow.show()
            settingswindow.requestActivate()
            settingswindow.raise()
        }
    }
    Action {
        id: copyAction
        text: qsTr("Copy")
        shortcut: "Ctrl+Shift+C"
        onTriggered: {

        }
    }
    Action {
        id: pasteAction
        text: qsTr("Paste")
        shortcut: "Ctrl+Shift+V"
    }
    Action {
        id: zoomIn
        text: qsTr("Zoom In")
        shortcut: "Ctrl++"
        onTriggered: appSettings.incrementScaling()
    }
    Action {
        id: zoomOut
        text: qsTr("Zoom Out")
        shortcut: "Ctrl+-"
        onTriggered: appSettings.decrementScaling()
    }
    Action {
        id: showAboutAction
        text: qsTr("About")
        onTriggered: {
            aboutDialog.show()
            aboutDialog.requestActivate()
            aboutDialog.raise()
        }
    }
    ApplicationSettings {
        id: appSettings
        Component.onCompleted: {
            appSettings.loadProfile(8)
        }
    }
    Q1.SplitView{
        anchors.fill: parent
        Q1.SplitView{
            id:container_propertytree
            Layout.minimumWidth: 270
            Layout.maximumWidth: 350
            Layout.fillHeight: true
            orientation: Qt.Vertical

            Q1.GroupBox
            {
                title: "超参数"
                Layout.fillWidth: true
                height: 300
                Layout.minimumHeight: 100
                Layout.maximumHeight: 350
                Q1.TreeView{
                    id:tree_view
                    anchors.fill: parent

                    model:model_properties
                    selectionMode: Q1.SelectionMode.SingleSelection
                    selection:  ItemSelectionModel {
                        model: model_properties
                        id:sel
                    }
                    onDoubleClicked: {

                    }
                    rootIndex:  model_properties?model_properties[0]:tree_view.rootIndex
                    //headerDelegate: Item{ height: 1}
                    style: TreeViewStyle {
                        id:style_tree_view
                        backgroundColor: "transparent"
                        indentation: 15
                        branchDelegate: Item {
                            id:b_root
                            width: 15
                            height: 20

                            SvgIcon{
                                width: 10
                                height: 10
                                anchors.centerIn: parent
                                svgPath: CppUtility.transUrl("qrc:/prism_qt_ui/svg/back.svg")

                                color:ma.containsMouse? Style.gray:  "black"
                                rotation: styleData.isExpanded? 270:180
                                Behavior on rotation {
                                    NumberAnimation { duration: 100 }
                                }
                            }

                            MouseArea{
                                id:ma
                                hoverEnabled: true
                                anchors.fill: parent
                                propagateComposedEvents: true
                                //pressAndHoldInterval : 800

                                onPressed: {
                                    mouse.accepted = false
                                    b_root.forceActiveFocus()
                                }
                            }


                        }

                        rowDelegate:Rectangle {
                            property bool isSelected: styleData.selected
                            property var idx : control.__listView.model.mapRowToModelIndex(styleData.row)
                            color: styleData.selected ?"lightblue": (ma_hovered.containsMouse? Style.lightblue50: (styleData.alternate?Style.lightgray30:"white"))
                            height: 28
                            MouseArea{

                                id:ma_hovered
                                property bool ishovered : containsMouse && !parent.isSelected
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                hoverEnabled: true
                                //onEntered: {
                                //    var y1 =Math.abs(ma_hovered.mapFromItem(control,0,0).y)
                                //    var y2 = styleData.row * 25
                                //    if(y1 < y2  ||  y1 > y2+25)
                                //        CppUtility.forceUpdateMouseAreaHovered(ma_hovered)

                                //}
                            }
                        }

                        frame: Rectangle {
                            border.color:  "lightblue"
                            border.width: 1
                            anchors.fill: parent
                            anchors.topMargin: -1
                        }

                        scrollBarBackground: Rectangle{
                            implicitWidth: 6
                        }

                        incrementControl: Item { height: 0 }
                        decrementControl: Item { height: 0 }
                        handleOverlap: 0
                        handle: Rectangle{
                            implicitHeight:5
                            implicitWidth: 5
                            radius: implicitWidth/2
                            color: (styleData.hovered || styleData.pressed) ?Style.lightgray100: Style.lightgray70

                        }
                        corner: Item {implicitHeight: 0;implicitWidth: 5 }

                        headerDelegate: Rectangle{
                            color: Style.lightblue70
                            height: 30
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                verticalAlignment: Text.AlignVCenter
                                text: styleData.value
                            }

                            Rectangle{
                                width: 1
                                height: parent.height
                                anchors.right: parent.right
                                anchors.rightMargin: -5
                            }
                        }

                    }

                    verticalScrollBarPolicy: Qt.ScrollBarAsNeeded
                    // 自定义滚动条


                    horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                    Component.onCompleted: {
                        tree_view.__wheelAreaScrollSpeed = 50
                        tree_view.__listView.cacheBuffer = 9999999
                    }

                    onCurrentIndexChanged: {
                    }


                    Q1.TableViewColumn {
                        id:col_name
                        title: "属性"
                        resizable: true
                        width: tree_view.width/2 -5
                        delegate:Item {
                            RowLayout {
                                anchors.fill: parent
                                Text {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    verticalAlignment: Text.AlignVCenter
                                    //text:model.propertyName
                                    text:model.showName
                                    elide: Text.ElideRight
                                    font: Style.h7
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                    Q1.TableViewColumn {
                        id:col_value
                        title: "值"
                        resizable: true
                        width: tree_view.width - col_name.width
                        delegate:Item {
                            id:rowRoot

                            property Component  boolComp:Component{
                                Item {
                                    Q1.CheckBox{
                                        anchors.verticalCenter: parent.verticalCenter
                                        onCheckedChanged: {
                                            vm.saveProjects()
                                        }
                                    }
                                }
                            }
                            property Component  intComp:Component{
                                Item {
                                    Q1.SpinBox{
                                        anchors.fill:parent
                                        anchors.leftMargin: 5
                                        anchors.rightMargin: 7
                                        value: Bind.create(proj,model.propertyName)
                                        decimals: model.decimals
                                        stepSize: model.step
                                        minimumValue: model.from
                                        maximumValue: model.to
                                        onValueChanged: {
                                            if(proj.get(model.propertyName) !== value)
                                            {
                                                proj.set(model.propertyName,value)
                                                vm.saveProjects()
                                            }
                                        }
                                    }
                                }
                            }
                            property Component  floatComp:Component{
                                Item {
                                    Q1.SpinBox{
                                        anchors.fill:parent
                                        anchors.leftMargin: 5
                                        anchors.rightMargin: 7
                                        onValueChanged: {
                                            vm.saveProjects()
                                        }
                                    }
                                }
                            }
                            property Component  cmbComp:Component{
                                Q1.ComboBox{
                                    model:parent.m.options
                                    currentIndex: {
                                        if(currentText) {}
                                        var model_value = Bind.create(proj,parent.m.propertyName)
                                        for(var i = 0 ;i < parent.m.options.count ; i++)
                                        {
                                            if(model_value === parent.m.options.get(i).text)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onCurrentTextChanged: {
                                        var model_value = Bind.create(proj,parent.m.propertyName)
                                        if(currentText!=="" && currentText !== model_value)
                                        {
                                            proj.set(parent.m.propertyName,CppUtility.stdstr(currentText))
                                            vm.saveProjects()
                                        }
                                    }
                                }
                            }
                            property Component  strComp:Component{
                                Item {
                                    Text {
                                        id:t_data
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        text: Bind.create(proj,model.propertyName)
                                        elide: Text.ElideLeft
                                        verticalAlignment: Text.AlignVCenter
                                        onTextChanged: {
                                            vm.saveProjects()
                                        }

                                        MouseArea{
                                            anchors.fill: parent
                                            function locateModel(){
                                                for(var i = 0;i<lv_logModel.model_models.length();i++)
                                                {
                                                    var  r = lv_logModel.model_models.getRowData(i)
                                                    if(r.get("fullPath") === t_data.text)
                                                    {
                                                        lv_logModel.currentIndex = i
                                                    }

                                                }
                                            }
                                            onClicked: {
                                                locateModel()
                                            }
                                            Component.onCompleted: {
                                                locateModel()
                                            }
                                        }
                                    }
                                }

                            }

                            Loader {
                                anchors.fill: parent
                                property var m: model
                                sourceComponent: {
                                    switch(model.type) {
                                    case "bool":
                                        return rowRoot.boolComp
                                    case "int":
                                        return rowRoot.intComp
                                    case "float":
                                        return rowRoot.floatComp
                                    case "enum":
                                        return rowRoot.cmbComp
                                    case "string":
                                        return rowRoot.strComp
                                    default:
                                        return null
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Q1.GroupBox{
                title: "基准模型"
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: 0
                implicitWidth: 0
                ListView {
                    id: lv_logModel
                    currentIndex: -1
                    anchors.fill: parent
                    clip: true
                    spacing: 0
                    property var model_models: vm.modelList??null
                    model: model_models
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
                                    var modelpath = model_row_root.rvm.get("fullPath")
                                    proj.set("modelName", CppUtility.stdstr(modelpath) )
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
                                //IconButton {
                                //    Layout.preferredHeight: 20
                                //    Layout.preferredWidth: 20
                                //    Layout.alignment: Qt.AlignVCenter
                                //    mipmap:true
                                //    ToolTip.visible: ma.containsMouse
                                //    ToolTip.text: "删除标记"
                                //    ToolTip.delay: 300
                                //}
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout{
            spacing: 0
            Layout.fillHeight: true
            TerminalContainer {
                Layout.fillHeight: true
                Layout.fillWidth: true
                z: 100
                id: terminalContainer
                enabled: true
                width: parent.width
                height: (parent.height + Math.abs(y))
                Component.onCompleted: {
                    terminalContainer.qterminalSession.sendText("source venv_yolo8/bin/activate && clear \n");
                    JsEx.delay(parent,200,function(){
                        terminalContainer.qterminalSession.sendText(" ");
                    })
                }
                onClicked:function(e) {
                   terminalContainer.qterminal.forceActiveFocus()
                }
                Connections{
                    target: vm
                    onSendText2term:function(cmd){
                        terminalContainer.qterminalSession.sendText(cmd);
                    }
                }
            }
            Text{
                Layout.fillWidth: true
                visible: terminalWindow.isForgroundShell
                text: "当前基准模型 : " + Bind.create(proj,"modelName")

            }

            RowLayout{
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                function startNewSession(){
                }
                Q1.Button{
                    text: "训练"
                    enabled: terminalWindow.isForgroundShell
                    onClicked:{
                        vm.train();
                    }
                }
                Q1.Button{
                    id:btn_terminal
                    text: "中止任务"
                    enabled: !terminalWindow.isForgroundShell
                    onClicked:{
                        var pid =terminalContainer.qterminalSession.getShellPID()
                        var result = CppUtility.killProceById(pid)
                        timer.stop()
                        terminalWindow.isForgroundShell=true
                        terminalWindow.parent.updateUrl()
                    }
                }
                Q1.Button{
                    text: "清屏"
                    enabled: terminalWindow.isForgroundShell
                    onClicked: {
                        timer.stop()
                        terminalWindow.isForgroundShell=true
                        terminalWindow.parent.updateUrl()
                    }
                }
                Q1.Button{
                    text: "刷新模型列表"
                    onClicked: {
                        vm.loadModelList()
                    }
                }
                Q1.Button{
                    text: "打开模型目录"
                    onClicked: {
                        CppUtility.openPath(proj.get("workDir")+"/train_logs")
                    }
                }
                //Q1.Button{
                //    text: "打印"
                //    onClicked: {
                //        var pid =terminalContainer.qterminalSession.getShellPID()
                //        console.log(pid)
                //        console.log(CppUtility.isForegroundShell(pid))
                //    }
                //}
            }
        }
    }
    ListModel{
        id:model_properties

        //model
        ListElement{
            group :"group1"
            propertyName :"modelName"
            showName: "基准模型"
            visible :true
            type:"string"
            tips:""
        }

        //image size
        ListElement{
            group :"group1"
            propertyName :"imgSize"
            showName: "图片大小"
            visible :true
            type:"int"
            from: 100
            to: 10000
            step: 4
            decimals: 0
            tips:""
        }

        //epochs
        ListElement{
            group :"group1"
            propertyName :"epochs"
            showName: "轮次"
            visible :true
            type:"int"
            from: 0
            to: 999
            step: 1
            decimals: 0
            tips:""
        }

        //batchs
        ListElement{
            group :"group1"
            propertyName :"batchs"
            showName: "批次"
            visible :true
            type:"int"
            from: 0
            to: 100
            step: 1
            decimals: 0
            tips:""
        }

        //device
        ListElement{
            group :"group1"
            propertyName :"device"
            showName: "设备"
            visible :true
            type:"enum"
            options:[
                ListElement{ text:"cpu"; value:"0" },
                ListElement{ text:"cuda"; value:"1" },
                ListElement{ text:"mps"; value:"2" }
            ]
            tips:""
        }

    }
}
