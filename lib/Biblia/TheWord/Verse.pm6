use v6;
unit module Biblia::TheWord;

#use Grammar::Tracer;
#use Grammar::Debugger;

class Elem
{
  has Str $.text is required;
  has Int $.order is rw;

  method gist() {
    say "#$.order, text: [$.text]";
  }
}

class Syntagm is Elem
{
  has Str $.pre-tags;
  has Str $.word is required;
  has Str @.tags;

  method gist() {
    say "#$.order, text: [$.text], word: [$.word], pre-tags: $.pre-tags, tags: {@.tags.join}";
  }
  method share-strongs-with(Syntagm $other) {
    for @!tags.grep(/^ '<W' <[GH]> /) -> $ours {
      for $other.tags.grep(/^ '<W' <[GH]> /) -> $theirs {
        #say "share-strongs-with: $ours <=> $theirs";
        return True if $ours eq $theirs
      }
    }
    False
  }
}

class Verse::Actions
{
  has Int $.order = 0;

  method TOP($/) {
    make @<elem>».made
  }
  method syntagm($/)
  {
    make Syntagm.new(
            :text(~$/),
            :word($<word>.made),
            :tags(@<tag>».made),
            :pre-tags($<wt>.made // "")
    );
    #say $/.made;
  }
  method punctuation($/){ make Elem.new( :text(~$/) ) }
  method blank($/)      { make Elem.new( :text(~$/) ) }
  method note($/)       { make Elem.new( :text(~$/) ) }
  method title($/)      { make Elem.new( :text(~$/) ) }

  method other-tag($/)  { make Elem.new( :text(~$/) ) }

  method word($/)       { make ~$/ }
  method wt($/)         { $!order++; make ~$/ }
  method tag($/)        { make $<strong-tag>.made // $<morpho-tag>.made }
  method morpho-tag($/) { make ~$/ }
  method strong-tag($/) { make ~$/ }

  method elem($/) {
    my $e = $<syntagm>.made     //
            $<punctuation>.made //
            $<blank>.made       //
            $<note>.made        //
            $<title>.made       //
            $<other-tag>.made;
    $e.order = $!order++;
    #say $e;
    make $e;
  }
}

grammar Verse {
  token TOP {
    <elem>*
  }

  token elem {
    | <syntagm>
    | <punctuation>
    | <blank>
    | <note>
    | <title>
    | <other-tag> # tags irrelevantes
  }

  token title {
    [ '<TS' [\d]? '>' ] ~ '<Ts>' \N+?
  }

  token note {
    <.begin-note> ~ '<Rf>' \N+?
  }

  token begin-note {
    '<RF' [ ' q' [uote]? '=' '"'? \w+ '"'? ]? '>'
  }

  token punctuation  {
    <+[.,:;!? \(\) \[\] \{\} ] +[\|\"\'´‘’·—\-\─「」«»=*]>+
  }

  token blank  {
    \h+
  }

  token other-tag
  {
    <!before <wt>> '<' ~ '>' \N+?
  }

  #  token formatacao {
  #    '<' ~ '>'
  #    [
  #      | < u /u i /i b /b s /s sup /sup sub /sub rtl /rtl ltr /ltr br p NB Nb
  #          FI Fi FR Fr FO Fo St CM CI CL /font /span >
  #      | 'font' .*?
  #      | 'span' .*?
  #      | 'PI' <[0..7]>
  #      | 'ST' .*?
  #    ]
  #  }

  token morpho-tag {
    '<WT' <.morfo> [ \h+ 'l="' <.lemma> '"' ]?  [ \h+ 'lh="' <.homonym> '"' ]? '>'
  }
  token syntagm    { <wt>? <word> <tag>*                }
  token tag        { <strong-tag>|<morpho-tag>          }
  token word       { '-'? [<:Letter>|<:Number>|<[᾿΄]>]+ }
  token wt         { '<wt>'                             }
  token strong-tag { '<W' <.strong> <[sx]>? '>'         }
  token strong     { <[HG]> \d+ [ '.' \d+ ]?            }
  token morfo      { <[a..z A..Z 0..9 -]>+              }
  token lemma      { <-[>"]>+                           }
  token homonym    { <.lemma>                           }
}


#my $line = '<wt>Livro<WG1> de';
#my $parse_sem_strongs = Biblia::TheWord::Verse.parse(
      #$line,
      #:actions(Biblia::TheWord::Verse::Actions.new)
#) or die "couldn't parse verse on line $line:\n";
#say $parse_sem_strongs;
#say $parse_sem_strongs.made;
