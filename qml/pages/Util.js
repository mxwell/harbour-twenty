.pragma library

function condense_array(ar) {
    var j = 0;
    var n = ar.length;
    for (var i = 0; i < n; ++i) {
        if (typeof ar[i] !== 'undefined')
            ar[j++] = ar[i];
    }
    ar.splice(j, n - j);
}

function make_filled_array(n, filler) {
    var result = new Array(n);
    for (var i = 0; i < n; ++i)
        result[i] = filler;
    return result
}

function make_2d_array(rows, columns) {
    var result = new Array(rows);
    for (var i = 0; i < rows; ++i)
        result[i] = new Array(columns);
    return result;
}

function fill_2d_array(ar, value) {
    for (var i in ar)
        for (var j in ar[i])
            ar[i][j] = value;
}

function make_point(x, y) {
    return { x: x, y: y }
}

function point_sum(a, b) {
    return make_point(a.x + b.x, a.y + b.y)
}

function point_diff(a, b) {
    return make_point(a.x - b.x, a.y - b.y)
}

// @a and @b are squares with side=@size, represented by topleft points
function find_collision(a, b, size) {
    return a.x < b.x + size && a.x + size > b.x && a.y < b.y + size && a.y + size > b.y
}

function generate_number(right_bound, forbidden) {
    while (true) {
        var num = Math.min(Math.floor(1 + Math.random() * right_bound), 19)
        if (num !== forbidden) {
            return num
        }
    }
}

function queue_new() {
    return {
        front: 0,
        end: 0,
        items: new Array(128)
    };
}

function queue_push(q, item) {
    q.items[q.end] = item;
    q.end = (q.end + 1) % q.items.length;
    if (q.end === q.front) {
        console.log("ERROR: queue overflow");
       q.front = (q.front + 1) % q.items.length;
    }
}

function queue_pop(q) {
    if (q.front === q.end) {
        console.log("ERROR: queue underflow");
    }
    var result = q.items[q.front];
    q.front = (q.front + 1) % q.items.length;
    return result;
}

function queue_empty(q) {
    return q.front === q.end;
}

function make_task(name, body) {
    return {
        name: name,
        body: body
    };
}

function delay(duration) {
    var result = 0;
    for (var i = 0; i < duration; ++i)
        result += i * (duration - i + 1);
    return result;
}
