import QtQuick 2.1
import Sailfish.Silica 1.0

Rectangle {
    property int digit
    property string text_color
    property double pos_x
    property double pos_y

    height: width
    radius: width / 10
    antialiasing: true
    color: "#4e9a06"

    Label {
        id: label
        text: String(digit)
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: height * 7 / 10
        font.bold: true
        color: text_color
    }

    Behavior on y { NumberAnimation { duration: 50; easing.type: Easing.Linear } }
    Behavior on x { NumberAnimation { duration: 50; easing.type: Easing.Linear } }
}
