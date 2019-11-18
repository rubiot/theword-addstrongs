#! /usr/bin/env perl6

use MONKEY-TYPING;

use lib './lib';
use Terminal::ANSIColor;
use Biblia::TheWord::Verse;
use Biblia::TheWord::Refs;
use Biblia::iBiblia;
use Text::Levenshtein;
use Data::Dump;

subset File of Str where { .IO.f // die "file '{.Str}' not found in dir '$*CWD'" };
subset BibleModule of File where { .Str ~~ / '.' ['ont'|'nt'|'ot'] $ / }

our %synonyms;

augment class Str {
  method normalize {
    self.lc.subst(/<[᾿]>/, '', :g).comb.map({.NFD[0].chr}).join
  }
  method synonym-of(Str $other) {
    (%synonyms{self}{$other}:exists) || (%synonyms{$other}{self}:exists);
  }
  method strip-tags {
    my token tag {
      [
        || '<TS' <-[>]>* '>' .*? '<Ts>'
        || '<RF' <-[>]>* '>' .*? '<Rf>'
        || '<' <-[>]>* '>'
      ]
    }
    self.subst(/<tag>/, '', :g);
  }
}

our &inbold   := &colored.assuming(*, 'bold');
our &inyellow := &colored.assuming(*, 'yellow');
our &inred    := &colored.assuming(*, 'red');
our &ingreen  := &colored.assuming(*, 'green');
our &inwhite  := &colored.assuming(*, 'white');

our %opts;
our $ibiblia-project;
our $ibiblia-pairs = '';

sub MAIN(
  BibleModule:D :$file!,       # Path to the module you want to add Strongs to
  BibleModule:D :$borrow-from!,# Path to the module you want to borrow Strongs from
  Int  :$start-from = 1,       # Skip to this line, useful in debug mode
  Bool :$debug = False,        # Enable debug mode
  Str  :$ibiblia,              # Generate an iBiblia association project
  Int  :$max-levenshtein = 1,  # Maximum Levenshtein allowed
  Int  :$min-levenshtein = 3,  # Minimum word size to apply Levenshtein
  Str  :$synonyms-file,        # Synonyms file
  Bool :$strongs-association = False # Do associations based on Strong's tags
 )
{
  %opts<dst-module>          = $file;
  %opts<src-module>          = $borrow-from;
  %opts<start-line>          = $start-from;
  %opts<debug>               = $debug;
  %opts<no-tags>             = False;
  %opts<ibiblia>             = $ibiblia;
  %opts<max-levenshtein>     = $max-levenshtein;
  %opts<min-levenshtein>     = $min-levenshtein;
  %opts<synonyms-file>       = $synonyms-file;
  %opts<strongs-association> = $strongs-association;
  %opts<src-range>           = get-file-range(%opts<src-module>);
  %opts<dst-range>           = get-file-range(%opts<dst-module>);

  fail "incompatible ranges" if (%opts<src-range> == OT && %opts<dst-range> == NT) ||
                                (%opts<dst-range> == OT && %opts<src-range> == NT);

  load-synonyms() with %opts<synonyms-file>;
  add-strongs();
}

sub add-strongs()
{
  our $idx = Biblia::TheWord::Index.new( :lang(en_us), :range(get-common-range()) );

  my Int @lines     = 1..$idx.max;
  my Int @src-lines = %opts<src-module>.IO.lines[|get-src-range()];
  my Int @dst-lines = %opts<dst-module>.IO.lines[|get-dst-range()];

  $ibiblia-project = Biblia::iBiblia::ProjectWriter.new(:file(%opts<ibiblia>), :range($idx.range)) if %opts<ibiblia>;

  my ($line, $dst-line, $src-line) = @lines.shift, @dst-lines.shift, @src-lines.shift;
  my ($p1, $p2) = parse-line($line, $dst-line, $src-line);

  for @lines Z @dst-lines Z @src-lines -> [$line, $dst-line, $src-line] {
    NEXT { $idx.next; $ibiblia-pairs = ""; }

    next if $line < %opts<start-line>;

    say-debug inbold("line {$idx.line()}, {$idx.ref()}...");
    say-debug inbold("  dst: ") ~ ingreen($dst-line.strip-tags);
    say-debug inbold("  src: ") ~ ingreen($src-line.strip-tags);

    my ($parse_sem_strongs, $parse_com_strongs) = await $p1, $p2;
    ($p1, $p2) = parse-line(@lines.shift, @dst-lines.shift, @src-lines.shift);

    #say $parse_com_strongs.made;
    #say $parse_sem_strongs.made;

    associate-verse(
      $parse_sem_strongs.made,
      $parse_com_strongs.made.grep(Biblia::TheWord::Syntagm)
    );

    $ibiblia-project.insert(
      $line,
      Biblia::iBiblia::Pair.new(
        :src-text($src-line),
        :dst-text($dst-line),
        :pairs($ibiblia-pairs)
      )
    ) if %opts<ibiblia>;
  }
}

# Returns two promises, one for the parsing result of each verse
sub parse-verse(Int $line, Str $src-line, Str $dst-line)
{
    my $p1 = start Biblia::TheWord::Verse.parse(
      $dst-line,
      :actions(Biblia::TheWord::Verse::Actions.new)
    ) or die inred(">>> %opts<module> - couldn't parse verse on line $line:\n"), $dst-line;
    my $p2 = start Biblia::TheWord::Verse.parse(
      $src-line,
      :actions(Biblia::TheWord::Verse::Actions.new)
    ) or die inred(">>> %opts<src-module> - couldn't parse verse on line $line:\n") ~ $src-line;

    ($p1, $p2)
}

sub print-debug(Str $s)
{
  print $s if %opts<debug>;
}

sub say-debug(Str $s)
{
  say $s if %opts<debug>;
}

sub same-string(Str $a, Str $b) #is cached
{
  $a.normalize eq $b.normalize
}

sub update-ibiblia-pairs(Biblia::TheWord::Syntagm:D $dst,
                         Biblia::TheWord::Syntagm $src?)
{
  #say-debug sprintf('<par a="%d" b="%d">', $src.order, $dst.order);
  $ibiblia-pairs ~= sprintf('<par a="%d" b="%d">', $src.order, $dst.order)
    if %opts<ibiblia> && $src && $src.tags;
}

sub format-syntagm(Biblia::TheWord::Syntagm:D $dst,
                   Biblia::TheWord::Syntagm $src?,
                   :$color = 'default')
{
  my Str $elem;

  #$elem  = "<wt>" if $src && !%opts<no-tags>;
  $elem ~= $src.pre-tags if $src && !%opts<not-tags>;
  $elem ~= colored($dst.word, $src ?? $color !! 'red');
  $elem ~= $src.tags.join if $src && !%opts<no-tags>;
  $elem ~= '<?>' if $color eq 'yellow' && !%opts<no-tags>;

  update-ibiblia-pairs($dst, $src);

  $elem
}

sub print-verse(Str $line)
{
  say %opts<debug> ?? $line !! colorstrip($line);
  say-debug "";
}

sub associate-verse(@dst, @src is copy)
{
  my @phases = %opts<strongs-association> ?? (&strongs-association)
                                          !! (&exact-association, &levenshtein-association, &synonym-association);

  my Str @words[@dst.elems];
  my Str @unassociated;

  for @phases -> $phase {
    say-debug inbold("  trying {$phase.name}...");
    @unassociated = ();
    $phase(@words, @unassociated, @dst, @src);

    if %opts<debug> && (@src.elems || @unassociated.elems) {
      say "   left after {$phase.name}";
      say "     dst: " ~ inyellow(@unassociated.join(" "));
      say "     src: " ~ inyellow(@src.grep(Biblia::TheWord::Syntagm).map({.word}).join(" "));
    }

    last unless @src.elems && any(@words».chars) == 0;
  }

  # handling non-associated words
  for @words.keys -> $w {
    @words[$w] = format-syntagm(@dst[$w])
      if @words[$w].chars == 0;
  }

  print-verse @words.join
}

sub exact-association(@words, Str @unassociated, @dst, @src)
{
  WORD: for @dst.keys -> $id {
    my $d := @dst[$id];

    if $d ~~ Biblia::TheWord::Syntagm {
      for @src.keys -> $is {
        my $s := @src[$is];
        next unless $s ~~ Biblia::TheWord::Syntagm;
        if same-string($s.word, $d.word) {
          @words[$id] = format-syntagm($d, $s);
          @src.splice($is, 1);
          next WORD;
        }
      }
      @words[$id] = '';
      @unassociated.push($d.word);
    } else {
      @words[$id] = $d.text
    }
  }
}

sub strongs-association(@words, Str @unassociated, @dst, @src)
{
  WORD: for @dst.keys -> $id {
    my $d := @dst[$id];

    if $d ~~ Biblia::TheWord::Syntagm && $d.tags.elems {
      for @src.keys -> $is {
        my $s := @src[$is];
        next unless $s ~~ Biblia::TheWord::Syntagm && $s.tags.elems;
        if $d.share-strongs-with($s) {
          say-debug inyellow("      {$d.word} --> {$s.word}");
          @words[$id] = format-syntagm($d, $s);
          @src.splice($is, 1);
          next WORD;
        }
      }
      @words[$id] = '';
      @unassociated.push($d.word);
    } else {
      @words[$id] = $d.text;
    }
  }
}

sub levenshtein-association(@words, Str @unassociated, @dst, @src)
{
  WORD: for @words.keys -> $w {
    next if @words[$w].chars; # already associated?

    my $d := @dst[$w];
    if $d.word.chars > %opts<min-levenshtein> {
      my @distance = distance($d.word.normalize, @src».word».normalize);
      for @distance.keys -> $k {
        if @distance[$k] == %opts<max-levenshtein> {
          say-debug inyellow("      {$d.word} --> {@src[$k].word}");
          #say-debug inyellow(@src[$k].word);
          @words[$w] = format-syntagm($d, @src[$k], :color('yellow'));
          @src.splice($k, 1);
          last unless @src.elems;
          next WORD;
        }
      }
      last unless @src.elems;
      #say-debug inyellow("???");
    }
    @unassociated.push($d.word);
  }
}

sub synonym-association(@words, Str @unassociated, @dst, @src)
{
  return unless %opts<synonyms-file>;

  WORD: for @words.keys -> $w {
    next if @words[$w].chars; # already associated?

    my $d := @dst[$w];
    for @src.keys -> $is {
      my $s := @src[$is];
      next unless $s ~~ Biblia::TheWord::Syntagm;
      if $s.word.synonym-of($d.word) {
        say-debug inyellow("      {$d.word} --> {$s.word}");
        @words[$w] = format-syntagm($d, $s);
        @src.splice($is, 1);
        next WORD;
      }
    }
    @unassociated.push($d.word);
  }
}

sub interactive-association(@words, Str @unassociated, @dst, @src)
{
  WORD: for @words.keys -> $w {
    next if @words[$w].chars;

    my $d := @dst[$w];
    for @src.keys -> $is {
      my $s := @src[$is];
      next unless $s ~~ Biblia::TheWord::Syntagm;
      # TODO ###############################
    }
    @unassociated.push($d.word);
  }
}

sub load-synonyms()
{
  # TODO load %synonyms from a file

  #%synonyms<expansão><firmamento>++;
  #%synonyms<erva><relva>++;
  #%synonyms<luminares><luzeiros>++;
}

sub get-file-range(Str $module) returns BibleRange
{
  return OT  if $module.ends-with('.ot');
  return NT  if $module.ends-with('.nt');
  return ONT if $module.ends-with('.ont');
  fail "unknown range: $module"
}

sub get-src-range()
{
  my %range;

  %range{OT  ~ ONT} = ^23145;
  %range{OT  ~ OT } = ^23145;
  %range{ONT ~ ONT} = ^31102;
  %range{ONT ~ OT } = ^23145;
  %range{ONT ~ NT } = 23145..31101;
  %range{NT  ~ NT } = ^7957;
  %range{NT  ~ ONT} = ^7957;

  %range{%opts<src-range> ~ %opts<dst-range>} // fail "unhandled range combination";
}

sub get-dst-range()
{
  my %range;

  %range{OT  ~ ONT} = ^23145;
  %range{OT  ~ OT } = ^23145;
  %range{ONT ~ ONT} = ^31102;
  %range{ONT ~ OT } = ^23145;
  %range{ONT ~ NT } = ^7957;
  %range{NT  ~ NT } = ^7957;
  %range{NT  ~ ONT} = 23145..31101;

  %range{%opts<src-range> ~ %opts<dst-range>} // fail "unhandled range combination";
}

sub get-common-range() returns BibleRange
{
  my %range;

  %range{OT  ~ ONT} = OT;
  %range{OT  ~ OT } = OT;
  %range{ONT ~ ONT} = ONT;
  %range{ONT ~ OT } = OT;
  %range{ONT ~ NT } = NT;
  %range{NT  ~ NT } = NT;
  %range{NT  ~ ONT} = NT;

  %range{%opts<src-range> ~ %opts<dst-range>} // fail "unhandled range combination";
}
