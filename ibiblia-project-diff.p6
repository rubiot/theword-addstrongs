#!/usr/bin/env perl6
use lib './lib';
use Terminal::ANSIColor;
use Biblia::iBiblia;

our &inbold   := &colored.assuming(*, 'bold');
our &inyellow := &colored.assuming(*, 'yellow');
our &inred    := &colored.assuming(*, 'red');
our &ingreen  := &colored.assuming(*, 'green');
our &inwhite  := &colored.assuming(*, 'white');

subset File of Str where { .IO.f // die "file '{.Str}' not found" };
subset BibFile of File where { .Str ~~ / '.bib' $ / };

sub MAIN(BibFile:D :$first!, BibFile:D :$second!) {
    my $p1 = Biblia::iBiblia::ProjectReader.new(:file($first));
    my $p2 = Biblia::iBiblia::ProjectReader.new(:file($second));

    say "comparing {$p1.info<descricao>} to {$p2.info<descricao>}...";
    for ^$p1.elems -> $i {
        compare-verse($p1[$i], $p2[$i])
    }
}

sub compare-verse(%left, %right) {
    my @diffs;

    for <pare_texto_origem pare_texto_destino pare_pares pare_comentarios> -> $field {
        compare-field(@diffs, $field, %left, %right)
    }

    if @diffs.elems {
        say inbold(%left<pare_ref>);
        @diffs>>.say
    }
}

sub compare-field(@diffs, $field, %left, %right) {
    push @diffs, inred("\t[$field]\n") ~ inyellow("\t\t%left{$field}\n") ~ ingreen("\t\t%right{$field}")
        if %left{$field} ne %right{$field};
}