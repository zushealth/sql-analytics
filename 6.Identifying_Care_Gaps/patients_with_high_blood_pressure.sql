-- Query to identify patients with high blood pressure
SELECT 
    DISTINCT O.UPID,
    O.EFFECTIVE_START, 
    O.EFFECTIVE_END, 
    MAX(CASE 
        WHEN CODE_LOINC IN ('8480-6', '8479-8', '8459-0', '8460-8') 
        THEN VALUE_QUANTITY_VALUE 
    END) AS systolic,
    MAX(CASE 
        WHEN CODE_LOINC IN ('8462-4', '8453-3', '8454-1') 
        THEN VALUE_QUANTITY_VALUE 
    END) AS diastolic,
    LISTAGG(DISTINCT OIC.CODE, ', ') AS interpretation_code,
    LISTAGG(DISTINCT OIC.DISPLAY, ', ') AS interpretation_display,
    MAX(CASE 
        WHEN DATA_SOURCE IN ('carequality', 'commonwell') 
        THEN TRUE 
    END) AS ehr_documentation,
    LISTAGG(DISTINCT O.ENCOUNTER_ID, ', ') AS encounter_ids,
    LISTAGG(DISTINCT E.enc_type_code, ', ') AS encounter_type
FROM OBSERVATION AS O
LEFT JOIN OBSERVATION_INTERPRETATION_CODING AS OIC 
    ON O.OBSERVATION_INTERPRETATION_ID = OIC.OBSERVATION_INTERPRETATION_ID
LEFT JOIN (
    SELECT 
        E.ID, 
        ETC.CODE AS enc_type_code
    FROM ENCOUNTER AS E
    LEFT JOIN ENCOUNTER_TYPE_CODING AS ETC 
        ON E.ENCOUNTER_TYPE_ID = ETC.ENCOUNTER_TYPE_ID
    WHERE ETC.USER_SELECTED IS NOT NULL
) AS E 
    ON E.ID = O.ENCOUNTER_ID
WHERE 
    O.CODE_LOINC IN ('8480-6', '8479-8', '8459-0', '8460-8', '8462-4', '8453-3', '8454-1')
    AND O.STATUS NOT IN ('cancelled', 'entered-in-error')
    AND O.VALUE_QUANTITY_VALUE IS NOT NULL
    AND (E.enc_type_code = 'AMB' OR E.enc_type_code IS NULL)
GROUP BY 
    O.UPID, 
    O.EFFECTIVE_START, 
    O.EFFECTIVE_END;
