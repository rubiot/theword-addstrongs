use v6.c;
use Test;      # a Standard module included with Rakudo
use lib './lib';
use Biblia::TheWord::Verse;

use-ok 'Biblia::TheWord::Verse';
ok Biblia::TheWord::Verse.parse('<wt>bla ble<WG1>', :rule('syntagm')) ~~ Biblia::TheWord::Verse;
ok Biblia::TheWord::Verse.parse('<wt>bli<WG1>', :rule('syntagm')) ~~ Biblia::TheWord::Verse;
ok Biblia::TheWord::Verse.parse('blo<WG1>', :rule('syntagm')) ~~ Biblia::TheWord::Verse;

say Biblia::TheWord::Verse.parse('<wt>adorá<WG4352><WTV-AAN l="προσκυνέω"><wt>-lo<WG846><WTP-DSM l="αὐτός"> <wt>respeito<WG4012s><WTPREP l="περί">, E <wt>tomar<WG142><WTV-FAI-3P l="αἴρω">-te<wt>-ão<WG142s><WTV-FAI-3P l="αἴρω">',
      :actions(Biblia::TheWord::Verse::Actions.new)
  );

say $/.made;

ok Biblia::TheWord::Verse.parse('<TS>my title<Ts>', :rule('title')) ~~ Biblia::TheWord::Verse;
ok Biblia::TheWord::Verse.parse('<TS7>my title<Ts>', :rule('title')) ~~ Biblia::TheWord::Verse;
ok Biblia::TheWord::Verse.parse('<wt>bla ble<WG1>', :rule('syntagm')) ~~ Biblia::TheWord::Verse;
ok Biblia::TheWord::Verse.parse('<wt>bli<WG1>', :rule('syntagm')) ~~ Biblia::TheWord::Verse;
ok Biblia::TheWord::Verse.parse('blo<WG1>', :rule('syntagm')) ~~ Biblia::TheWord::Verse;

#say Biblia::TheWord::Verse.parse('<RF q="x">', :rule('begin-note')).made;
#say Biblia::TheWord::Verse.parse('<RF>my note<Rf>', :rule('note')).made;
#ok Biblia::TheWord::Verse.parse('<RF>my note<Rf>', :rule('note')) ~~ Biblia::TheWord::Verse;

done-testing;
