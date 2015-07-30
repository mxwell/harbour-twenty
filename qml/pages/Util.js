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
