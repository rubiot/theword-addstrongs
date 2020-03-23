use v6;
unit module Biblia::TheWord;

#use Grammar::Tracer;
#use Grammar::Debugger;

class Elem
{
  has Str $.text is required;
  has Int $.order is required is rw;

  method Str() {
    "Elem: #$.order, text: [$.text]"
  }
}

class Word is Elem
{
  # a word is nothing special here, but it is in iBiblia, because it is the element that can be associated
  method Str() {
    "Word: #$.order, text: [$.text]"
  }
}

class Syntagm is Elem
{
  has Str $.pre-tags;
  has Elem @.words is required;
  has Str @.tags;

  method Str() {
    #"Syntagm: #$.order, text: [$.text], words: [{@.words».text.join}], pre-tags: [$.pre-tags], tags: [{@.tags.join}]\n"
    "Syntagm: #$.order, text: [$.text], words: [{@.words».Str.join(',')}], pre-tags: [$.pre-tags], tags: [{@.tags.join}]"
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
  method get-words() {
    @!words>>.text.join
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
            :order(-1), # order doesn't matter because it doesn't count as a word in iBiblia
            :text(~$/),
            :words($<words>.made // $<word>.made),
            :tags(@<tag>».made),
            :pre-tags($<wt>.made // "")
    );
    #say $/.made;
  }
  method punctuation($/){ make Elem.new( :text(~$/), :order($!order++) ) }
  method blank($/)      { make Elem.new( :text(~$/), :order($!order++) ) }
  method note($/)       { make Elem.new( :text(~$/), :order($!order++) ) }
  method title($/)      { make Elem.new( :text(~$/), :order($!order++) ) }
  method other-tag($/)  { make Elem.new( :text(~$/), :order($!order++) ) }
  method wt($/)         { $!order++; make ~$/ }
  method tag($/)        { make $<strong-tag>.made // $<morpho-tag>.made }
  method morpho-tag($/) { make ~$/ }
  method strong-tag($/) { make ~$/ }
  method word($/) {
    make Word.new: :text(~$/), :order($!order++);
    #say $/.made;
  }
  method words($/) {
    my Elem @elems;
    for roundrobin @<word>, @<blank> -> @p {
      @elems.push: |@p».made
    }
    #say @elems.perl; exit;
    make @elems
  }
  method elem($/) {
    my $e = $<syntagm>.made     //
            $<punctuation>.made //
            $<blank>.made       //
            $<note>.made        //
            $<title>.made       //
            $<other-tag>.made;
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
    #<:Punctuation>+
    <[".,;:!?()··“”]>+
  }

  token blank  {
    #<:White_Space>+
    <[\ \t|]>+
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
  token syntagm    { <wt> <words> <tag>* | <word> <tag>* }
  token tag        { <strong-tag>|<morpho-tag>           }
  #token word       { '-'? [<:Letter>|<:Number>|<[᾿΄׃־׀]>]+}
  token word       { '-'? <-[-\ \t|<".,;:!?()··“”]>+ | '-' }
  token words      { <word>+ % <blank>                   }
  token wt         { '<wt>'                              }
  token strong-tag { '<W' <.strong> <[sx]>? '>'          }
  token strong     { <[HG]> \d+ [ '.' \d+ ]?             }
  token morfo      { <-[\h]>+                            }
  token lemma      { <-[>"]>+                            }
  token homonym    { <.lemma>                            }
}

if False {
  #           0   1    23      45           6
  my $line = '<v=1.14.20><wt>וּ<WH9000><WTconj l="וְ"><sup>and</sup> <wt>בָרוּךְ֙<WH1288><WTverb.qal.ptcp.u.m.sg.a l="ברך"><sup>blessed be</sup> <wt>אֵ֣ל<WH410><WTsubs.m.sg.a l="אֵל"><sup>God</sup> <wt>עֶלְיֹ֔ון<WH5945><WTadjv.m.sg.a l="עֶלְיֹון"><sup>Most High,</sup> <wt>אֲשֶׁר־<WH834><WTconj l="אֲשֶׁר"><sup>who</sup> <wt>מִגֵּ֥ן<WH4042><WTverb.piel.perf.p3.m.sg l="מגן"><sup>has delivered</sup> <wt>צָרֶ֖יךָ<WH6862><WTsubs.m.pl.a.prs.p2.m.sg l="צַר"><sup>your enemies</sup> <wt>בְּ<WH9003><WTprep l="בְּ"><sup>•</sup> <wt>יָדֶ֑ךָ<WH3027><WTsubs.u.sg.a.prs.p2.m.sg l="יָד"><sup>into your hand.”</sup> <wt>וַ<WH9000><WTconj l="וְ"><sup>•</sup> <wt>יִּתֶּן־<WH5414><WTverb.qal.wayq.p3.m.sg l="נתן"><sup>Then Abram gave</sup> <wt>לֹ֥ו<WH9005><WTprep.prs.p3.m.sg l="לְ"><sup>•</sup> <wt>מַעֲשֵׂ֖ר<WH4643><WTsubs.m.sg.a l="מַעֲשֵׂר"><sup><FI>Melchizedek<Fi> a tenth</sup> <wt>מִ<WH4480><WTprep l="מִן"><sup>•</sup> <wt>כֹּֽל׃<WH3605><WTsubs.m.sg.a l="כֹּל"><sup>of everything.</sup>';
  my $parse_sem_strongs = Biblia::TheWord::Verse.parse(
          $line,
          :actions(Biblia::TheWord::Verse::Actions.new)
          ) or die "couldn't parse verse on line $line:\n";
  #say $parse_sem_strongs;
  say $parse_sem_strongs.made.map({.Str ~ "\n"});

  #my @x = [
  #  Biblia::TheWord::Syntagm.new(
  #          pre-tags => "<wt>",
  #          words => Array[Biblia::TheWord::Elem].new(
  #                  Biblia::TheWord::Elem.new(text => "Livro", order => 1),
  #                  Biblia::TheWord::Elem.new(text => " ", order => 2),
  #                  Biblia::TheWord::Elem.new(text => "de", order => 3)
  #          ),
  #          tags => Array[Str].new("<WG1>"),
  #          text => "<wt>Livro de<WG1>",
  #          order => -1),
  #  Biblia::TheWord::Elem.new(
  #          text => " ",
  #          order => 4),
  #  Biblia::TheWord::Syntagm.new(
  #          pre-tags => "",
  #          words => Array[Biblia::TheWord::Elem].new(
  #                  Biblia::TheWord::Elem.new(text => "geração", order => 5)
  #          ),
  #          tags => Array[Str].new("<WG2>"),
  #          text => "geração<WG2>",
  #          order => -1),
  #  Biblia::TheWord::Elem.new(
  #          text => ".",
  #          order => 6)
  #]
}