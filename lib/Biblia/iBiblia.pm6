use v6;
unit module Biblia::iBiblia;
use DBIish;
use Biblia::TheWord::Refs;

constant @statements =
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
  has Str $!file;
  has $!dbh;
  has Biblia::TheWord::Index $!idx;
  has BibleRange $!range;
  has $!insert-sth;
  has $!insert-info;

  submethod BUILD(:$!file, :$!range) {
    $!idx = Biblia::TheWord::Index.new( :lang(pt_br), :range($!range) );
    $!dbh = DBIish.connect("SQLite", :database($!file));

    for @statements -> $s {
      $!dbh.do($s);
    }

    $!insert-sth  = $!dbh.prepare('INSERT INTO pares VALUES (?,?,?,?,?,?,?,?,?)');
    $!insert-info = $!dbh.prepare('INSERT INTO info  VALUES (?,?)');

    #self.add-info('descricao', 'addstrong-auto-generated-project');
  }

  submethod DESTROY() {
    $!insert-sth.finish;
    $!dbh.dispose;
  }

  method add-info(Str:D $key, Str:D $value) {
    $!insert-info($key, $value);
  }

  method insert(Int:D $line, Pair:D $pair) {
    $!idx.goto($line);
    $!insert-sth.execute(
      sprintf("%d,%d,%d", $!idx.bookId, $!idx.chapter, $!idx.verse),
      $!idx.ref,
      $pair.src-text,
      $pair.dst-text,
      "", # consulta 1
      "", # consulta 2
      $pair.pairs,
      0,  # pare_situacao
      ""  # pare_comentarios
    );
  }
}
