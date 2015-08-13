import QtQuick 2.1
import Sailfish.Silica 1.0
import "../pages"

CoverBackground {
    Column {
        anchors.fill: parent
        spacing: Theme.itemSizeSmall

        Rectangle {
            width: parent.width
            height: Theme.paddingSmall
            color: "transparent"
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Twenty")
            font.bold: true
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            Box {
                id: cover_score
                width: Theme.itemSizeSmall
                box_spacing: width / 10
            }

            Label {
                id: cover_multiplier
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            if (max_number > 0)
                cover_score.set_digit(max_number)
            if (score > 1)
                cover_multiplier.text = "x" + String(score)
            else
                cover_multiplier.text = ""
        }
    }
}


