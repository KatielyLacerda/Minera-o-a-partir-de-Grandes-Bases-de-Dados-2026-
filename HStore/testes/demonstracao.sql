-- comando de execução: psql -X -d alunos80k -f testes/demonstracao.sql
\set ON_ERROR_STOP on
BEGIN;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE TEMP TABLE Alunos (NUSP numeric(8), Nome text);
CREATE TEMP TABLE Configura (NUSP numeric(8), Nome text, Config hstore, Destaques hstore);
CREATE TEMP TABLE Matriculas (NUSP numeric(8), CodDisc text, NF numeric, Frequencia numeric);
INSERT INTO Alunos VALUES
 (1,'Ana'),(2,'Bruno'),(3,'Carla'),(4,'Davi'),(5,'Eva'),(6,'Fábio');
INSERT INTO Configura VALUES
 (1,'Ana',hstore('Font','Arial'),hstore('Extra','preservar')),
 (4,'Davi',NULL,NULL),(5,'Eva',NULL,NULL);
INSERT INTO Matriculas VALUES
 (1,'D1',9,100),(1,'D2',8,100),(1,'D3',0.5,0),(1,'D4',0,0),
 (2,'D1',10,100),
 (3,'D1',8,100),(3,'D2',8,100),
 (4,'D1',7.99,100),(4,'D2',5,100),(4,'D3',0.51,0),(4,'D4',0.5,1),
 (5,'D1',9,100),(5,'D1',9,100),
 (6,'D1',0,0);
\ir ../sql/01_origem.sql
\ir ../sql/02_resolucao.sql
-- Reexecução: não deve duplicar linhas nem perder chaves.
\ir ../sql/02_resolucao.sql
DO $$
BEGIN
 IF (SELECT count(*) FROM Configura) <> 6 THEN
   RAISE EXCEPTION 'Falha em inserção ou reexecução'; END IF;
 IF NOT EXISTS (SELECT 1 FROM Configura WHERE NUSP=1
    AND (Destaques->'Distinção')::numeric=9
    AND Destaques->'Bom'='2' AND Destaques->'Trancamento'='D3, D4'
    AND Destaques->'Extra'='preservar' AND Config->'Font'='Arial') THEN
   RAISE EXCEPTION 'Falha em coexistência, valores ou preservação'; END IF;
 IF NOT EXISTS (SELECT 1 FROM Configura WHERE NUSP=2 AND Nome='Bruno'
    AND (Destaques->'Distinção')::numeric=10 AND NOT Destaques ? 'Bom') THEN
   RAISE EXCEPTION 'Falha em Distinção/INSERT com Nome'; END IF;
 IF NOT EXISTS (SELECT 1 FROM Configura WHERE NUSP=3 AND Destaques->'Bom'='2'
    AND NOT Destaques ? 'Distinção') THEN
   RAISE EXCEPTION 'Falha no limite NF=8'; END IF;
 IF NOT EXISTS (SELECT 1 FROM Configura WHERE NUSP=4 AND Destaques IS NULL) THEN
   RAISE EXCEPTION 'Destaque indevido nos limites'; END IF;
 IF NOT EXISTS (SELECT 1 FROM Configura WHERE NUSP=5
    AND Destaques ? 'Distinção' AND NOT Destaques ? 'Bom') THEN
   RAISE EXCEPTION 'Contagem repetida da mesma disciplina'; END IF;
 IF NOT EXISTS (SELECT 1 FROM Configura WHERE NUSP=6 AND Nome='Fábio'
    AND Destaques->'Trancamento'='D1') THEN
   RAISE EXCEPTION 'Falha de INSERT para Trancamento'; END IF;
 RAISE NOTICE 'Todos os testes passaram.';
END $$;
\ir ../sql/03_conferir.sql
ROLLBACK;
