/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.1
import Sailfish.Silica 1.0


Page {
    id: root

    property int kAreaRows: 8
    property int kAreaColumns: 7

    SilicaFlickable {
        id: flickable
        anchors { left: parent.left; right: parent.right }
        width: parent.width
        height: 100

        PullDownMenu {
            MenuItem {
                text: qsTr("Some action")
                onClicked: {}
            }
        }

        Row {
            id: statusRow
            anchors.fill: parent

            Label {
                text: qsTr("Score")
            }

            Button {
                text: qsTr("Pause")
            }
        }
    }

    Item {
        id: gameArea
        anchors {
            top: flickable.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Item {
            id: table
            anchors {
                left: parent.left
                leftMargin: Theme.paddingMedium
                right: parent.right
                rightMargin: Theme.paddingMedium
                topMargin: Theme.paddingMedium
                bottom: parent.bottom
                bottomMargin: Theme.paddingLarge
            }

            height: 8 * width / 7

            MouseArea {
                anchors.fill: parent
                onPressed: game.select(mouse.x, mouse.y)
                onPositionChanged: game.move_to(mouse.x, mouse.y)
                onReleased: game.complete()
            }

            Component.onCompleted: {
                game.box_component = Qt.createComponent("Box.qml")

                game.boxes = new Array(kAreaRows)
                for (var i = 0; i < kAreaRows; ++i)
                    game.boxes[i] = new Array(kAreaColumns)

                game.layout()
            }
        }

    }

    QtObject {
        id: game

        property var box_component
        property var boxes
                                    /*   1     |    2     |   3      |    4     |   5      |    6     |    7     |    8     |    9    */
        property var colors:        ["#ffff9c", "#ff2421", "#00f3ad", "#298aff", "#dea6ff", "#31eb00", "#ffd2bd", "#9c00f7", "#ffb600" ]
        property var text_colors:   ["#8b8e00", "#ffffff", "#ffffff", "#ffffff", "#ffffff", "#ffffff", "#ff5500", "#ffffff", "#ffffff" ]

        property int box_total_size
        property int box_size
        property int box_spacing

        function generate_digit(upper_digit) {
            var digit
            while (true) {
                digit = Math.floor(1 + Math.random() * 9)
                if (digit !== upper_digit) {
                    break
                }
            }
            return digit
        }

        // move existing rows up
        function lift_boxes() {
            for (var c = 0; c < kAreaColumns; ++c)
                if (boxes[0][c] !== undefined) {
                    boxes[0][c].destroy()
                    boxes[0][c] = undefined
                }
            for (var r = 1; r < kAreaRows; ++r) {
                for (var c = 0; c < kAreaColumns; ++c) {
                    var box = boxes[r][c]
                    if (box !== undefined) {
                        box.y = box_spacing + (r - 1) * box_total_size
                    }
                    boxes[r - 1][c] = box
                }
            }
        }

        // init the lowest row
        function add_row() {
            var r = kAreaRows - 1
            for (var c = 0; c < kAreaColumns; ++c) {
                var upper = -1
                if (boxes[r - 1][c] !== undefined)
                    upper = boxes[r - 1][c].digit
                var digit = generate_digit(upper)
                var color_id = (digit - 1) % colors.length
                boxes[r][c] = box_component.createObject(table, {
                                             digit: digit,
                                             color: colors[color_id],
                                             text_color: text_colors[color_id],
                                             x: box_spacing + c * box_total_size,
                                             y: box_spacing + r * box_total_size,
                                             width: box_size })
            }
        }

        function select(x, y) {
            console.log("select " + x + "," + y)
        }

        function move_to(x, y) {
            console.log("move to " + x + "," + y)
        }

        function complete() {
            console.log("complete now")
        }

        function destroy_boxes() {
            for (var r = 0; r < kAreaRows; ++r)
                for (var c = 0; c < kAreaColumns; ++c)
                    if (typeof boxes[r][c] !== 'undefined') {
                        boxes[r][c].destroy()
                        boxes[r][c] = undefined
                    }
        }

        function layout() {
            if (boxes === undefined)
                return

            var hsize = table.width / kAreaColumns
            var vsize = table.height / kAreaRows
            box_total_size = Math.floor(Math.min(hsize, vsize))
            box_spacing = box_total_size / 10
            box_size = box_total_size - box_spacing
            destroy_boxes()
            add_row()
            lift_boxes()
            add_row()
        }
    }
}


