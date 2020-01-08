use v6;
unit module Biblia::iBiblia;
use Biblia::TheWord::Refs;
use DBIish;

%*ENV<DBIISH_SQLITE_LIB> = "sqlite3.dll" if $*DISTRO.is-win;

constant @ddl-statements =
  "DROP TABLE IF EXISTS traducoes",
  "CREATE TABLE traducoes (
      trad_lori_id integer not null,
      trad_ldes_id integer not null,
      trad_ocorrencias integer
  )",
  "DROP TABLE IF EXISTS sintagmas_locucoes_origem",
  "CREATE TABLE sintagmas_locucoes_origem (
      slor_lori_id integer not null,
      slor_sori_id integer not null,
      slor_ordem integer not null
  )",
  "DROP TABLE IF EXISTS sintagmas_locucoes_destino",
  "CREATE TABLE sintagmas_locucoes_destino (
      slde_ldes_id integer not null,
      slde_sdes_id integer not null,
      slde_ordem integer not null
  )",
  "DROP TABLE IF EXISTS pares",
  "CREATE TABLE pares (
      pare_id text primary key,
      pare_ref text,
      pare_texto_origem text,
      pare_texto_destino text,
      pare_texto_consulta1 text,
      pare_texto_consulta2 text,
      pare_pares text,
      pare_situacao number,
      pare_comentarios text
  )",
  "DROP TABLE IF EXISTS locucoes_origem",
  "CREATE TABLE locucoes_origem (
      lori_id integer not null primary key,
      lori_qtde_sintagmas integer,
      lori_locucao varchar(200) unique
  )",
  "DROP TABLE IF EXISTS locucoes_destino",
  "CREATE TABLE locucoes_destino (
      ldes_id integer not null primary key,
      ldes_qtde_sintagmas integer,
      ldes_locucao varchar(200) unique
  )",
  "DROP TABLE IF EXISTS info",
  "CREATE TABLE info (
      id text primary key,
      valor text
  )",
  "CREATE UNIQUE INDEX trad_uk on traducoes(trad_lori_id, trad_ldes_id)",
  "CREATE UNIQUE INDEX slor_uk on sintagmas_locucoes_origem(slor_lori_id, slor_sori_id)",
  "CREATE UNIQUE INDEX slde_uk on sintagmas_locucoes_destino(slde_ldes_id, slde_sdes_id)",
  "CREATE INDEX 'lori_locucao_idx' ON locucoes_origem (lori_locucao)",
  "CREATE INDEX 'ldes_locucao_idx' ON locucoes_destino (ldes_locucao)",
;

class Pair
{
  has Str $.src-text;
  has Str $.dst-text;
  has Str $.pairs;
}

class Project
{
  has $.dbh;
  has Str $.file is required;
  has Biblia::TheWord::Index $.idx is rw;

  submethod BUILD(:$!file) {
    $!dbh = DBIish.connect("SQLite", :database($!file), :AutoCommit(False));
  }

  submethod DESTROY() {
    $!dbh.dispose;
  }

  method init-idx(BibleRange $range) {
    self.idx = Biblia::TheWord::Index.new( :lang(pt_br), :range($range) );
  }
}

class ProjectReader is Project does Positional
{
  has @!pairs;
  has %.info;

  submethod BUILD() {
    my $select-info = self.dbh.prepare('select * from info');
    $select-info.execute;
    for $select-info.allrows(:array-of-hash) -> %row {
      %!info{%row<id>} = %row<valor>;
    }

    my $select-pairs = self.dbh.prepare('SELECT * from pares');
    $select-pairs.execute;
    @!pairs = $select-pairs.allrows(:array-of-hash);
    $select-pairs.dispose;

    self.init-idx(@!pairs[0]<pare_id> = '1,1,1' ?? OT !! NT);
  }

  multi method elems() {
    self.idx.max
  }

  multi method AT-POS($index) {
    self.idx.goto($index + 1);
    my %result = @!pairs[self.idx.line - 1];
    %result<pare_pares>       //= '';
    %result<pare_comentarios> //= '';
    %result;
  }

  multi method EXISTS-POS($index) {
    0 <= $index <= self.idx.max
  }
}

class ProjectWriter is Project
{
  has $!insert-sth;
  has $!insert-info;

  submethod BUILD(:$range) {
    self.init-idx($range);

    for @ddl-statements -> $s {
      self.dbh.do($s);
    }

    $!insert-sth  = self.dbh.prepare('INSERT INTO pares VALUES (?,?,?,?,?,?,?,?,?)');
    $!insert-info = self.dbh.prepare('INSERT INTO info  VALUES (?,?)');
    #self.add-info('descricao', 'addstrong-auto-generated-project');
  }

  submethod DESTROY() {
    $!insert-sth.finish;
    self.dbh.commit;
  }

  method commit() {
    self.dbh.commit;
  }

  method rollback() {
    self.dbh.rollback;
  }

  method add-info(Str:D $key, Str:D $value) {
    $!insert-info($key, $value);
  }

  method insert(Int:D $line, Pair:D $pair) {
    self.idx.goto($line);
    $!insert-sth.execute(
      sprintf("%d,%d,%d", self.idx.bookId, self.idx.chapter, self.idx.verse),
      self.idx.ref,
      $pair.src-text,
      $pair.dst-text,
      "", # reference 1
      "", # reference 2
      $pair.pairs,
      0,  # status
      ""  # comments
    );
  }
}
