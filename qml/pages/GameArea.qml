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
import "./Logic.js" as Logic
import "./Util.js" as Util


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
                game.layout()
            }
        }

    }

    QtObject {
        id: game

        property var box_component
        property var boxes
        property var used

        // box_size + box_spacing = box_total_size
        property int box_total_size
        property int box_size
        property int box_half_size
        property int box_spacing

        // group of picked boxes: it contains the boxes themselves
        property var pgroup: []

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

        function unbind_from_grid(box) {
            //console.log("unbinding at row " + box.row + ", column " + box.column)
            boxes[box.row][box.column] = undefined
        }

        // return true if box is successfully bound, otherwise return false (= it was lost)
        function bind_to_grid(box, r, c) {
            if (typeof boxes[r][c] !== 'undefined') {
                if (boxes[r][c].digit !== box.digit) {
                    console.log("ERROR: losing box at " + r + "," + c)
                } else if (boxes[r][c] === box) {
                    console.log("ERROR: the same")
                    return true
                } else {
                    console.log("merging boxes with digit " + box.digit)
                }
                box.unbind_all()
                boxes[r][c].unbind_all()
                box.destroy()
                boxes[r][c].evolve()
                return false
            }
            boxes[r][c] = box
            box.set_cell(r, c)
            //console.log("bind " + box.digit + " at " + box.row + "," + box.column)
            return true
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
                if (typeof boxes[r - 1][c] !== 'undefined')
                    upper = boxes[r - 1][c].digit
                var digit = generate_digit(upper)
                var b = box_component.createObject(table, { width: box_total_size, box_spacing: box_spacing })
                b.set_digit(digit)
                align_with_grid(b, r, c)
            }
            if (hor_bind) {
                boxes[r][0].bind(Logic.kRight, boxes[r][1])
                boxes[r][1].bind(Logic.kLeft, boxes[r][0])
            }
            if (ver_bind) {
                boxes[r][0].bind(Logic.kTop, boxes[r - 1][0])
                boxes[r - 1][0].bind(Logic.kBottom, boxes[r][0])
            }
        }

        // return array with all boxes connected to @picked
        function bfs(picked) {
            if (typeof picked.row === 'undefined' || typeof picked.column === 'undefined') {
                console.log("ERROR: picked has no row or column")
            }
            if (typeof used[picked.row] === 'undefined') {
                console.log("used[" + picked.row + "] is undef")
            }

            used[picked.row][picked.column] = true
            var queue = [picked]
            var qfront = 0
            while (qfront < queue.length) {
                var from = queue[qfront]
                ++qfront
                for (var dir = Logic.kTop; dir <= Logic.kBottom; ++dir) {
                    var to = from.adjacent[dir]
                    if (typeof to === 'undefined' || used[to.row][to.column])
                        continue
                    used[to.row][to.column] = true
                    queue.push(to)
                }
            }
            return queue
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
            Util.fill_2d_array(used, false)
            pgroup = bfs(picked)
            for (var i in pgroup)
                pgroup[i].floating = true
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

            while (pgroup.length > 0) {
                var center = center_of_box(pgroup[0])
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
                // Target reached
                if (!moving)
                    break

                // 2. Check for collision with walls and push out
                for (var i in pgroup) {
                    var cur_center = center_of_box(pgroup[i])
                    var cur_next = point_sum(cur_center, move)
                    cur_next.x = Math.min(Math.max(cur_next.x, box_half_size + kEps), table.width - kEps - box_half_size)
                    cur_next.y = Math.min(Math.max(cur_next.y, box_half_size + kEps), table.height - kEps - box_half_size)
                    move = point_diff(cur_next, cur_center)
                }

                // 3. Find bounding cells ranges
                var left_column = kAreaColumns - 1, right_column = 0
                var top_row = kAreaRows - 1, bottom_row = 0
                for (var i in pgroup) {
                    var cur_center = center_of_box(pgroup[i])
                    var cur_next = point_sum(cur_center, move)
                    left_column = Math.min(left_column, x_to_column(cur_next.x - box_half_size))
                    right_column = Math.max(right_column, x_to_column(cur_next.x + box_half_size))
                    top_row = Math.min(top_row, y_to_row(cur_next.y - box_half_size))
                    bottom_row = Math.max(bottom_row, y_to_row(cur_next.y + box_half_size))
                }
                left_column = Math.min(Math.max(left_column, 0), kAreaColumns - 1)
                right_column = Math.min(Math.max(right_column, 0), kAreaColumns - 1)
                top_row = Math.min(Math.max(top_row, 0), kAreaRows - 1)
                bottom_row = Math.min(Math.max(bottom_row, 0), kAreaRows - 1)

                // 3. Check for collision with boxes and push out
                for (var column = left_column; column <= right_column; ++column) {
                    for (var row = top_row; row <= bottom_row; ++row) {
                        var fixed = boxes[row][column]
                        if (typeof fixed === 'undefined' || fixed.floating)
                            continue
                        for (var i in pgroup) {
                            var cur = make_point(pgroup[i].pos_x, pgroup[i].pos_y)
                            var box = point_sum(cur, move)
                            if (fixed.digit === pgroup[i].digit || !find_collision(fixed, box))
                                continue
                            // find a direction with the smallest overlap
                            var overlap = 1e9
                            var reverse = make_point(0, 0)
                            if (move.x > kEps && cell_is_free(row, column - 1)) {
                                var right = box.x + box_size
                                var fixed_left = fixed.pos_x
                                var o = right - fixed_left
                                if (0 < o && o < box_size) {
                                    overlap = right - fixed_left
                                    reverse.x = -(right - fixed_left + kEps)
                                }
                            } else if (move.x < -kEps && cell_is_free(row, column + 1)) {
                                var left = box.x
                                var fixed_right = fixed.pos_x + box_size
                                var o = fixed_right - left
                                if (0 < o && o < box_size) {
                                    overlap = fixed_right - left
                                    reverse.x = fixed_right - left + kEps
                                }
                            }
                            if (move.y > kEps && cell_is_free(row - 1, column)) {
                                var bottom = box.y + box_size
                                var fixed_top = fixed.pos_y
                                var o = bottom - fixed_top
                                if (0 < o && o < box_size && o < overlap) {
                                    overlap = bottom - fixed_top
                                    reverse.x = 0
                                    reverse.y = -(bottom - fixed_top + kEps)
                                }
                            } else if (move.y < -kEps && cell_is_free(row + 1, column)) {
                                var top = box.y
                                var fixed_bottom = fixed.pos_y + box_size
                                var o = fixed_bottom - top
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
                for (var i in pgroup) {
                    var box = pgroup[i]
                    box.move_with_vector(move)
                    if (move_in_grid)
                        unbind_from_grid(box)
                }
                // Bind boxes to grid again, if they've been moved out of cells
                if (move_in_grid) {
                    // flag if some boxes of the pgroup were merged with fixed boxes
                    var lost = false
                    for (var i in pgroup) {
                        var box = pgroup[i]
                        if (!bind_to_grid(box, box.row + row_add, box.column + column_add)) {
                            pgroup[i] = undefined
                            lost = true
                        }
                    }
                    if (typeof pgroup[0] === 'undefined') {
                        complete()
                        return
                    } else if (lost) {
                        for (var i in pgroup) {
                            var b = pgroup[i]
                            if (typeof b !== 'undefined')
                                b.floating = false
                        }
                        Util.fill_2d_array(used, false)
                        pgroup = bfs(pgroup[0])
                        for (var i in pgroup) {
                            pgroup[i].floating = true
                        }
                    }
                    gravitate()
                }
                //console.log("put into cell " + pgroup[0].row + "," + pgroup[0].column)
            }
        }


        /* Search at each step for boxes, that should fall at least 1 level down
         * and drop them 1 unit down exactly */
        // TODO care for floating boxes
        function gravitate() {            
            /* boxes falling at this step */
            var fgroup
            do {
                fgroup = []
                Util.fill_2d_array(used, false)
                for (var r = 0; r < kAreaRows; ++r) {
                    for (var c = 0; c < kAreaColumns; ++c) {
                        var box = boxes[r][c]
                        if (typeof box === 'undefined' || used[r][c] || box.floating)
                            continue
                        var group = bfs(box)
                        // flag of whether could the group be dropped 1 unit down
                        var flag = true
                        for (var i in group) {
                            var b = group[i]
                            if (b.adjacent[Logic.kBottom])
                                continue
                            var next_row = b.row + 1
                            if (next_row === kAreaRows) {
                                flag = false
                                break
                            }
                            var under = boxes[next_row][b.column]
                            if (typeof under !== 'undefined' && under.digit !== b.digit) {
                                flag = false
                                break
                            }
                        }
                        if (flag)
                            fgroup = fgroup.concat(group)
                    }
                }
                // unbind all falling
                for (var i in fgroup) {
                    var box = fgroup[i]
                    unbind_from_grid(box)
                }
                // and bind them lower
                for (var i in fgroup) {
                    var box = fgroup[i]
                    align_with_grid(box, box.row + 1, box.column)
                }
            } while (fgroup.length > 0);
        }

        function complete() {
            if (pgroup.length === 0)
                return
            //console.log("releasing")
            // relax group
            for (var i in pgroup) {
                var box = pgroup[i]
                if (typeof box === 'undefined')
                    continue
                box.move_to(grid_x(box.column), grid_y(box.row))
                box.floating = false
            }
            pgroup = []
            // drop all
            gravitate()
        }

        // @a is a normal box object, @p is a box, represented by a topleft point
        function find_collision(a, p) {
            return a.pos_x < p.x + box_size && a.pos_x + box_size > p.x &&
                    a.pos_y < p.y + box_size && a.pos_y + box_size > p.y
        }

        function destroy_boxes() {
            for (var r in boxes)
                for (var c in boxes[r])
                    if (typeof boxes[r][c] !== 'undefined') {
                        boxes[r][c].destroy()
                        boxes[r][c] = undefined
                    }
        }

        function layout() {
            if (typeof boxes !== 'undefined') {
                destroy_boxes()
            }
            boxes = Util.make_2d_array(kAreaRows, kAreaColumns)
            used = Util.make_2d_array(kAreaRows, kAreaColumns)

            var hsize = table.width / kAreaColumns
            var vsize = table.height / kAreaRows
            box_total_size = Math.floor(Math.min(hsize, vsize))
            box_spacing = box_total_size / 10
            box_size = box_total_size - box_spacing
            box_half_size = box_size / 2

            add_row(true, false)
            lift_boxes()
            add_row(false, true)
            lift_boxes()
            add_row(false, false)
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


