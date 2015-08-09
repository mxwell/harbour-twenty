import QtQuick 2.1
import Sailfish.Silica 1.0


Dialog {
    id: about
    canAccept: true

    SilicaListView {
        id: flickable
        anchors.fill: parent

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: "Twenty v0.1"
                anchors.horizontalCenter: parent.horizontalCenter
                acceptText: qsTr("Close")
            }

            Label {
                textFormat: Text.RichText
                horizontalAlignment: Text.Center
                anchors.horizontalCenter: parent.horizontalCenter
                text: "<a href=\"http://twenty.frenchguys.net/\">" + qsTr("Original game") + "</a>"

                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }

            Label {
                textFormat: Text.RichText
                horizontalAlignment: Text.Center
                anchors.horizontalCenter: parent.horizontalCenter
                text: "<a href=\"http://github.com/\">" + qsTr("Github") + "</a>"

                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }

            Label {
                horizontalAlignment: Text.Center
                anchors.horizontalCenter: parent.horizontalCenter
                text: "2015"
            }
        }

        VerticalScrollDecorator {}
    }
}





