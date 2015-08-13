
/* How to find adjacent boxes */
var adjacent_dr = [-1, 0, 0, 1]
var adjacent_dc = [0, -1, 1, 0]

var kTop = 0
var kLeft = 1
var kRight = 2
var kBottom = 3

var reversedDirection = [kBottom, kRight, kLeft, kTop]

/*** Colors *** /
                  /*   1     |    2     |   3      |    4     |   5      |    6     |    7     |    8     |    9     |    10   |   11     |    12     |   13     |   14     |   15     |    16    |    17    |    18    |   19     |   20     */
var body_colors = ["#ffff9c", "#ff2421", "#00f3ad", "#298aff", "#dea6ff", "#31eb00", "#ffd2bd", "#9c00f7", "#ffb600", "#c5c2c5", "#cefb00", "#ffff00", "#ff187b", "#00d7ef", "#808080", "#2424ff", "#f340ff", "#ffb2b2", "#ffe5a5", "#fe8242" ]
var text_colors = ["#8b8e00", "#ffffff", "#ffffff", "#ffffff", "#ffffff", "#ffffff", "#ff5500", "#ffffff", "#ffffff", "white",   "#6b7d00", "#7b7900", "white",   "white",   "white",   "white",   "white",   "white",   "#d09400", "white" ]

var kMaxBoxNumber = 20

var kFastMultiplier = 2
var kSlowMultiplier = 3

var kGameStateNo        = 0
var kGameStateCreated   = 1
var kGameStateStarted   = 2
var kGameStatePaused    = 3
