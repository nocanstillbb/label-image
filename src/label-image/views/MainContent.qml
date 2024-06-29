import QtQuick 2.0
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import prismCpp 1.0
import prism_qt_ui 1.0



ColumnLayout {
    anchors.fill: parent
    spacing: 0
    MainTitlebar{
        Layout.fillWidth: true
        Layout.preferredHeight: 40
    }
    MainBody{
        Layout.fillWidth: true
        Layout.fillHeight: true
    }


}
