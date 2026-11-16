---------------------------------------------------------------
-- Caetano Traina Júnior -- Agosto de 2016 --------------------
-- Cria tabela de Nomes próprio, com Nome, Sexo, e LinguaMae --
---------------------------------------------------------------

DROP VIEW  IF EXISTS Tabelas CASCADE;
DROP TABLE IF EXISTS AcadVarInt;
DROP TABLE IF EXISTS Nomes;
DROP TABLE IF EXISTS Temp_Nomes;
DROP TABLE IF EXISTS Sobrenomes;
DROP TABLE IF EXISTS Temp_SobreNomes;

CREATE TABLE AcadVarInt(
    Nome TEXT,
    Valor BIGINT);

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--
-- Prepara os nomes próprios e Sobrenomes
CREATE TABLE Nomes (
    Id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Nome VARCHAR(30),
    Genero CHAR,
    Origem CHAR(3)
    );

\copy Nomes(Nome, Genero, Origem) FROM '/Users/katielylacerda/Downloads/HStore/base/Alunos80K/Nomes.csv' WITH (FORMAT csv, HEADER true)


CREATE TABLE Sobrenomes (
    Id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Nome VARCHAR(30),
    Origem CHAR(3)
    );

\copy SobreNomes(Nome, Origem) FROM '/Users/katielylacerda/Downloads/HStore/base/Alunos80K/SobreNomes.csv' WITH (FORMAT csv, HEADER true)



-- Apagar tuplas repetidas: Nomes próprios
SELECT Nome, Genero, Origem 
       INTO TEMPORARY Temp_Nomes FROM Nomes
    GROUP By Nome, Genero, Origem
    HAVING Count(*)>1;
DELETE FROM Nomes N
    USING Temp_Nomes T
    WHERE (N.Nome, N.Genero, N.Origem)=(T.Nome, T.Genero, T.Origem);
INSERT INTO Nomes(Nome, Genero, Origem) 
    SELECT Nome, Genero, Origem FROM  Temp_Nomes;
DROP TABLE Temp_Nomes;

-- Apagar tuplas repetidas: Sobrenomes
SELECT Nome, Origem 
       INTO TEMPORARY Temp_SobreNomes from SobreNomes
    GROUP By Nome, Origem
    HAVING Count(*)>1;
DELETE FROM SobreNomes N
    USING Temp_SobreNomes T
    WHERE (N.Nome, N.Origem)=(T.Nome, T.Origem);
INSERT INTO SobreNomes(Nome, Origem) 
    SELECT Nome, Origem FROM  Temp_SobreNomes;
DROP TABLE Temp_SobreNomes;


--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--
-- Inicia a documentação das Tabelas 
CREATE VIEW Tabelas AS
    SELECT 1::Integer       AS Numero,  'Nomes'::Text    AS NomeTab, Count(*)::BigInt AS NroTuplas FROM Nomes UNION 
    SELECT 2,                           'Sobrenomes',                Count(*)                      FROM Sobrenomes;

INSERT INTO AcadVarInt 
    SELECT 'CountNomes' Nome, NroTuplas   Valor   FROM Tabelas WHERE NomeTab='Nomes';

INSERT INTO AcadVarInt 
    SELECT 'CountSobrenomes', NroTuplas           FROM Tabelas WHERE NomeTab='Sobrenomes';

TABLE Tabelas;

