SELECT NUSP, Nome, Config,
       Destaques -> 'Distinção' AS maior_nota,
       Destaques -> 'Trancamento' AS disciplinas_trancadas,
       Destaques -> 'Bom' AS quantidade_disciplinas,
       Destaques
FROM Configura
WHERE Destaques ?| ARRAY['Distinção', 'Trancamento', 'Bom']
ORDER BY NUSP
LIMIT 100;

SELECT count(*) AS total_configura,
       count(*) FILTER (WHERE Destaques ? 'Distinção') AS com_distincao,
       count(*) FILTER (WHERE Destaques ? 'Trancamento') AS com_trancamento,
       count(*) FILTER (WHERE Destaques ? 'Bom') AS com_bom
FROM Configura;
