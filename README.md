# theword-addstrongs
Tool to copy strongs from one theWord Bible module to another.

`Usage:
    ./theword-addstrongs.p6 --file=<BibleModule> --borrow-from=<BibleModule> [--start-from=<Int>] [--debug] [--ibiblia=<Str>]`

* `--file`        theWord Bible module you want to add strongs to
* `--borrow-from` theWord Bible module you want to copy strongs from
* `--start-from`  provide this to skip the first lines from the Bible module (debug)
* `--debug`       print lots of debug information
* `--ibiblia`     if provided, creates an iBiblia project having the indicated filename
