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

        Rectangle {
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
            color: "#eff6bc"
            radius: height / 50

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
        property int box_half_size
        property int box_spacing

        // group of picked boxes: it contains the boxes themselves
        property var pgroup: []

        property var adjacent_dr: [-1, 0, 0, 1]
        property var adjacent_dc: [0, -1, 1, 0]

        property double kEps: 1e-6
        property int kTop: 0
        property int kLeft: 1
        property int kRight: 2
        property int kBottom: 3

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

        function unbind_from_grid(box) {
            boxes[box.row][box.column] = undefined
        }

        function bind_to_grid(box, r, c) {
            if (typeof boxes[r][c] !== 'undefined') {
                console.log("about to lose box at " + r + "," + c)
            }
            boxes[r][c] = box
            box.set_cell(r, c)
            //console.log("bind " + box.digit + " at " + box.row + "," + box.column)
        }

        function align_with_grid(box, r, c) {
            bind_to_grid(box, r, c)
            box.move_to(grid_x(c), grid_y(r))
        }

        // move existing rows up: return true if no boxes should be destroyed for the move,
        //  otherwise return false and don't move
        function lift_boxes() {
            for (var c = 0; c < kAreaColumns; ++c)
                if (boxes[0][c] !== undefined)
                    return false
            for (var r = 1; r < kAreaRows; ++r) {
                for (var c = 0; c < kAreaColumns; ++c) {
                    var box = boxes[r][c]
                    if (box !== undefined) {
                        box.set_y(grid_y(r - 1))
                        bind_to_grid(box, r - 1, c)
                        boxes[r][c] = undefined
                    }
                }
            }
            return true
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
        function add_row(hor_bind, ver_bind) {
            var r = kAreaRows - 1
            for (var c = 0; c < kAreaColumns; ++c) {
                var upper = -1
                if (boxes[r - 1][c] !== undefined)
                    upper = boxes[r - 1][c].digit
                var digit = generate_digit(upper)
                var color_id = (digit - 1) % colors.length
                var b = box_component.createObject(table, {
                                             digit: digit,
                                             body_color: colors[color_id],
                                             text_color: text_colors[color_id],
                                             width: box_total_size,
                                             box_spacing: box_spacing })
                align_with_grid(b, r, c)
            }
            if (hor_bind) {
                boxes[r][0].set_binding(kRight, true)
                boxes[r][1].set_binding(kLeft, true)
            }
            if (ver_bind) {
                boxes[r][0].set_binding(kTop, true)
                boxes[r - 1][0].set_binding(kBottom, true)
            }
        }

        function select(x, y) {
            if (pgroup.length > 0)
                return
            var column = x_to_column(x)
            var row = y_to_row(y)
            if (0 > column || column >= kAreaColumns
                  || 0 > row && row >= kAreaRows)
                return
            var picked = boxes[row][column]
            if (typeof picked === 'undefined')
                return
            // TODO implement "catching"
            if (picked.floating)
                return
            var qfront = 0
            // queue is surely empty now
            var queue = pgroup
            picked.floating = true
            queue.push(picked)
            while (qfront < queue.length) {
                var box = queue[qfront]
                ++qfront
                var r = box.row, c = box.column
                for (var dir = 0; dir < 4; ++dir) {
                    if (box.adjacent[dir]) {
                        var to_r = r + adjacent_dr[dir]
                        var to_c = c + adjacent_dc[dir]
                        var to = boxes[to_r][to_c]
                        if (!to.floating) {
                            to.floating = true
                            queue.push(to)
                        }
                    }
                }
            }

            var temp = []
            for (var i in pgroup) {
                temp.push(pgroup[i].row + "," + pgroup[i].column)
            }

            //console.log("picked " + pgroup.length + " box(es):" + temp.join("  "))
        }

        function make_point(x, y) {
            return { x: x, y: y }
        }

        function center_of_box(box) {
            return { x: box.pos_x + box_half_size, y: box.pos_y + box_half_size }
        }

        function make_box(center) {
            return { pos_x: center.x - box_half_size, pos_y: center.y - box_half_size }
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
                   (typeof boxes[row][column] === 'undefined' || boxes[row][column].floating)
        }

        function move_to(x, y) {
            if (pgroup.length === 0)
                return
            //console.log("move to " + Math.floor(x) + "," + Math.floor(y))
            var target = make_point(x, y)
            var step_limit = box_half_size - kEps

            while (true) {
                var i, t, cur_center, cur_next, box

                var center = center_of_box(pgroup[0])
                // 1. Move a little
                var move = point_diff(target, center)
                var moving = false
                if (Math.abs(move.x) > kEps) {
                    moving = true
                    if (Math.abs(move.x) > step_limit) {
                        t = Math.abs(move.x / step_limit)
                        move.x /= t
                        move.y /= t
                    }
                }
                if (Math.abs(move.y) > kEps) {
                    moving = true
                    if (Math.abs(move.y) > step_limit) {
                        t = Math.abs(move.y / step_limit)
                        move.x /= t
                        move.y /= t
                    }
                }
                // Target reached
                if (!moving)
                    break

                // 2. Check for collision with walls and push out
                for (i in pgroup) {
                    cur_center = center_of_box(pgroup[i])
                    cur_next = point_sum(cur_center, move)
                    cur_next.x = Math.min(Math.max(cur_next.x, box_half_size + kEps), table.width - kEps - box_half_size)
                    cur_next.y = Math.min(Math.max(cur_next.y, box_half_size + kEps), table.height - kEps - box_half_size)
                    move = point_diff(cur_next, cur_center)
                }
                var temp = point_sum(center, move)
                //console.log("current new center: " + y_to_row(temp.y) + "," + x_to_column(temp.x))

                // 3. Find bounding cells ranges
                var left_column = kAreaColumns - 1, right_column = 0
                var top_row = kAreaRows - 1, bottom_row = 0
                for (i in pgroup) {
                    cur_center = center_of_box(pgroup[i])
                    cur_next = point_sum(cur_center, move)
                    left_column = Math.min(left_column, x_to_column(cur_next.x - box_half_size))
                    right_column = Math.max(right_column, x_to_column(cur_next.x + box_half_size))
                    top_row = Math.min(top_row, y_to_row(cur_next.y - box_half_size))
                    bottom_row = Math.max(bottom_row, y_to_row(cur_next.y + box_half_size))
                }
                left_column = Math.min(Math.max(left_column, 0), kAreaColumns - 1)
                right_column = Math.min(Math.max(right_column, 0), kAreaColumns - 1)
                top_row = Math.min(Math.max(top_row, 0), kAreaRows - 1)
                bottom_row = Math.min(Math.max(bottom_row, 0), kAreaRows - 1)

                //console.log("columns, rows: " + left_column + "-" + right_column + ", " + top_row + "-" + bottom_row)

                //console.log("move: " + Math.floor(move.x) + "," + Math.floor(move.y))
                //var box = make_box(next)

                // 3. Check for collision with boxes and push out
                var intact = []
                for (var column = left_column; column <= right_column; ++column) {
                    for (var row = top_row; row <= bottom_row; ++row) {
                        var fixed = boxes[row][column]
                        if (typeof fixed === 'undefined' || fixed.floating)
                            continue
                        for (i in pgroup) {
                            var cur = make_point(pgroup[i].pos_x, pgroup[i].pos_y)
                            box = point_sum(cur, move)
                            if (!find_collision(fixed, box))
                                continue
                            // find a direction with the smallest overlap
                            var overlap = 1e9
                            var reverse = make_point(0, 0)
                            var o
                            if (move.x > kEps && cell_is_free(row, column - 1)) {
                                var right = box.x + box_size
                                var fixed_left = fixed.pos_x
                                o = right - fixed_left
                                if (0 < o && o < box_size) {
                                    overlap = right - fixed_left
                                    reverse.x = -(right - fixed_left + kEps)
                                }
                            } else if (move.x < -kEps && cell_is_free(row, column + 1)) {
                                var left = box.x
                                var fixed_right = fixed.pos_x + box_size
                                o = fixed_right - left
                                if (0 < o && o < box_size) {
                                    overlap = fixed_right - left
                                    reverse.x = fixed_right - left + kEps
                                }
                            }
                            if (move.y > kEps && cell_is_free(row - 1, column)) {
                                var bottom = box.y + box_size
                                var fixed_top = fixed.pos_y
                                o = bottom - fixed_top
                                if (0 < o && o < box_size && o < overlap) {
                                    overlap = bottom - fixed_top
                                    reverse.x = 0
                                    reverse.y = -(bottom - fixed_top + kEps)
                                }
                            } else if (move.y < -kEps && cell_is_free(row + 1, column)) {
                                var top = box.y
                                var fixed_bottom = fixed.pos_y + box_size
                                o = fixed_bottom - top
                                if (0 < o && o < box_size && o < overlap) {
                                    overlap = fixed_bottom - top
                                    reverse.x = 0
                                    reverse.y = fixed_bottom - top + kEps
                                }
                            }
                            if (overlap > 1e8)
                                continue
                            //console.log("correction: " + Math.floor(reverse.x) + "," + Math.floor(reverse.y))
                            move = point_sum(move, reverse)
                        }
                    }
                }
                // check if there is any effect
                if (Math.abs(move.x) < kEps && Math.abs(move.y) < kEps)
                    break
                // Check if boxes are moved out of their current cells
                var row_add = y_to_row(center.y + move.y) - y_to_row(center.y)
                var column_add = x_to_column(center.x + move.x) - x_to_column(center.x)
                var move_in_grid = row_add !== 0 || column_add !== 0
                // Move the group
                for (i in pgroup) {
                    box = pgroup[i]
                    box.move_with_vector(move)
                    if (move_in_grid)
                        unbind_from_grid(box)
                }
                // Bind boxes to grid again, if they've been moved out of cells
                if (move_in_grid) {
                    for (i in pgroup) {
                        box = pgroup[i]
                        bind_to_grid(box, box.row + row_add, box.column + column_add)
                    }
                }
                //console.log("put into cell " + pgroup[0].row + "," + pgroup[0].column)
            }
        }

        function complete() {
            if (pgroup.length === 0)
                return
            // Find the smallest fall in group and also unbind boxes from the grid
            var fall = kAreaRows - 1
            for (var i in pgroup) {
                var box = pgroup[i]
                var c = box.column
                var r = box.row
                var cur = 0
                for (++r; r < kAreaRows; ++r) {
                    if (typeof boxes[r][c] !== 'undefined' && !boxes[r][c].floating) {
                        break
                    } else {
                        ++cur
                    }
                }
                fall = Math.min(fall, cur)
                unbind_from_grid(box)
            }
            // Bind boxes back to grid, but @fall rows lower
            //console.log("releasing into " + (pgroup[0].row + fall) + "," + pgroup[0].column + "(fall " + fall + ")")
            for (var i in pgroup) {
                align_with_grid(pgroup[i], pgroup[i].row + fall, pgroup[i].column)
                pgroup[i].floating = false
            }
            pgroup = []
        }

        // @a is a normal box object, @p is a box, represented by a topleft point
        function find_collision(a, p) {
            return a.pos_x < p.x + box_size && a.pos_x + box_size > p.x &&
                    a.pos_y < p.y + box_size && a.pos_y + box_size > p.y
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
            if (typeof boxes === 'undefined')
                return

            var hsize = table.width / kAreaColumns
            var vsize = table.height / kAreaRows
            box_total_size = Math.floor(Math.min(hsize, vsize))
            box_spacing = box_total_size / 10
            box_size = box_total_size - box_spacing
            box_half_size = box_size / 2
            destroy_boxes()
            add_row(true, false)
            lift_boxes()
            add_row(false, true)
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


