import QtQuick 2.1
import Sailfish.Silica 1.0
import "./Logic.js" as Logic

Rectangle {
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

    function set_digit(d) {
        digit = d
        label.text = String(d)
        body.color = Logic.body_colors[(d - 1) % Logic.body_colors.length]
        label.color = Logic.text_colors[(d - 1) % Logic.text_colors.length]
    }

    function evolve() {
        set_digit(digit + 1)
    }

    function move_to(tx, ty) {
        pos_x = tx
        pos_y = ty
        x = pos_x
        y = pos_y
    }

    function move_with_vector(v) {
        pos_x += v.x
        pos_y += v.y
        x = pos_x
        y = pos_y
    }

    function set_y(ty) {
        pos_y = ty
        y = pos_y
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

    Behavior on y { NumberAnimation { duration: 50; easing.type: Easing.Linear } }
    Behavior on x { NumberAnimation { duration: 50; easing.type: Easing.Linear } }
}
