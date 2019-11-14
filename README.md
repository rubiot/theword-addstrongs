# theword-addstrongs
Command-line tool that copies strongs/morphology tags from one [theWord](http://www.theword.net) Bible module to another based on similar words.

Usage:

`./theword-addstrongs.p6 --file=<BibleModule> --borrow-from=<BibleModule> [--start-from=<Int>] [--debug] [--ibiblia=<Str>] [--max-levenshtein=<Int>] [--min-levenshtein=<Int>] [--synonyms-file=<Str>] [--strongs-association]`

* `--file` theWord Bible module you want to add strongs to
* `--borrow-from` [theWord](http://www.theword.net) Bible module you want to copy strongs from
* `--start-from`use this to start from a line other than the first one (for debug purposes)
* `--debug` print lots of debug information
* `--ibiblia` if provided, an [iBiblia](https://github.com/rubiot/ibiblia) project will be created with this name
* `--max-levenshtein` maximum [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) allowed to associate two different words. Defaults to 1. Increase it if you want to loose the association rules.
* `--min-levenshtein` minimum size for a word to apply Levenstein distance association. Defaults to 3.
* `--strongs-association` do association based on Strong's tags, instead of testing the words. Useful to generate iBiblia projects.
