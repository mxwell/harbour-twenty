import QtQuick 2.1
import QtQuick.Particles 2.0
import Sailfish.Silica 1.0
import "./Logic.js" as Logic
import "./Util.js" as Util

Rectangle {
    id: root
    property int digit

    // difference of the physical and virtual y-coordinate
    property double phys_virt_diff: 0

    // "physical" coordinates of the top left corner
    property double pos_x
    property double pos_y

    // row and column of the occupied cell in the grid
    property int row
    property int column

    // flag of a box picked by a user touch
    property bool floating: false

    // bindings to adjacent boxes: relative position
    // of the neighbor is specified by Logic.adjacent_dr and Logic.adjacent_dc
    property var adjacent: [undefined, undefined, undefined, undefined]

    // saved from GameArea
    property int box_spacing
    property var saved_neighbor

    // for a nice destruction
    property bool to_be_destroyed: false
    property var destroy_callback

    property bool to_evolve: false

    function get_digit() {
        return digit
    }

    function set_digit(d) {
        digit = d
        label.text = String(d)
        body.color = Logic.body_colors[(d - 1) % Logic.body_colors.length]
        label.color = Logic.text_colors[(d - 1) % Logic.text_colors.length]
    }

    function conceal() {
        label.text = ''
        body.color = 'white'
    }

    function reveal() {
        set_digit(digit)
    }

    function set_to_evolve() {
        to_evolve = true
    }

    function evolve() {
        to_evolve = false
        make_smoke()
        set_digit(digit + 1)
    }

    function set_to_pop() {
        to_be_destroyed = true
        destroy_callback = function() {}
        virtual_move_to(pos_x, -200, 0)
    }

    function get_virtual() {
        return Util.make_point(pos_x, pos_y - phys_virt_diff)
    }

    function set_phys_virt_diff(diff, speed) {
        var change = diff - phys_virt_diff
        move_to(pos_x, pos_y + change, speed)
        phys_virt_diff = diff
    }

    // nullify difference, but don't move box
    function relax_diff() {
        phys_virt_diff = 0
    }

    function set_position(tx, ty) {
        pos_x = tx
        pos_y = ty
        x = pos_x
        y = pos_y
    }

    /* 0 - slow, 1 - middle, 2 - instantaneous */
    function move_to(tx, ty, speed) {
        var duration = 0
        if (speed < 2) {
            var dx = tx - pos_x
            var dy = ty - pos_y
            var dist = Math.sqrt(dx * dx + dy * dy)
            if (speed === 0)
                duration = dist * Logic.kSlowMultiplier
            else
                duration= dist * Logic.kFastMultiplier
        }
        y_animation.duration = duration
        x_animation.duration = duration
        set_position(tx, ty)
    }

    function virtual_move_to(tx, ty, speed) {
        move_to(tx, ty + phys_virt_diff, speed)
    }

    function move_with_vector(v, speed) {
        move_to(pos_x + v.x, pos_y + v.y, speed)
    }

    function set_cell(r, c) {
        row = r
        column = c
    }

    function set_binding(direction, visible) {
        if (direction === Logic.kRight)
            right_binding.visible = visible
        else if (direction === Logic.kBottom)
            bottom_binding.visible = visible
    }

    function bind(direction, neighbor) {
        adjacent[direction] = neighbor
        set_binding(direction, true)
    }

    function unbind(direction, mutual) {
        var neighbor = adjacent[direction]
        if (typeof neighbor === 'undefined')
            return
        adjacent[direction] = undefined
        set_binding(direction, false)
        if (mutual)
            neighbor.unbind(Logic.reversedDirection[direction], false)
    }

    function unbind_all() {
        for (var dir = Logic.kTop; dir <= Logic.kBottom; ++dir)
            unbind(dir, true)
    }

    function set_to_destroy(callback) {
        destroy_callback = callback
        to_be_destroyed = true
        destroy_timer.start()
    }

    function make_smoke() {
        particle_system.start()
        smoke.pulse(body.smoke_life)
        smoke_timer.start()
    }

    function self_destroy() {
        if (!to_be_destroyed)
            return
        to_be_destroyed = false
        destroy_callback()
        root.destroy()
    }

    height: width
    color: "transparent"

    Rectangle {
        id: body
        x: 0
        y: 0
        width: parent.width - box_spacing
        height: body.width
        radius: body.width / 10
        antialiasing: true

        Label {
            id: label
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: height * 7 / 10
            font.bold: true
        }

        property int smoke_life: 300

        ParticleSystem {
            id: particle_system
            anchors.fill: parent
            running: false

            Turbulence {
                id: turb
                enabled: true
                anchors.fill: parent
                strength: 100
                NumberAnimation on strength {
                    from: 100
                    to: 32
                    easing.type: Easing.Linear
                    duration: body.smoke_life
                }
            }

            ImageParticle {
                groups: ["smoke"]
                source: "qrc:///img/particle-brick.png"
                colorVariation: 0.7
            }

            Emitter {
                id: smoke
                group: "smoke"
                enabled: false
                x: body.width * 0.5
                y: body.height * 0.8

                emitRate: 200
                lifeSpan: body.smoke_life / 2
                size: 32
                endSize: -1
                sizeVariation: 8
                acceleration: PointDirection { y: 180 }
                velocity: AngleDirection {
                    angle: 270
                    magnitude: 120
                    angleVariation: 15
                    magnitudeVariation: 5
                }
            }

            Timer {
                id: smoke_timer
                interval: body.smoke_life
                running: false
                onTriggered: {
                    particle_system.pause()
                    particle_system.reset()
                    particle_system.stop()
                }
            }
        }
    }

    Rectangle {
        id: right_binding
        visible: false
        width: box_spacing
        height: (parent.width - box_spacing) / 2
        x: parent.width - box_spacing
        y: (parent.width - box_spacing) / 4
        color: "black"
    }

    Rectangle {
        id: bottom_binding
        visible: false
        width: (parent.width - box_spacing) / 2
        height: box_spacing
        x: (parent.width - box_spacing) / 4
        y: parent.height - box_spacing
        color: "black"
    }

    Behavior on y {
        NumberAnimation {
            id: y_animation
            duration: 0
            easing.type: Easing.OutQuad
        }
    }
    Behavior on x {
        NumberAnimation {
            id: x_animation
            duration: 0
            easing.type: Easing.OutQuad
        }
    }

    Timer {
        id: destroy_timer
        interval: Logic.kGravityDelay
        running: false
        onTriggered: {
            if (!running)
                self_destroy()
        }
    }
}
