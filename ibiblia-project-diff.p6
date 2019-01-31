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
    loop {
        compare-verse($p1.read-next(), $p2.read-next());
        last if $p1.idx.line == $p1.idx.max;
    }
}

sub compare-verse(%left, %right) {
    my @diffs;

    compare-field(@diffs, 'pare_texto_origem', %left, %right);
    compare-field(@diffs, 'pare_texto_destino', %left, %right);
    compare-field(@diffs, 'pare_pares', %left, %right);
    compare-field(@diffs, 'pare_comentarios', %left, %right);

    if @diffs.elems {
        say inbold(%left<pare_ref>);
        @diffs>>.say
    }
}

sub compare-field(@diffs, $field, %left, %right) {
    push @diffs, inred("\t[$field]\n") ~ inyellow("\t\t%left{$field}\n") ~ ingreen("\t\t%right{$field}")
        if %left{$field} ne %right{$field};
}