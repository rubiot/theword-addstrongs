use v6.c;
use Test;      # a Standard module included with Rakudo
use lib 'lib';
use Biblia::TheWord::Refs;

#plan $num-tests;

{
  my Biblia::TheWord::Index $idx .= new();
  is $idx.line, 1;
  is $idx.ref, 'Gn 1:1';
}

{
  my Biblia::TheWord::Index $idx .= new(:range(ONT));
  is $idx.line, 1;
  is $idx.ref, 'Gn 1:1';
  $idx.next;
  is $idx.ref, 'Gn 1:2';
  is $idx.line, 2;
  $idx.goto('Ap 22:21');
  is $idx.ref, 'Ap 22:21';
  is $idx.line, 31102;
  $idx.next;
  is $idx.ref, 'Ap 22:21';
  is $idx.line, 31102;
}

{
  my Biblia::TheWord::Index $idx .= new(:range(OT));
  is $idx.line, 1;
  is $idx.ref, 'Gn 1:1';
  $idx.next;
  is $idx.ref, 'Gn 1:2';
  $idx.goto('Ml 4:6');
  is $idx.ref, 'Ml 4:6';
  is $idx.line, 23145;
  $idx.next;
  is $idx.line, 23145;
}

{
  my Biblia::TheWord::Index $idx .= new(:range(NT));
  is $idx.line, 1;
  is $idx.ref, 'Mt 1:1';
  $idx.next;
  is $idx.ref, 'Mt 1:2';
  $idx.goto('Ap 22:21');
  is $idx.ref, 'Ap 22:21';
  is $idx.line, 7957;
  $idx.next;
  is $idx.line, 7957;
}

done-testing;  # optional with 'plan'
