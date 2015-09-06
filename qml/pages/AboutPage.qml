import QtQuick 2.1
import Sailfish.Silica 1.0


Dialog {
    id: about
    canAccept: false

    SilicaFlickable {
        id: description
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator { flickable: description }

        Column {
            id: column
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: "Twenty (for Jolla) v0.2"
                anchors.horizontalCenter: parent.horizontalCenter
                acceptText: ""
                cancelText: qsTr("Close")
            }

            SectionHeader {
                text: qsTr("About")
            }

            Label {
                textFormat: Text.RichText
                text: qsTr("This is an open source[1] implementation of Twenty[2], a fast-paced game with numbers and gravity.")
                font.pixelSize: Theme.fontSizeSmall
                width: parent.width - Theme.itemSizeMedium
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.WordWrap
            }

            Label {
                textFormat: Text.RichText
                width: parent.width - Theme.itemSizeMedium
                anchors.horizontalCenter: parent.horizontalCenter
                text: "[1] <a href=\"https://github.com/mxwell/harbour-twenty\">" + qsTr("Github") + "</a>"
                font.pixelSize: Theme.fontSizeSmall

                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }

            Label {
                textFormat: Text.RichText
                width: parent.width - Theme.itemSizeMedium
                anchors.horizontalCenter: parent.horizontalCenter
                text: "[2] <a href=\"http://twenty.frenchguys.net/\">" + qsTr("Original game") + "</a>"
                font.pixelSize: Theme.fontSizeSmall

                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }

            Label {
                horizontalAlignment: Text.Center
                anchors.horizontalCenter: parent.horizontalCenter
                text: "2015"
                font.pixelSize: Theme.fontSizeSmall
            }

            SectionHeader {
                text: qsTr("How to play")
            }

            ListModel {
                id: instructions

                ListElement { name: "You could drag blocks to any free place." }
                ListElement { name: "There is a gravitation." }
                ListElement { name: "Two colliding blocks with the same number transform into a block with the incremented number." }
                ListElement { name: "Your goal is to get to 20." }
            }

            Repeater {
                model: instructions

                delegate: Label {
                    anchors {
                        leftMargin: Theme.itemSizeSmall
                        rightMargin: Theme.itemSizeSmall
                    }
                    text: "- " + name
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width - Theme.itemSizeMedium
                    anchors.horizontalCenter: parent.horizontalCenter
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                width: parent.width
                height: Theme.itemSizeMedium
                color: "transparent"
            }
        }
    }
}





