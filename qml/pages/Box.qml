import QtQuick 2.1
import Sailfish.Silica 1.0

Rectangle {
    property int digit
    property string body_color
    property string text_color
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
    // of the neighbor is specified by GameArea's adjacent_dr and adjacent_dc
    property var adjacent: [false, false, false, false]
    // saved from GameArea
    property int box_spacing

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

    function set_binding(direction, is_visible) {
        if (direction === 2)
            right_binding.visible = is_visible
        else if (direction === 3)
            bottom_binding.visible = is_visible
        adjacent[direction] = is_visible
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
        color: body_color

        Label {
            id: label
            text: String(digit)
            anchors.fill: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: height * 7 / 10
            font.bold: true
            color: text_color
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
