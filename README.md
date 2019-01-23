# theword-addstrongs
Tool to copy strongs from one theWord Bible module to another.

Usage:

`./theword-addstrongs.p6 --file=<BibleModule> --borrow-from=<BibleModule> [--start-from=<Int>] [--debug] [--ibiblia=<Str>]`

* `--file`        theWord Bible module you want to add strongs to
* `--borrow-from` theWord Bible module you want to copy strongs from
* `--start-from`  use this to start from a line other than the first one (for debug purposes)
* `--debug`       print lots of debug information
* `--ibiblia`     if provided, an iBiblia project will be created with this name
