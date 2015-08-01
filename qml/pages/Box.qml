import QtQuick 2.1
import QtQuick.Particles 2.0
import Sailfish.Silica 1.0
import "./Logic.js" as Logic

Rectangle {
    id: root
    property int digit
    // user-faced X coordinate of the topleft corner
    property double pos_x
    // user-faced Y coordinate of the topleft corner
    property double pos_y
    // row of the occupied cell in the grid
    property int row
    // column of the occupied cell in the grid
    property int column
    // flag for box not bound to the grid
    property bool floating: false
    // bindings to adjacent boxes: relative position
    // of the neighbor is specified by Logic.adjacent_dr and Logic.adjacent_dc
    property var adjacent: [undefined, undefined, undefined, undefined]
    // saved from GameArea
    property int box_spacing
    property var saved_neighbor
    property bool to_be_destroyed: false
    property var destroy_callback

    function set_digit(d) {
        digit = d
        label.text = String(d)
        body.color = Logic.body_colors[(d - 1) % Logic.body_colors.length]
        label.color = Logic.text_colors[(d - 1) % Logic.text_colors.length]
    }

    function evolve() {
        make_smoke()
        set_digit(digit + 1)
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
                duration = dist * 2.5
            else
                duration = dist * 1.5
        }
        y_animation.duration = duration
        x_animation.duration = duration
        set_position(tx, ty)
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
        if (!y_animation.running && !smoke_timer.running)
            self_destroy()
        else
            to_be_destroyed = true
    }

    function make_smoke() {
        smoke.enabled = true
        smoke_timer.start()
    }

    function self_destroy() {
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

        property int smoke_life: 250

        ParticleSystem {
            anchors.fill: parent

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
                //color: "#11111111"
                colorVariation: 0.7
            }

            Emitter {
                id: smoke
                group: "smoke"
                enabled: false
                x: body.width / 2
                y: body.height

                emitRate: 200
                lifeSpan: body.smoke_life
                lifeSpanVariation: 50
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
                    smoke.enabled = false
                    if (root.to_be_destroyed)
                        self_destroy()
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
            duration: 100
            easing.type: Easing.OutQuad

            onRunningChanged: {
                if (!running && root.to_be_destroyed)
                    self_destroy()
            }
        }
    }
    Behavior on x {
        NumberAnimation {
            id: x_animation
            duration: 100
            easing.type: Easing.OutQuad
        }
    }
}
