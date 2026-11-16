DROP MATERIALIZED VIEW IF EXISTS ExamesColesterolExercicio;

CREATE MATERIALIZED VIEW ExamesColesterolExercicio AS
    SELECT P.id_paciente, E.dt_coleta,
           MAX(E.de_hospital) AS Hospital,
           AVG(E.de_resultado::FLOAT) FILTER(WHERE E.de_analito ~*'ldl' AND E.de_analito!~*'vldl') AS LDL,              -- evitar contar vldl como ldl.
           AVG(E.de_resultado::FLOAT) FILTER(WHERE E.de_analito ~*'hdl') AS HDL, 
           AVG(E.de_resultado::FLOAT) FILTER(WHERE E.de_analito ~*'v.*coles')AS VLDL, 
           AVG(E.de_resultado::FLOAT) FILTER(WHERE E.de_analito ~*'n[aã]o.hdl')AS NaoHDL,                               -- aceita nao e não
           AVG(E.de_resultado::FLOAT) FILTER(WHERE Lower(E.de_analito) IN ('colesterol total', 'colesterol')) AS Total, -- alguns hospitais usam só colesterol para indicar total.
           MAX(E.cd_unidade) AS Unidade,
		   MAX(D.de_desfecho) AS Desfecho,
		   MAX(CAST(D.dt_desfecho AS date) - CAST(E.dt_coleta AS date)) as DifData, -- seria possível usar LAG
		   ROW_NUMBER() OVER (PARTITION BY P.id_paciente ORDER BY E.dt_coleta ASC) AS SeqExame,
		   ROW_NUMBER() OVER (PARTITION BY P.id_paciente, E.id_atendimento ORDER BY E.dt_coleta ASC) AS SeqExameAtendimento,
		   AVG(E.de_resultado::FLOAT) FILTER(WHERE Lower(E.de_analito) IN ('colesterol total', 'colesterol')) 
			- LAG(AVG(E.de_resultado::FLOAT) FILTER(WHERE Lower(E.de_analito) IN ('colesterol total', 'colesterol')), 1) --calcula a diferença entre o colesterol total de um exame e o do anterior 
    OVER (PARTITION BY P.id_paciente ORDER BY E.dt_coleta ASC) AS DifColesterolTotal
        FROM D2.ExamLabs E JOIN D2.Pacientes P on E.id_paciente = P.ID_Paciente 
			JOIN D2.Desfechos D ON D.id_paciente = P.id_paciente AND D.id_atendimento = E.id_atendimento -- um paciente pode ter vários atendimentos, queremos o desfecho daquele paciente naquele atendimento
        WHERE  P.CD_Municipio IN('GUARULHOS', 'OSASCO') AND
             E.de_exame ~*'coleste' AND 
             E.de_resultado!~'[^\d.,+-]'                -- pode haver texto em vez de números em alguns registros.
        GROUP BY P.id_paciente, E.dt_coleta, E.id_atendimento; -- caso um paciente tenha dois atendimentos no mesmo dia, separa as ocorrências

SELECT *
    FROM ExamesColesterolExercicio
    LIMIT 10;