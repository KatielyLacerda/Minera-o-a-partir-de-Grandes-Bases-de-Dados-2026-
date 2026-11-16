-- Arquivo para psql. Os comandos com barra invertida são do psql.
\set ON_ERROR_STOP on
BEGIN;
\ir sql/01_origem.sql
\ir sql/02_resolucao.sql
COMMIT;
\ir sql/03_conferir.sql
