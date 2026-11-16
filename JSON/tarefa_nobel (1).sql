
-- ----------------------------------------------------------------------------
-- Criar a base de dados Nobel 
-- ----------------------------------------------------------------------------
DROP DATABASE IF EXISTS nobel WITH (FORCE);
CREATE DATABASE nobel
    WITH OWNER = postgres
    ENCODING = 'UTF8';

\c nobel

-- ----------------------------------------------------------------------------
-- Criar e carregar as tabelas Premios, Premiados e Paises
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS Temporaria;
CREATE TABLE Temporaria (Linha TEXT);

DROP TABLE IF EXISTS Premios, Premiados, Paises CASCADE;
CREATE TABLE Premios (Premio jsonb NOT NULL);
CREATE TABLE Premiados (Premiados jsonb NOT NULL);
CREATE TABLE Paises (Pais jsonb NOT NULL);

-- Carrega Premios
\copy Temporaria FROM '/home/juliana/bd/Arquivos de dados da Base Nobel-20261109/prize.json' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')
INSERT INTO Premios
    SELECT jsonb_array_elements((Linha::Jsonb)->'prizes') FROM Temporaria;
DELETE FROM Temporaria;

-- Carrega Premiados
\copy Temporaria FROM '/home/juliana/bd/Arquivos de dados da Base Nobel-20261109/Laureate.json' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')
INSERT INTO Premiados
    SELECT jsonb_array_elements((Linha::Jsonb)->'laureates') FROM Temporaria;
DELETE FROM Temporaria;

-- Carrega Paises
\copy Temporaria FROM '/home/juliana/bd/Arquivos de dados da Base Nobel-20261109/Country.json' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')
INSERT INTO Paises
    SELECT jsonb_array_elements((Linha::Jsonb)->'countries') FROM Temporaria;
DELETE FROM Temporaria;

-- ----------------------------------------------------------------------------
-- Criação e carga da tabela auxiliar Especialidades (Specialties.csv)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS Especialidades;
CREATE TABLE Especialidades (
    Laureate  TEXT,
    Specialty TEXT
);

\copy Especialidades(Laureate, Specialty) FROM '/home/juliana/bd/Arquivos de dados da Base Nobel-20261109/Specialties.csv' WITH (FORMAT csv, HEADER true)


-- ============================================================================
-- 1) Atualize a tabela Premiados, de maneira que o documento associado a cada
--    Premiado possa indicar, além da categoria do Prêmio, também a
--    especialidade de cada um, quando disponível
-- ============================================================================

UPDATE Premiados P
    SET Premiados = jsonb_set(
                        P.Premiados || jsonb_build_object('specialty', TRIM(E.Specialty)),
                        '{prizes,0,specialty}',
                        to_jsonb(TRIM(E.Specialty)),
                        true
                    )
    FROM Especialidades E
    WHERE TRIM(E.Laureate) LIKE '% ' || REPLACE(REPLACE(REPLACE(RTRIM(P.Premiados->>'surname', '.'), 'u00f6', 'ö'), 'u00e1', 'á'), 'u00e9', 'é')
      AND POSITION(
              LEFT(REGEXP_REPLACE(P.Premiados->>'firstname', '^Sir ', ''), 1)
              IN LEFT(TRIM(E.Laureate), LENGTH(TRIM(E.Laureate)) - LENGTH(REPLACE(REPLACE(REPLACE(RTRIM(P.Premiados->>'surname', '.'), 'u00f6', 'ö'), 'u00e1', 'á'), 'u00e9', 'é')))
          ) > 0
      AND NOT (P.Premiados->>'firstname' = 'William' AND TRIM(E.Laureate) = 'W.L. Bragg');

-- Verificação da Atualização 1 (usando LATERAL para desaninhar 'prizes'):
SELECT (P.Premiados->>'firstname') || ' ' || (P.Premiados->>'surname') AS Quem,
       (P.Premiados->>'bornCountry') AS Pais,
       Pr.value->>'year' AS Quando,
       Pr.value->>'category' AS Categoria,
       Pr.value->>'specialty' AS Especialidade_No_Premio,
       P.Premiados->>'specialty' AS Especialidade_No_Premiado
    FROM Premiados P
    CROSS JOIN LATERAL jsonb_array_elements(P.Premiados->'prizes') AS Pr(value)
    WHERE P.Premiados ? 'specialty'
    ORDER BY Especialidade_No_Premiado, Quando
    LIMIT 15;


-- ============================================================================
-- 2) Suponha que essa informação deve também ser armazenada fora do documento
--    Json. Faça a atualização correspondente.
-- ============================================================================

-- 2.1) Altera a tabela Premiados adicionando um atributo estruturado fora do JSONB:
ALTER TABLE Premiados
    ADD COLUMN IF NOT EXISTS Specialty TEXT;

-- 2.2) Atualiza a nova coluna externa:
UPDATE Premiados P
    SET Specialty = TRIM(E.Specialty)
    FROM Especialidades E
    WHERE TRIM(E.Laureate) LIKE '% ' || REPLACE(REPLACE(REPLACE(RTRIM(P.Premiados->>'surname', '.'), 'u00f6', 'ö'), 'u00e1', 'á'), 'u00e9', 'é')
      AND POSITION(
              LEFT(REGEXP_REPLACE(P.Premiados->>'firstname', '^Sir ', ''), 1)
              IN LEFT(TRIM(E.Laureate), LENGTH(TRIM(E.Laureate)) - LENGTH(REPLACE(REPLACE(REPLACE(RTRIM(P.Premiados->>'surname', '.'), 'u00f6', 'ö'), 'u00e1', 'á'), 'u00e9', 'é')))
          ) > 0
      AND NOT (P.Premiados->>'firstname' = 'William' AND TRIM(E.Laureate) = 'W.L. Bragg');

-- 2.3) Verificação da Atualização 2 (exibindo o dado dentro e fora do documento JSON):
SELECT (P.Premiados->>'firstname') || ' ' || (P.Premiados->>'surname') AS Quem,
       Pr.value->>'year' AS Quando,
       Pr.value->>'category' AS Categoria,
       Pr.value->>'specialty' AS Especialidade_No_JSON,
       P.Specialty AS Especialidade_Fora_Do_JSON
    FROM Premiados P
    CROSS JOIN LATERAL jsonb_array_elements(P.Premiados->'prizes') AS Pr(value)
    WHERE P.Specialty IS NOT NULL
    ORDER BY P.Specialty, Quando
    LIMIT 20;
