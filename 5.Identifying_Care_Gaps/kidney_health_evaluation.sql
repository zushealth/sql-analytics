WITH RankedObservations AS (
    SELECT 
        O.UPID,
        CASE 
            WHEN O.CODE_LOINC IN (
                '48642-3', '48643-1', '50044-7', '50210-4', '62238-1', 
                '69405-9', '70969-1', '77147-7', '98979-8'
            ) THEN 'eGFR'
            WHEN O.CODE_LOINC IN (
                '13705-9', '14585-4', '14958-3', '14959-1', '30000-4', 
                '30001-2', '32294-1', '44292-1', '59159-4', '76401-9', 
                '77253-3', '77254-1', '2709552'
            ) THEN 'uACR'
        END AS LAB_TYPE,
        O.CODE_LOINC, 
        O.CODE_DISPLAY, 
        O.EFFECTIVE_START, 
        O.EFFECTIVE_END, 
        O.VALUE_QUANTITY_VALUE,
        O.VALUE_QUANTITY_UNIT,
        OIC.CODE AS INTERPRETATION_CODE,
        OIC.DISPLAY AS INTERPRETATION_DISPLAY,
        O.REFERENCE_RANGE_LOW,
        O.REFERENCE_RANGE_HIGH,
        O.REFERENCE_RANGE_UNIT,
        O.REFERENCE_RANGE_DISPLAY,
        CASE 
            WHEN O.DATA_SOURCE IN ('carequality', 'commonwell') THEN TRUE 
            ELSE FALSE 
        END AS EHR_DOCUMENTATION,
        O.ENCOUNTER_ID,
        E.ENC_TYPE_CODE,
        ROW_NUMBER() OVER (
            PARTITION BY O.UPID, 
                         CASE 
                             WHEN O.CODE_LOINC IN (
                                 '48642-3', '48643-1', '50044-7', '50210-4', 
                                 '62238-1', '69405-9', '70969-1', '77147-7', 
                                 '98979-8'
                             ) THEN 'eGFR'
                             WHEN O.CODE_LOINC IN (
                                 '13705-9', '14585-4', '14958-3', '14959-1', 
                                 '30000-4', '30001-2', '32294-1', '44292-1', 
                                 '59159-4', '76401-9', '77253-3', '77254-1', 
                                 '2709552'
                             ) THEN 'uACR'
                         END 
            ORDER BY O.EFFECTIVE_START DESC NULLS FIRST
        ) AS RANK
    FROM 
        PATIENT P
    JOIN 
        LENS_SNOMED_CONDITION C 
        ON P.UPID = C.UPID
        AND C.CODE_CCS IN ('END002', 'END003')
    LEFT JOIN 
        OBSERVATION O 
        ON P.UPID = O.UPID
        AND O.CODE_LOINC IN (
            '48642-3', '48643-1', '50044-7', '50210-4', '62238-1', 
            '69405-9', '70969-1', '77147-7', '98979-8', '13705-9', 
            '14585-4', '14958-3', '14959-1', '30000-4', '30001-2', 
            '32294-1', '44292-1', '59159-4', '76401-9', '77253-3', 
            '77254-1', '2709552'
        )
        AND O.STATUS NOT IN ('cancelled', 'entered-in-error')
        AND O.VALUE_QUANTITY_VALUE IS NOT NULL
    LEFT JOIN 
        OBSERVATION_INTERPRETATION_CODING OIC 
        ON O.OBSERVATION_INTERPRETATION_ID = OIC.OBSERVATION_INTERPRETATION_ID
    LEFT JOIN (
        SELECT 
            E.ID, 
            ETC.CODE AS ENC_TYPE_CODE
        FROM 
            ENCOUNTER E
        LEFT JOIN 
            ENCOUNTER_TYPE_CODING ETC 
            ON E.ENCOUNTER_TYPE_ID = ETC.ENCOUNTER_TYPE_ID
        WHERE 
            ETC.USER_SELECTED IS NOT NULL
    ) E 
    ON E.ID = O.ENCOUNTER_ID
    AND (E.ENC_TYPE_CODE = 'AMB' OR E.ENC_TYPE_CODE IS NULL)
)
SELECT * 
FROM RankedObservations
WHERE RANK = 1
ORDER BY UPID