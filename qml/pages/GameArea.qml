import QtQuick 2.1
import Sailfish.Silica 1.0
import "./Logic.js" as Logic
import "./Util.js" as Util


Page {
    property int kAreaRows: 8
    property int kAreaColumns: 7

    function restart_progress() {
        spawn_timer.stop()
        game.start_lift()
    }

    function init_game() {
        table.game_state = Logic.kGameStateNo
        game_over.visible = false
        restart_button.visible = false

        spawn_timer.stop()
        progressBar.value = 0
        progressBar.visible = true
        table.opacity = 0.25
        pause.toggle_view(false)

        game.layout()
        table.game_state = Logic.kGameStateCreated
    }

    function launch_game() {
        if (table.game_state !== Logic.kGameStateCreated
                && table.game_state !== Logic.kGameStatePaused) {
            console.log("ERROR: launch game when state is " + table.game_state)
        }
        table.opacity = 1
        touch.enabled = true
        pause.toggle_view(true)
        spawn_timer.start()
        table.game_state = Logic.kGameStateStarted
    }

    function pause_game(check_state) {
        if (table.game_state !== Logic.kGameStateStarted) {
            if (check_state)
                return
            console.log("ERROR: pause game when state is " + table.game_state)
        }
        spawn_timer.stop()
        touch.enabled = false
        table.opacity = 0.25
        pause.toggle_view(false)
        table.game_state = Logic.kGameStatePaused
    }

    function update_score() {
        if (score_box.get_digit() !== max_number)
            score_box.set_digit(max_number)
        if (score > 1)
            score_multiplier.text = "x " + String(score)
        else
            score_multiplier.text = ""
    }

    SilicaFlickable {
        id: flickable
        anchors { left: parent.left; right: parent.right }
        width: parent.width
        height: parent.height - parent.width * 8 / 7

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: {
                    if (table.game_state === Logic.kGameStateStarted)
                        pause_game()
                    pageStack.push("AboutPage.qml")
                }
            }

            MenuItem {
                text: qsTr("Restart")
                onClicked: {
                    init_game()
                    launch_game()
                }
            }
        }

        Column {
            width: parent.width
            anchors {
                bottomMargin: Theme.itemSizeSmall
                bottom: parent.bottom
            }

            Row {
                id: score_row
                anchors.horizontalCenter: parent.horizontalCenter

                Box {
                    id: score_box
                    width: Theme.itemSizeSmall
                    box_spacing: width / 10
                }

                Label {
                    id: score_multiplier
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter

                ProgressBar {
                    id: progressBar
                    width: flickable.width * 8 / 10
                    value: 0
                    maximumValue: 8 * 15

                    function spawn_finish() {
                        value = 0
                        if (table.game_state === Logic.kGameStateStarted)
                            spawn_timer.restart()
                    }

                    function spawn_fail() {
                        console.log("spawn failed")
                        progressBar.visible = false
                        pause.visible = false
                        touch.enabled = false

                        table.opacity = 0.25
                        game_over.y = -game_over.height
                        game_over.visible = true
                        game_over_move.start()

                        restart_button.y = gameArea.height
                        restart_button.visible = true
                        restart_button_move.start()
                        table.game_state = Logic.kGameStateNo
                    }

                    Timer {
                        id: spawn_timer
                        interval: 125
                        repeat: false
                        onTriggered: {
                            var value = progressBar.value + 1
                            if (value === progressBar.maximumValue) {
                                value = 0
                                game.start_lift()
                            } else if (table.game_state === Logic.kGameStateStarted) {
                                restart()
                            }
                            progressBar.value = value
                        }
                        running: false
                    }

                    Timer {
                        id: scroll_timer
                        interval: 50
                        repeat: false
                        onTriggered: game.add_task_scroll()
                    }

                    Timer {
                        id: gravity_timer
                        interval: Logic.kGravityDelay
                        repeat: false

                        function start_if_stopped() {
                            if (!running)
                                start()
                        }
                        onTriggered: game.add_task_gravitate()
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
                        if (table.game_state === Logic.kGameStateStarted)
                            pause_game()
                        else
                            launch_game()
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
                onPressed: game.send_touch_select(mouse.x, mouse.y)
                onPositionChanged: game.send_touch_move(mouse.x, mouse.y)
                onReleased: game.send_touch_release()
            }

            property int game_state: Logic.kGameStateNo

            Component.onCompleted: {
                game.send_ready_to_spawn.connect(restart_progress)
                game.send_score_change.connect(update_score)
                game.send_spawn_end.connect(progressBar.spawn_finish)
                game.send_spawn_fail.connect(progressBar.spawn_fail)
                game.send_start_scroll_timer.connect(scroll_timer.start)
                game.send_start_gravity_timer.connect(gravity_timer.start_if_stopped)

                game.box_component = Qt.createComponent("Box.qml")
                // one-time action
                game.init()

                init_game()
            }
        }

        Item {
            id: final_splash
            anchors.fill: parent

            Label {
                id: game_over
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
                visible: false
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeLarge
                text: qsTr("Game over")
                fontSizeMode: Text.HorizontalFit

                NumberAnimation on y {
                    id: game_over_move
                    from: -game_over.height
                    to: Theme.itemSizeLarge
                    duration: 500
                    easing.type: Easing.Linear
                }
            }

            Button {
                id: restart_button
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
                visible: false
                text: qsTr("New game")
                onClicked: {
                    init_game()
                    launch_game()
                }

                SequentialAnimation on y {
                    id: restart_button_move
                    PauseAnimation { duration: 300 }
                    NumberAnimation {
                        from: gameArea.height
                        to: Theme.itemSizeLarge + 2 * game_over.height
                        duration: 500
                        easing.type: Easing.Linear
                    }
                }
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

        // lift vars
        property double lift_offset: 0
        property var lift_rungs
        property int lift_pos: 0

        // group of picked boxes: it contains the boxes themselves
        property var pgroup: []
        property double touch_x
        property double touch_y

        property double kEps: 1e-6

        property int spawns: 0

        /* External signals */
        signal send_ready_to_spawn()
        signal send_spawn_end()
        signal send_spawn_fail()
        signal send_score_change()
        signal send_start_scroll_timer()
        signal send_start_gravity_timer()

        /*** Task queue ***/
        property var task_queue
        property bool idle: true

        /* signals to invoke if one wants to schedule some task */
        signal send_gravitate()
        signal send_scroll()
        signal send_touch_select(double x, double y)
        signal send_touch_move(double x, double y)
        signal send_touch_release()
        signal send_evolve(var b)

        function init() {
            game.send_gravitate.connect(add_task_gravitate)
            game.send_scroll.connect(add_task_scroll)
            game.send_touch_select.connect(add_task_select)
            game.send_touch_move.connect(add_task_move)
            game.send_touch_release.connect(add_task_release)
            game.send_evolve.connect(add_task_evolve)
        }

        // add to task queue, and execute it immediately if idle
        function run_or_schedule(task) {
            Util.queue_push(task_queue, task)
            if (!idle)
                return
            idle = false
            while (!Util.queue_empty(task_queue)) {
                var next = Util.queue_pop(task_queue)
                next.body()
            }
            idle = true
        }

        function add_task_gravitate() {
            run_or_schedule(Util.make_task("gravitate", gravitate))
        }

        function add_task_scroll() {
            run_or_schedule(Util.make_task("scroll", lift_step))
        }

        // physical coordinates
        function add_task_select(x, y) {
            run_or_schedule(Util.make_task("select", function() {
                touch_start(x, y)
            }))
        }

        // physical coordinates
        function add_task_move(x, y) {
            run_or_schedule(Util.make_task("move", function() {
                touch_move(x, y)
            }))
        }

        function add_task_release() {
            run_or_schedule(Util.make_task("release", complete))
        }

        function add_task_evolve(box) {
            run_or_schedule(Util.make_task("evolve", function() {
                if (typeof box !== 'undefined' && box.to_evolve) {
                    box.to_evolve = false
                    var digit = box.get_digit()
                    box.evolve()
                    add_digit(digit + 1)
                    rm_digit(digit)
                    rm_digit(digit)
                    // destroy box in grid too, if it reached max value
                    if (digit + 1 === Logic.kMaxBoxNumber) {
                        boxes[box.row][box.column] = undefined
                        box.set_to_pop()
                    }
                } else {
                    console.log("ERROR: saved box is lost")
                }
                send_start_gravity_timer()
            }))
        }

        function unbind_from_grid(box) {
            boxes[box.row][box.column] = undefined
        }

        // return true if box is successfully bound, otherwise return false (= it was lost)
        function bind_to_grid(box, r, c) {
            if (typeof boxes[r][c] !== 'undefined') {
                if (boxes[r][c].get_digit() !== box.get_digit()) {
                    console.log("ERROR: losing box at " + r + "," + c + ": replace " + boxes[r][c].get_digit() + " with " + box.get_digit())
                } else if (boxes[r][c] === box) {
                    console.log("ERROR: the same")
                    return true
                }

                box.unbind_all()
                var saved = boxes[r][c]
                saved.unbind_all()
                saved.set_to_evolve()
                box.set_to_destroy(function() {
                    send_evolve(saved)
                })

                return false
            }
            boxes[r][c] = box
            box.set_cell(r, c)
            //console.log("bind " + box.digit + " at " + box.row + "," + box.column)
            return true
        }

        function align_with_grid(box, r, c, speed) {
            box.virtual_move_to(grid_line(c), grid_line(r), speed)
            return bind_to_grid(box, r, c)
        }

        function start_lift() {
            add_row()
            lift_offset = 0
            lift_pos = 0
            send_scroll()
        }

        function lift_step() {
            var ok = true
            if (lift_pos >= lift_rungs.length) {
                // finish the lifting
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
                lift_pos = 0
                ++spawns
                send_start_gravity_timer()
                // notify progress bar
                send_spawn_end()
                return
            }

            //console.log("lifting #" + lift_pos)
            lift_offset += lift_rungs[lift_pos]
            ++lift_pos
            //console.log("lift offset: " + lift_offset)
            for (var r = 0; r <= kAreaRows; ++r) {
                for (var c = 0; c < kAreaColumns; ++c) {
                    var box = boxes[r][c]
                    if (typeof box === 'undefined')
                        continue
                    box.set_phys_virt_diff(-lift_offset, 0)
                    if (box.pos_y < kEps) {
                        console.log("box " + box.get_digit() + " is out of the table")
                        ok = false
                    }
                }
            }
            if (!ok) {
                send_spawn_fail()
                return
            }
            if (pgroup.length > 0)
                send_touch_move(touch_x, touch_y)
            send_start_scroll_timer()
        }

        function grid_line(line_id) {
            return box_spacing + box_total_size * line_id
        }

        function coordinate_to_grid(x) {
            return Math.floor((x - box_spacing) / box_total_size)
        }

        function add_digit(digit) {
            if (digit < Logic.kMaxBoxNumber) {
                ++counts[digit]
                if (counts[digit] === 2)
                    ++not_single
            }
            if (digit > max_number) {
                max_number = digit
                send_score_change()
            }
            if (digit === Logic.kMaxBoxNumber) {
                ++score
                send_score_change()
            }
        }

        function rm_digit(digit) {
            --counts[digit]
            if (counts[digit] === 1)
                --not_single
        }

        // init the lowest row
        function add_row() {
            var r = kAreaRows
            for (var c = 0; c < kAreaColumns; ++c) {
                var upper = -1
                if (typeof boxes[r - 1][c] !== 'undefined')
                    upper = boxes[r - 1][c].get_digit()
                var b = box_component.createObject(table, { width: box_total_size, box_spacing: box_spacing })
                var digit = Util.generate_number(Math.min(4 + spawns / 4, Logic.kMaxBoxNumber - 1), upper)
                b.set_digit(digit)
                add_digit(digit)
                align_with_grid(b, r, c, 2)
            }
            var binding_slots = kAreaColumns * 2 - 1
            var max_bindings = Math.min(spawns / 8, binding_slots - 5)
            var prob = max_bindings / binding_slots
            var bindings = 0
            // bind to the right
            var component_size = 1
            for (var c = 0; bindings < max_bindings && c + 1 < kAreaColumns; ++c) {
                if (Math.random() < prob
                        && boxes[r][c].get_digit() !== boxes[r][c + 1].get_digit()
                        && component_size + 1 <= kAreaColumns - 2) {
                    ++bindings
                    boxes[r][c].bind(Logic.kRight, boxes[r][c + 1])
                    boxes[r][c + 1].bind(Logic.kLeft, boxes[r][c])
                    ++component_size
                } else {
                    component_size = 1
                }
            }
            // bind to the top
            for (var c = 0; bindings < max_bindings && c < kAreaColumns; ++c) {
                var box = boxes[r][c]
                var above = boxes[r - 1][c]
                if (typeof above === 'undefined'
                        || box.get_digit() === above.get_digit()
                        || above.floating
                        || above.to_evolve
                        || above.to_be_destroyed
                        || Math.random() > prob)
                    continue
                // Calculate sizes of components, connected to @box and @above,
                // to not exceed limit for component size
                Util.fill_2d_array(used, false)
                var box_group = bfs(box)
                var above_group = bfs(above)
                if (box_group.length + above_group.length > kAreaColumns - 2)
                    continue
                ++bindings
                box.bind(Logic.kTop, above)
                above.bind(Logic.kBottom, box)
            }
        }

        // return array with all boxes connected to @picked
        function bfs(picked) {
            if (typeof picked === 'undefined')
                return []
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

        // receive physical coordinates
        function touch_start(x, y) {
            //console.log("touch start: " + x + "," + y)
            select(x, y + lift_offset)
        }

        // receive virtual coordinates
        function select(x, y) {
            if (pgroup.length > 0) {
                return
            }
            var column = coordinate_to_grid(x)
            var row = coordinate_to_grid(y)
            if (0 > column || column >= kAreaColumns
                  || 0 > row || row >= kAreaRows) {
                return
            }
            var picked = boxes[row][column]
            // TODO implement "catching"
            if (typeof picked === 'undefined'
                    || picked.to_evolve
                    || picked.floating)
                return
            Util.fill_2d_array(used, false)
            pgroup = bfs(picked)
            for (var i in pgroup)
                pgroup[i].floating = true
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

        // receive physical coordinates
        function touch_move(x, y) {
            //console.log("touch move: " + x + "," + y)
            touch_x = x
            touch_y = y
            move_to(x, y + lift_offset)
        }

        // receive virtual coordinates
        function move_to(x, y) {
            if (pgroup.length === 0) {
                return
            }
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
                    left_column = Math.min(left_column, coordinate_to_grid(cur_next.x - box_half_size))
                    right_column = Math.max(right_column, coordinate_to_grid(cur_next.x + box_half_size))
                    top_row = Math.min(top_row, coordinate_to_grid(cur_next.y - box_half_size))
                    bottom_row = Math.max(bottom_row, coordinate_to_grid(cur_next.y + box_half_size))
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
                            if ((fixed.get_digit() === pgroup[i].get_digit() && !fixed.to_evolve) || !Util.find_collision(top_left, box, box_size))
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
                            move = Util.point_sum(move, reverse)
                        }
                    }
                }
                // Check if there is any effect
                if (move_too_small(move))
                    break
                // Check if boxes are moved out of their current cells
                var row_add = coordinate_to_grid(center.y + move.y) - coordinate_to_grid(center.y)
                var column_add = coordinate_to_grid(center.x + move.x) - coordinate_to_grid(center.x)
                var move_in_grid = row_add !== 0 || column_add !== 0
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
                        complete()
                        return
                    } else if (lost) {
                        reselect()
                    }
                    send_start_gravity_timer()
                }
            }
        }

        function reselect() {
            // get newly picked boxes
            Util.fill_2d_array(used, false)
            var updated_group = bfs(pgroup[0])
            // release the boxes of the difference
            for (var i in pgroup) {
                var b = pgroup[i]
                if (typeof b !== 'undefined' && updated_group.indexOf(b) === -1) {
                    b.virtual_move_to(grid_line(b.column), grid_line(b.row), 0)
                    b.floating = false
                }
            }
            pgroup = updated_group
        }

        /* 1. Search at each step for boxes, that should fall at least 1 level down
         * and drop them 1 unit down exactly.
         * 2. Works with virtual coordinates.
         */
        function gravitate() {
            /* to collect falling boxes */
            var fgroup = []
            Util.fill_2d_array(used, false)
            // freeing: element is set to true if the corresponding box is to be dropped
            var freeing = Util.make_2d_array(kAreaRows, kAreaColumns)
            Util.fill_2d_array(freeing, false)

            for (var r = kAreaRows - 1; r >= 0; --r) {
                for (var c = 0; c < kAreaColumns; ++c) {
                    var box = boxes[r][c]
                    if (typeof box === 'undefined'
                            || used[r][c]
                            || box.floating
                            || box.to_evolve)
                        continue
                    var group = bfs(box)
                    // flag of whether could the group be dropped 1 unit down
                    var flag = true
                    for (var i in group) {
                        var b = group[i]
                        if (b.adjacent[Logic.kBottom])
                            continue
                        var next_row = b.row + 1
                        if (next_row >= kAreaRows) {
                            flag = false
                            break
                        }
                        var under = boxes[next_row][b.column]
                        if (!freeing[next_row][b.column]
                                && typeof under !== 'undefined'
                                && (under.to_evolve || under.get_digit() !== b.get_digit())) {
                            flag = false
                            break
                        }
                    }
                    if (flag) {
                        fgroup = fgroup.concat(group)
                        for (var i in group) {
                            var b = group[i]
                            freeing[b.row][b.column] = true
                        }
                    }
                }
            }
            // unbind all falling
            for (var i in fgroup) {
                var box = fgroup[i]
                unbind_from_grid(box)
            }
            // and bind them lower
            var lost = false // impact on pgroup
            var merged = false // flag if any merge happened
            for (var i in fgroup) {
                var box = fgroup[i]
                var row = box.row + 1
                var column = box.column
                if (align_with_grid(box, row, column, 1))
                    continue
                merged = true
                if (boxes[row][column].floating) {
                    merged = true
                    var id = pgroup.indexOf(boxes[row][column])
                    if (id >= 0) {
                        var p = pgroup[id]
                        p.virtual_move_to(grid_line(p.column), grid_line(p.row), 1)
                        p.floating = false
                        pgroup[id] = undefined
                        lost = true
                    }
                }
            }
            if (lost)
                reselect()
            if (fgroup.length > 0)
                send_start_gravity_timer()
            // check if spawn is required
            if (not_single < 1)
                send_ready_to_spawn()
        }

        // works with virtual coordinates
        function complete() {
            if (pgroup.length === 0) {
                return
            }
            // relax group
            for (var i in pgroup) {
                var box = pgroup[i]
                if (typeof box === 'undefined')
                    continue
                box.virtual_move_to(grid_line(box.column), grid_line(box.row), 0)
                box.floating = false
            }
            pgroup = []
            // drop all
            send_start_gravity_timer()
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
            counts = Util.make_filled_array(Logic.kMaxBoxNumber, 0)
            not_single = 0
            max_number = 0
            score = 0

            var hsize = table.width / kAreaColumns
            var vsize = table.height / kAreaRows
            box_total_size = Math.floor(Math.min(hsize, vsize))
            box_spacing = box_total_size / 8
            box_size = box_total_size - box_spacing
            box_half_size = box_size / 2
            lift_offset = 0
            // init the lift rungs
            var steps_total = 10
            var step = box_total_size / steps_total
            lift_rungs = []
            for (var i = 0; i + 1 < steps_total; ++i)
                lift_rungs.push(step)
            lift_rungs.push(box_total_size - (steps_total - 1) * step)

            // init task queue
            task_queue = Util.queue_new()
            idle = true

            spawns = 0
            start_lift()
        }
    }
}
