\set ON_ERROR_STOP on
\set ScriptPath '/Users/katielylacerda/Downloads/HStore/base/Alunos80K/'

CREATE DATABASE alunos80k WITH OWNER = postgres ENCODING = 'UTF8';
\connect alunos80k
SELECT current_database(), Current_User;

\i :ScriptPath'Nomes_Carga.sql'
\i :ScriptPath'CreateInsertTab_Cidades.sql'
\i :ScriptPath'USPAnuario_Q1.04.sql'
\i :ScriptPath'USPAnuario_T3.02.sql'
\i :ScriptPath'Cria_Alunos.sql'
\i :ScriptPath'Cria_Professor.sql'
\i :ScriptPath'Cria_Discip.sql'
\i :ScriptPath'Cria_MatrTurma.sql'
\i :ScriptPath'Cria-MatrTurmaAnoSemestre.sql'
