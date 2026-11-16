-- Origem das notas na base Alunos80K 
CREATE OR REPLACE TEMP VIEW notas_atividade AS
SELECT m.NUSP AS nusp, t.Sigla::text AS disciplina,
       m.NF::numeric AS nf, m.Frequencia::numeric AS frequencia
FROM Matricula AS m
JOIN Turma AS t ON t.Codigo = m.CodigoTurma;
