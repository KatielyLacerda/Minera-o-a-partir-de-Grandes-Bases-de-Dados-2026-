-------------------------------------------------------------------------------------------------------
-- Criar a tabela de Cidades Brasileiras com informações de censo Rural/Urbano (censo 2010) e gênero --
-- Caetano Traina Júnior -- Agosto de 2016 ------------------------------------------------------------
-------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS Cidades CASCADE;
CREATE TABLE Cidades (
    Codigo      decimal(7)   NOT NULL, -- Código IBGE
    Estado      char(2)      NOT NULL, 
    Municipio   char(70)     NOT NULL,
    Populacao   decimal(10)  NOT NULL, -- População total
    pctUrbana   decimal(7,4) NOT NULL, -- Porcentagem da população urbana
    pctRural    decimal(7,4) NOT NULL, -- Porcentagem da população rural
    pctHomem    decimal(7,4) NOT NULL, -- Porcentagem da população masculina
    PctMulher   decimal(7,4) NOT NULL, -- Porcentagem da população feminina
    pctHM       decimal(7,4) NOT NULL  -- proporção de homens na população
    );

-------------------------------------------------------------------------------------------------------
\copy Cidades FROM '/Users/katielylacerda/Downloads/HStore/base/Alunos80K/Cidades.csv' WITH (FORMAT csv, HEADER true)



--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--
CREATE OR REPLACE VIEW Tabelas AS
        SELECT 1::Integer AS Numero, 'Nomes'::Text  AS NomeTab, Count(*)::BIGINT AS NroTuplas FROM Nomes UNION 
        SELECT 2, 'Sobrenomes', Count(*) FROM Sobrenomes UNION 
        SELECT 3, 'Cidades',    Count(*) FROM Cidades
    ORDER BY Numero;

DELETE FROM AcadVarInt WHERE Nome='CountCidades';
INSERT INTO AcadVarInt 
    SELECT 'CountCidades', NroTuplas FROM Tabelas WHERE NomeTab='Cidades';

TABLE Tabelas;
