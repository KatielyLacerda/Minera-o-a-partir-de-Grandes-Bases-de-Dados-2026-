-- Nossa versão não estava aceitando merge então: 
-- usamos UPDATE para atualizar os alunos existentes
-- e INSERT para incluir os que ainda não estão em Configura
-- A transação é gerenciada por executar.sql ou pelo cliente SQL
CREATE EXTENSION IF NOT EXISTS hstore;
ALTER TABLE Configura ADD COLUMN IF NOT EXISTS Destaques hstore;

-- Como o notebook não declara uma PK, preparamos pra interrompa se a chave lógica for ambígua
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM Configura GROUP BY NUSP HAVING count(*) > 1)
     OR EXISTS (SELECT 1 FROM Configura WHERE NUSP IS NULL) THEN
    RAISE EXCEPTION 'Configura contém NUSP repetido ou nulo; revise a preparação.';
  END IF;
END $$;

-- 1. Distinção: maior NF entre as aprovações, se houver alguma NF >= 9.
WITH origem AS (
    SELECT a.NUSP, a.Nome, max(n.nf)::text AS valor
    FROM Alunos AS a JOIN notas_atividade AS n ON n.nusp = a.NUSP
    WHERE n.nf > 5
    GROUP BY a.NUSP, a.Nome
    HAVING max(n.nf) >= 9
), atualizados AS (
    UPDATE Configura AS c
    SET Destaques = coalesce(c.Destaques, ''::hstore)
                    || hstore('Distinção', s.valor)
    FROM origem AS s
    WHERE c.NUSP = s.NUSP
    RETURNING c.NUSP
)
INSERT INTO Configura (NUSP, Nome, Destaques)
SELECT s.NUSP, s.Nome, hstore('Distinção', s.valor)
FROM origem AS s
WHERE NOT EXISTS (SELECT 1 FROM Configura AS c WHERE c.NUSP = s.NUSP);

-- 2. Trancamento: frequência = 0 E NF <= 0,5.
-- Se houver várias disciplinas, guarda todos os códigos num único texto.
-- Uma linha por aluno evita múltiplas atualizações do mesmo alvo no MERGE
WITH origem AS (
    SELECT a.NUSP, a.Nome,
           string_agg(DISTINCT n.disciplina, ', ' ORDER BY n.disciplina) AS valor
    FROM Alunos AS a JOIN notas_atividade AS n ON n.nusp = a.NUSP
    WHERE n.frequencia = 0 AND n.nf <= 0.5
    GROUP BY a.NUSP, a.Nome
), atualizados AS (
    UPDATE Configura AS c
    SET Destaques = coalesce(c.Destaques, ''::hstore)
                    || hstore('Trancamento', s.valor)
    FROM origem AS s
    WHERE c.NUSP = s.NUSP
    RETURNING c.NUSP
)
INSERT INTO Configura (NUSP, Nome, Destaques)
SELECT s.NUSP, s.Nome, hstore('Trancamento', s.valor)
FROM origem AS s
WHERE NOT EXISTS (SELECT 1 FROM Configura AS c WHERE c.NUSP = s.NUSP);

-- 3. Bom: pelo menos duas disciplinas distintas com NF >= 8.
WITH origem AS (
    SELECT a.NUSP, a.Nome, count(DISTINCT n.disciplina)::text AS valor
    FROM Alunos AS a JOIN notas_atividade AS n ON n.nusp = a.NUSP
    WHERE n.nf >= 8
    GROUP BY a.NUSP, a.Nome
    HAVING count(DISTINCT n.disciplina) >= 2
), atualizados AS (
    UPDATE Configura AS c
    SET Destaques = coalesce(c.Destaques, ''::hstore)
                    || hstore('Bom', s.valor)
    FROM origem AS s
    WHERE c.NUSP = s.NUSP
    RETURNING c.NUSP
)
INSERT INTO Configura (NUSP, Nome, Destaques)
SELECT s.NUSP, s.Nome, hstore('Bom', s.valor)
FROM origem AS s
WHERE NOT EXISTS (SELECT 1 FROM Configura AS c WHERE c.NUSP = s.NUSP);

-- PS: Config nunca é alterado, então novos registros terão Config NULL.
-- Este script adiciona/atualiza destaques apenas!