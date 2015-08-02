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

    signal send_spawn()

    function restart_progress() {
        spawn_timer.stop()
        send_spawn()
    }

    SilicaFlickable {
        id: flickable
        anchors { left: parent.left; right: parent.right }
        width: parent.width
        height: parent.height - parent.width * 8 / 7

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
            }

            MenuItem {
                text: qsTr("Restart")
                onClicked: table.init_game()
            }
        }

        Column {
            width: parent.width
            anchors {
                bottomMargin: Theme.itemSizeSmall
                bottom: parent.bottom
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                id: scoreLabel
                text: qsTr("Score")
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter

                ProgressBar {
                    id: progressBar
                    width: flickable.width * 8 / 10
                    value: 0
                    maximumValue: 8 * 15

                    signal send()

                    function spawn_finish(result) {
                        console.log("spawn finished")
                        value = 0
                        spawn_timer.restart()
                    }

                    function spawn_fail() {
                        console.log("spawn failed")
                        pause.visible = false
                        touch.enabled = false
                    }

                    Timer {
                        id: spawn_timer
                        interval: 125
                        repeat: false
                        onTriggered: {
                            var value = progressBar.value + 1
                            if (value === progressBar.maximumValue) {
                                value = 0
                                send_spawn()
                            } else {
                                restart()
                            }
                            progressBar.value = value
                        }
                        running: false
                    }
                }

                IconButton {
                    id: pause
                    icon.source: "image://theme/icon-l-pause"

                    function toggle_view(playing) {
                        if (playing)
                            icon.source = "image://theme/icon-l-pause"
                        else
                            icon.source = "image://theme/icon-l-play"
                        visible = true
                    }

                    onClicked: {
                        if (spawn_timer.running) {
                            spawn_timer.stop()
                            touch.enabled = false
                        } else {
                            spawn_timer.start()
                            touch.enabled = true
                        }
                        toggle_view(spawn_timer.running)
                    }
                }
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
            clip: true
            color: "#eff6bc"
            radius: height / 50

            height: 8 * width / 7

            MouseArea {
                id: touch
                enabled: false
                anchors.fill: parent
            }

            function init_game() {
                game.layout()
                progressBar.value = 0
                spawn_timer.start()
                touch.enabled = true
                pause.toggle_view(true)
            }

            Component.onCompleted: {
                touch.onPressed.connect(game.touch_start)
                touch.onPositionChanged.connect(game.touch_move)
                touch.onReleased.connect(game.touch_release)
                root.send_spawn.connect(game.spawn)
                game.send_gravitate.connect(game.gravitate)
                game.send_ready_to_spawn.connect(restart_progress)
                game.send_spawn_end.connect(progressBar.spawn_finish)
                game.send_spawn_fail.connect(progressBar.spawn_fail)

                game.box_component = Qt.createComponent("Box.qml")
                init_game()
            }
        }

        Timer {
            id: testTimer
            repeat: false
            interval: 100
            running: false
            triggeredOnStart: true
            onTriggered: {
                console.log("trigger")
            }
        }
    }

    QtObject {
        id: game

        property var box_component
        property var boxes
        property var used

        property var counts
        property int not_single: 0

        // box_size + box_spacing = box_total_size
        property int box_total_size
        property int box_size
        property int box_half_size
        property int box_spacing
        property double lift_offset: 0

        // group of picked boxes: it contains the boxes themselves
        property var pgroup: []
        property double touch_x
        property double touch_y

        property double kEps: 1e-6

        property int spawns: 0

        signal send_gravitate()
        signal send_ready_to_spawn()
        signal send_spawn_end()
        signal send_spawn_fail()

        property string lock_owner: ""
        property bool taken: false

        function get_lock(name) {
            if (taken) {
                console.log("lock is taken by " + lock_owner + " before " + name)
            }
            taken = true
            lock_owner = name
        }

        function release_lock() {
            taken = false
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
                var saved = boxes[r][c]
                box.set_to_destroy(function() {
                    increase_digit(saved)
                    send_gravitate()
                })
                return false
            }
            boxes[r][c] = box
            box.set_cell(r, c)
            //console.log("bind " + box.digit + " at " + box.row + "," + box.column)
            return true
        }

        function align_with_grid(box, r, c, speed) {
            bind_to_grid(box, r, c)
            box.virtual_move_to(grid_x(c), grid_y(r), speed)
        }

        // move existing rows up: return true if no boxes should be destroyed for the move,
        //  otherwise return false and don't move
        function lift_boxes() {
            get_lock("lift-1")
            var step = box_total_size / 5.0
            var rungs = []
            for (var i = 0; i < 4; ++i)
                rungs.push(step)
            rungs.push(box_total_size - 4 * step)

            var ok = true
            lift_offset = 0
            for (var ik in rungs) {
                lift_offset += rungs[ik]
                //console.log("lift offset: " + lift_offset)
                for (var r = 0; r <= kAreaRows; ++r) {
                    for (var c = 0; c < kAreaColumns; ++c) {
                        var box = boxes[r][c]
                        if (typeof box === 'undefined')
                            continue
                        box.set_phys_virt_diff(-lift_offset, 0)
                        if (box.pos_y < kEps) {
                            console.log("box " + box.digit + " is out of the table")
                            ok = false
                        }
                    }
                }
                if (!ok) {
                    send_spawn_fail()
                    return
                }
                if (pgroup.length > 0) {
                    release_lock()
                    move_to(touch_x, touch_y + lift_offset)
                    get_lock("lift-2")
                }
            }
            for (var r = 1; r <= kAreaRows; ++r) {
                for (var c = 0; c < kAreaColumns; ++c) {
                    var box = boxes[r][c]
                    if (typeof box === 'undefined')
                        continue
                    //align_with_grid(box, r - 1, c, 2)
                    bind_to_grid(box, r - 1, c)
                    box.relax_diff()
                    boxes[r][c] = undefined
                }
            }
            lift_offset = 0
            ++spawns
            release_lock()
            send_gravitate()
            send_spawn_end()
        }

        // TODO refactor: merge two funcs into one
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

        function set_digit(b, digit) {
            ++counts[digit]
            if (counts[digit] === 2)
                ++not_single
            b.set_digit(digit)
        }

        function increase_digit(b) {
            counts[b.digit] -= 2
            if (counts[b.digit] === 0 || counts[b.digit] === 1)
                --not_single
            var new_digit = b.digit + 1
            ++counts[new_digit]
            if (counts[new_digit] === 2)
                ++not_single
            if (not_single < 1)
                send_ready_to_spawn()
            b.evolve()
        }

        // init the lowest row
        function add_row() {
            get_lock("add-row")
            var r = kAreaRows
            for (var c = 0; c < kAreaColumns; ++c) {
                var upper = -1
                if (typeof boxes[r - 1][c] !== 'undefined')
                    upper = boxes[r - 1][c].digit
                var b = box_component.createObject(table, { width: box_total_size, box_spacing: box_spacing })
                set_digit(b, Util.generate_number(Math.min(4 + spawns / 5, 19), upper))
                align_with_grid(b, r, c, 2)
            }
            var binding_slots = kAreaColumns * 2 - 1
            var max_bindings = Math.min(spawns / 2, binding_slots - 4)
            var prob = max_bindings / binding_slots
            var bindings = 0
            // bind to the right
            for (var c = 0; bindings < max_bindings && c + 1 < kAreaColumns; ++c) {
                if (Math.random() < prob && boxes[r][c].digit !== boxes[r][c + 1].digit) {
                    ++bindings
                    boxes[r][c].bind(Logic.kRight, boxes[r][c + 1])
                    boxes[r][c + 1].bind(Logic.kLeft, boxes[r][c])
                }
            }
            // bind to the top
            for (var c = 0; bindings < max_bindings && c < kAreaColumns; ++c) {
                var box = boxes[r][c]
                var above = boxes[r - 1][c]
                if (typeof above !== 'undefined' && box.digit !== above.digit && !above.floating && !above.to_be_destroyed && Math.random() < prob) {
                    ++bindings
                    box.bind(Logic.kTop, above)
                    above.bind(Logic.kBottom, box)
                }
            }
            release_lock()
        }

        function spawn() {
            add_row()
            /*
            var tt = 1000 * 1000 * 1000
            var ss = 0
            console.log("waiting")
            for (var i = 0; i < tt; ++i)
                ss += i * (i - 1)
            */
            console.log("lifting")
            lift_boxes()
            console.log("lifted")
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

        function touch_start(mouse_event) {
            //console.log("touch start: " + mouse_event.x + "," + mouse_event.y)
            select(mouse_event.x, mouse_event.y + lift_offset)
        }

        // Coordinates are virtual
        function select(x, y) {
            if (pgroup.length > 0) {
                return
            }
            get_lock("select")

            var column = x_to_column(x)
            // TODO virtual y?
            var row = y_to_row(y)
            if (0 > column || column >= kAreaColumns
                  || 0 > row && row >= kAreaRows) {
                release_lock()
                return
            }
            var picked = boxes[row][column]
            if (typeof picked === 'undefined') {
                release_lock()
                return
            }
            // TODO implement "catching"
            if (picked.floating) {
                release_lock()
                return
            }
            Util.fill_2d_array(used, false)
            pgroup = bfs(picked)
            for (var i in pgroup)
                pgroup[i].floating = true
            release_lock()
        }

        function center_of_box(box) {
            var top_left = box.get_virtual()
            return Util.make_point(top_left.x + box_half_size, top_left.y + box_half_size)
        }

        function make_box(center) {
            return { pos_x: center.x - box_half_size, pos_y: center.y - box_half_size }
        }

        function cell_is_free(row, column) {
            return 0 <= row && row < kAreaRows &&
                   0 <= column && column < kAreaColumns &&
                   (typeof boxes[row][column] === 'undefined' || boxes[row][column].floating)
        }

        function move_too_small(move) {
            return Math.abs(move.x) < kEps && Math.abs(move.y) < kEps
        }

        function touch_move(mouse_event) {
            //console.log("touch move: " + mouse_event.x + "," + mouse_event.y)
            touch_x = mouse_event.x
            touch_y = mouse_event.y
            move_to(mouse_event.x, mouse_event.y + lift_offset)
        }

        /* 1. Works with virtual coordinates
         * 2. Lock should be taken in advance
         */
        function move_to(x, y) {
            if (pgroup.length === 0) {
                return
            }
            get_lock("move-1")
            //console.log("move: start, to row " + y_to_row(y))
            var target = Util.make_point(x, y)
            var step_limit = box_half_size - kEps

            while (pgroup.length > 0) {
                var center = center_of_box(pgroup[0])
                // 1. Move a little
                var move = Util.point_diff(target, center)

                // Stop if target is reached
                if (move_too_small(move))
                    break

                // Confine a single movement
                var t = Math.max(Math.abs(move.x / step_limit), Math.abs(move.y / step_limit))
                if (t > 1) {
                    move.x /= t
                    move.y /= t
                }

                // 2. Check for collision with walls and push out
                for (var i in pgroup) {
                    var cur_center = center_of_box(pgroup[i])
                    var cur_next = Util.point_sum(cur_center, move)
                    cur_next.x = Math.min(Math.max(cur_next.x, box_half_size + kEps), table.width - kEps - box_half_size)
                    cur_next.y = Math.min(Math.max(cur_next.y, box_half_size + kEps), table.height - kEps - box_half_size)
                    move = Util.point_diff(cur_next, cur_center)
                }

                // 3. Find bounding cells ranges
                var left_column = kAreaColumns - 1, right_column = 0
                var top_row = kAreaRows - 1, bottom_row = 0
                for (var i in pgroup) {
                    var cur_center = center_of_box(pgroup[i])
                    var cur_next = Util.point_sum(cur_center, move)
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
                        var top_left = fixed.get_virtual()
                        for (var i in pgroup) {
                            var cur = pgroup[i].get_virtual()
                            var box = Util.point_sum(cur, move)
                            if (fixed.digit === pgroup[i].digit || !Util.find_collision(top_left, box, box_size))
                                continue
                            // find a direction with the smallest overlap
                            var overlap = 1e9
                            var reverse = Util.make_point(0, 0)
                            if (move.x > kEps && cell_is_free(row, column - 1)) {
                                var right = box.x + box_size
                                var fixed_left = top_left.x
                                var o = right - fixed_left
                                if (0 < o && o < box_size) {
                                    overlap = right - fixed_left
                                    reverse.x = -(right - fixed_left + kEps)
                                }
                            } else if (move.x < -kEps && cell_is_free(row, column + 1)) {
                                var left = box.x
                                var fixed_right = top_left.x + box_size
                                var o = fixed_right - left
                                if (0 < o && o < box_size) {
                                    overlap = fixed_right - left
                                    reverse.x = fixed_right - left + kEps
                                }
                            }
                            if (move.y > kEps && cell_is_free(row - 1, column)) {
                                var bottom = box.y + box_size
                                var fixed_top = top_left.y
                                var o = bottom - fixed_top
                                if (0 < o && o < box_size && o < overlap) {
                                    overlap = bottom - fixed_top
                                    reverse.x = 0
                                    reverse.y = -(bottom - fixed_top + kEps)
                                }
                            } else if (move.y < -kEps && cell_is_free(row + 1, column)) {
                                var top = box.y
                                var fixed_bottom = top_left.y + box_size
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
                            move = Util.point_sum(move, reverse)
                        }
                    }
                }
                // Check if there is any effect
                if (move_too_small(move))
                    break
                // Check if boxes are moved out of their current cells
                var row_add = y_to_row(center.y + move.y) - y_to_row(center.y)
                var column_add = x_to_column(center.x + move.x) - x_to_column(center.x)
                var move_in_grid = row_add !== 0 || column_add !== 0
                //console.log("move: " + move.x + ", " + move.y)
                // Move the group
                for (var i in pgroup) {
                    var box = pgroup[i]
                    box.move_with_vector(move, 1)
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
                        release_lock()
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
                    release_lock()
                    gravitate()
                    get_lock("move-2")
                }
            }
            release_lock()
        }

        /* 1. Search at each step for boxes, that should fall at least 1 level down
         * and drop them 1 unit down exactly.
         * 2. Works with virtual coordinates.
         */
        function gravitate() {
            get_lock("gravitate")
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
                    align_with_grid(box, box.row + 1, box.column, 0)
                }
            } while (fgroup.length > 0)
            release_lock()
        }

        function touch_release() {
            //console.log("touch release")
            complete()
        }

        /* 1. Works with virtual coordinates
         * 2. Lock should be taken in advance
         */
        function complete() {
            if (pgroup.length === 0) {
                return
            }
            get_lock("complete")
            // relax group
            for (var i in pgroup) {
                var box = pgroup[i]
                if (typeof box === 'undefined')
                    continue
                box.virtual_move_to(grid_x(box.column), grid_y(box.row), 0)
                box.floating = false
            }
            pgroup = []
            release_lock()
            // drop all
            gravitate()
        }

        function layout() {
            // destroy all previously existing boxes
            if (typeof boxes !== 'undefined') {
                for (var r = 0; r <= kAreaRows; ++r) {
                    for (var c = 0; c < kAreaColumns; ++c) {
                        if (typeof boxes[r][c] !== 'undefined') {
                            boxes[r][c].destroy()
                            boxes[r][c] = undefined
                        }
                    }
                }
            }

            boxes = Util.make_2d_array(kAreaRows + 1, kAreaColumns)
            used = Util.make_2d_array(kAreaRows + 1, kAreaColumns)
            counts = Util.make_filled_array(21, 0)
            not_single = 0

            var hsize = table.width / kAreaColumns
            var vsize = table.height / kAreaRows
            box_total_size = Math.floor(Math.min(hsize, vsize))
            box_spacing = box_total_size / 10
            box_size = box_total_size - box_spacing
            box_half_size = box_size / 2
            lift_offset = 0

            spawns = 0
            spawn()
            spawn()
        }
    }
}


