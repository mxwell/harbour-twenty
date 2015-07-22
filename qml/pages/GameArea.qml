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

        property var corners_dx: [0, 1, 1, 0]
        property var corners_dy: [0, 0, 1, 1]

        // box_size + box_spacing = box_total_size
        property int box_total_size
        property int box_size
        property int box_spacing

        property var picked_box: undefined

        property double kEps: 1e-6

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
                        box.pos_y = box_spacing + (r - 1) * box_total_size
                        box.y = box.pos_y
                    }
                    boxes[r - 1][c] = box
                }
            }
        }

        function grid_x(c) {
            return box_spacing + box_total_size * c
        }

        function grid_y(r) {
            return box_spacing + box_total_size * r
        }

        function x_to_column(x) {
            return Math.floor((x - box_spacing) / box_total_size)
        }

        function y_to_row(y) {
            return Math.floor((y - box_spacing) / box_total_size)
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
                var left = box_spacing + c * box_total_size
                var top = box_spacing + r * box_total_size
                boxes[r][c] = box_component.createObject(table, {
                                             digit: digit,
                                             color: colors[color_id],
                                             text_color: text_colors[color_id],
                                             x: left, pos_x: left,
                                             y: top, pos_y: top,
                                             width: box_size })
            }
        }

        // TODO check for falling box
        function select(x, y) {
            if (typeof picked_box !== 'undefined')
                return
            var c = Math.floor((x - box_spacing) / box_total_size)
            var r = Math.floor((y - box_spacing) / box_total_size)
            if (!(0 <= c && c < kAreaColumns && 0 <= r && r <= kAreaRows)) {
                picked_box = undefined
                return
            }
            picked_box = boxes[r][c]
            if (typeof picked_box === 'undefined')
                return
            picked_box.pos_x = grid_x(c)
            picked_box.pos_y = grid_y(r)
            boxes[r][c] = undefined
            console.log("picked at " + r + "," + c)
        }

        function put_box(box, x, y) {
            box.pos_x = x
            box.pos_y = y
            box.x = x
            box.y = y
        }

        function make_point(x, y) {
            return { x: x, y: y }
        }

        function make_box(center) {
            var half = box_size / 2
            return { pos_x: center.x - half, pos_y: center.y - half }
        }

        function point_sum(a, b) {
            return make_point(a.x + b.x, a.y + b.y)
        }

        function point_diff(a, b) {
            return make_point(a.x - b.x, a.y - b.y)
        }

        function cell_is_free(row, column) {
            return 0 <= row && row < kAreaRows &&
                   0 <= column && column < kAreaColumns &&
                   typeof boxes[row][column] === 'undefined'
        }

        function move_to(x, y) {
            //console.log("move to " + Math.floor(x) + "," + Math.floor(y))
            var target = make_point(x, y)

            var half_size = box_size / 2
            var step_limit = half_size - kEps

            var center = make_point(picked_box.pos_x + half_size, picked_box.pos_y + half_size)

            while (true) {
                // 1. Move a little
                var move = point_diff(target, center)
                var moving = false
                if (Math.abs(move.x) > kEps) {
                    moving = true
                    if (Math.abs(move.x) > step_limit) {
                        var t = Math.abs(move.x / step_limit)
                        move.x /= t
                        move.y /= t
                    }
                }
                if (Math.abs(move.y) > kEps) {
                    moving = true
                    if (Math.abs(move.y) > step_limit) {
                        var t = Math.abs(move.y / step_limit)
                        move.x /= t
                        move.y /= t
                    }
                }
                if (!moving) {
                    //console.log("target reached")
                    break
                }

                var next = point_sum(center, move)

                // 2. Check for collision with walls and push out
                next.x = Math.min(Math.max(next.x, half_size + kEps), table.width - kEps - half_size)
                next.y = Math.min(Math.max(next.y, half_size + kEps), table.height - kEps - half_size)
                //console.log("current new center: " + Math.floor(next.x) + "," + Math.floor(next.y) +
                //            " - cell " + x_to_column(next.x) + "," + y_to_row(next.y))

                // 3. Check for collision with boxes and push out
                var left_column = Math.max(x_to_column(next.x - half_size), 0)
                var right_column = Math.min(x_to_column(next.x + half_size), kAreaColumns - 1)
                var top_row = Math.max(y_to_row(next.y - half_size), 0)
                var bottom_row = Math.min(y_to_row(next.y + half_size), kAreaRows - 1)

                //console.log("move: " + Math.floor(move.x) + "," + Math.floor(move.y))
                var box = make_box(next)

                var intact = []
                for (var column = left_column; column <= right_column; ++column) {
                    for (var row = top_row; row <= bottom_row; ++row) {
                        if (column < 0) {
                            console.log("Error: column " + column)
                        }
                        if (row < 0) {
                            console.log("Error: row " + row)
                        }

                        var fixed = boxes[row][column]
                        if (typeof fixed === 'undefined' || !find_collision(box, fixed))
                            continue
                        //console.log("collision with box @" + row + "," + column)
                        intact.push(column + "-" + row)
                        // find a direction with the smallest overlap
                        var overlap = 1e9
                        var reverse = make_point(0, 0)
                        if (move.x > kEps && column === right_column && cell_is_free(row, column - 1)) {
                            var right = box.pos_x + box_size
                            var fixed_left = fixed.pos_x
                            var o = right - fixed_left
                            if (0 < o && o < box_size) {
                                overlap = right - fixed_left
                                reverse.x = -(right - fixed_left + kEps)
                            }
                        } else if (move.x < -kEps && column === left_column && cell_is_free(row, column + 1)) {
                            var left = box.pos_x
                            var fixed_right = fixed.pos_x + box_size
                            var o = fixed_right - left
                            if (0 < o && o < box_size) {
                                overlap = fixed_right - left
                                reverse.x = fixed_right - left + kEps
                            }
                        }
                        if (move.y > kEps && row === bottom_row && cell_is_free(row - 1, column)) {
                            var bottom = box.pos_y + box_size
                            var fixed_top = fixed.pos_y
                            var o = bottom - fixed_top
                            if (0 < o && o < box_size && o < overlap) {
                                overlap = bottom - fixed_top
                                reverse.x = 0
                                reverse.y = -(bottom - fixed_top + kEps)
                            }
                        } else if (move.y < -kEps && row === top_row && cell_is_free(row + 1, column)) {
                            var top = box.pos_y
                            var fixed_bottom = fixed.pos_y + box_size
                            var o = fixed_bottom - top
                            if (0 < o && o < box_size && o < overlap) {
                                overlap = fixed_bottom - top
                                reverse.x = 0
                                reverse.y = fixed_bottom - top + kEps
                            }
                        }
                        if (overlap > 1e8) {
                            console.log("Error: collision without overlaps")
                            continue
                        }
                        //console.log("correction: " + Math.floor(reverse.x) + "," + Math.floor(reverse.y))
                        box.pos_x += reverse.x
                        box.pos_y += reverse.y
                    }
                }
                //if (intact.length > 0)
                //    console.log("intact: " + intact.join(" "))

                if (Math.abs(picked_box.pos_x - box.pos_x) < kEps
                        && Math.abs(picked_box.pos_y - box.pos_y) < kEps)
                    break
                put_box(picked_box, box.pos_x, box.pos_y)
                center = make_point(box.pos_x + half_size, box.pos_y + half_size)
                //console.log("putting into center of " + x_to_column(center.x) + "," + y_to_row(center.y))
            }
        }

        function complete() {
            if (typeof picked_box === 'undefined')
                return
            //var center_x = picked_box.pos_x - box_spacing + box_total_size / 2.0
            //var c = Math.floor(center_x / box_total_size)
            var half_size = box_size / 2
            var center = make_point(picked_box.pos_x + half_size, picked_box.pos_y + half_size)
            var c = Math.min(Math.max(x_to_column(center.x), 0), kAreaColumns - 1)
            var r = Math.min(Math.max(y_to_row(center.y), 0), kAreaRows - 1)
            //var to_x = grid_x(c)
            //var center_y = picked_box.pos_y - box_spacing
            //var r = Math.floor(center_y / box_total_size)
            for (; r < kAreaRows; ++r) {
                if (typeof boxes[r][c] !== 'undefined') {
                    put_box(picked_box, grid_x(c), grid_y(r - 1))
                    boxes[r - 1][c] = picked_box
                    picked_box = undefined
                    console.log("released into " + (r - 1) + ", " + c)
                    return
                }
            }
            put_box(picked_box, grid_x(c), grid_y(kAreaRows - 1))
            boxes[kAreaRows - 1][c] = picked_box
            picked_box = undefined
            console.log("released into " + (kAreaRows - 1) + ", " + c)
        }

        function find_collision(a, b) {
            return a.pos_x < b.pos_x + box_size && a.pos_x + box_size > b.pos_x &&
                    a.pos_y < b.pos_y + box_size && a.pos_y + box_size > b.pos_y
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
            //test_1()
            //test_2()
        }

        function test_1() {
            console.log("prepare test 1..")
            console.log("box spacing " + box_spacing + ", box size " + box_size)
            picked_box = {pos_x: grid_x(0), pos_y: grid_y(5)}
            move_to(grid_x(0) + box_size / 2.0, grid_y(6) + box_size / 2.0)
            console.log("[1] box now at " + picked_box.pos_x + "," + picked_box.pos_y)
            move_to(grid_x(0) + box_size / 2.0, grid_y(4) + box_size / 2.0)
            console.log("[2] box now at " + picked_box.pos_x + "," + picked_box.pos_y)
            picked_box = undefined
        }

        function test_2() {
            console.log("prepare test 2..")
            var half = box_size / 2.0
            select(grid_x(1) + half, grid_y(6) + half)
            move_to(grid_x(2) + half, grid_y(5) + half)
            console.log("[3] box now at " + picked_box.pos_x + "," + picked_box.pos_y)
            move_to(grid_x(1) + half, grid_y(5) + half)
            console.log("[4] box now at " + picked_box.pos_x + "," + picked_box.pos_y)
            complete()
        }
    }
}


