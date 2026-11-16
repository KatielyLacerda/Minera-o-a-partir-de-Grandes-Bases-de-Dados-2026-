CREATE EXTENSION hstore;

DROP TABLE IF EXISTS Configura;
CREATE TABLE Configura (
	NUSP NUMERIC(8),
	Nome TEXT,
	Line INT,
	Col INT,
	BkGrdnColor INT,
	FrGrdnColor INT,
	Font TEXT,
	Proxy Boolean	
);

INSERT INTO  Configura(NUSP, Nome) 
    SELECT NUSP, Nome 
	    FROM Alunos 
		ORDER BY Random() 
		LIMIT 40000;

UPDATE Configura
    SET Line=300*Random()+20*Random(),
	    Col =40*Random()+20*Random()+10*Random()
	WHERE Random()<.8;

UPDATE Configura
    SET BkGrdnColor=0xFFFFFF*Random(),
	    FrGrdnColor =0xFFFFFF*Random()
	WHERE Random()<.6;

CREATE TEMPORARY TABLE Fonts (I INT, F TEXT);
INSERT INTO Fonts VALUES(1, 'Times'), (2, 'Helvetica'), (3, 'Arial'), (4, 'Courier'), (5, 'Garamond');

UPDATE Configura
    SET Font=(SELECT F FROM Fonts WHERE I=NUSP%5)
	WHERE Random()<.6;

DROP TABLE Fonts;

UPDATE Configura SET Proxy=true WHERE Random()<.5;
UPDATE Configura SET Proxy=false WHERE Random()<.5;

SELECT * FROM Configura
ORDER BY RANDOM();


------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
CREATE EXTENSION hstore;

DROP TABLE IF EXISTS Configura;
CREATE TABLE Configura (
	NUSP NUMERIC(8),
	Nome TEXT,
	Config HSTORE
	-- Line INT,
	-- Col INT,
	-- BkGrdnColor INT,
	-- FrGrdnColor INT,
	-- Font TEXT,
	-- Proxy Boolean
);

INSERT INTO  Configura(NUSP, Nome) 
    SELECT NUSP, Nome 
	    FROM Alunos 
		ORDER BY Random() 
		LIMIT 40000;

UPDATE Configura 
   SET Config = HStore(ARRAY['line', 'col'], 
					   ARRAY[TEXT((300*Random()+20*Random())::INT), TEXT((40*Random()+20*Random()+10*Random())::INT)])
	WHERE Random()<.8;

UPDATE Configura 
   SET Config = Config || HStore(ARRAY['BkGrdnColor', 'FrGrdnColor'], 
								 ARRAY[TEXT((0xFFFFFF*Random())::INT), TEXT((0xFFFFFF*Random())::INT)])
	WHERE Random()<.6;

CREATE TEMPORARY TABLE Fonts (I INT, F TEXT);
INSERT INTO Fonts VALUES(1, 'Times'), (2, 'Helvetica'), (3, 'Arial'), (4, 'Courier'), (5, 'Garamond');

UPDATE Configura
    SET Config=Config || HStore('Font', ''''||(SELECT F FROM Fonts WHERE I=(NUSP%5+1))::TEXT||'''')
	WHERE Random()<.6;

DROP TABLE Fonts;

UPDATE Configura SET Config=Config || HStore('Proxy', 'true')
WHERE Random()<.5;
UPDATE Configura SET Config=Config || HStore('Proxy', 'false')
WHERE Random()<.5;

SELECT * FROM Configura
ORDER BY RANDOM()