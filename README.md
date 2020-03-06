# theword-addstrongs
Command-line tool to copy strongs/morphology tags from one [theWord](http://www.theword.net) Bible module to another based on similar words.

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

## Module dependencies
The following [Raku](https://raku.org/) modules are necessary to run the script:
* Terminal::ANSIColor;
* Text::Levenshtein;
* DBIish.

## Known issues/limitations
* Bible modules must be in UTF-8 format;
* There can be no puctuation between a word and its Strong's/morphology tags. Move them to after the tags;
* Verse rules are not taken into account. If this is a problem, then apply them manually before running the script;
