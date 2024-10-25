-- Query to identify patients with elevated HbA1c levels
SELECT DISTINCT
    O.UPID, 
    O.CODE_LOINC, 
    O.CODE_DISPLAY, 
    O.EFFECTIVE_START, 
    O.EFFECTIVE_END, 
    O.VALUE_QUANTITY_VALUE,
    O.VALUE_QUANTITY_UNIT,
    OIC.CODE AS interpretation_code,
    OIC.DISPLAY AS interpretation_display,
    O.REFERENCE_RANGE_LOW,
    O.REFERENCE_RANGE_HIGH,
    O.REFERENCE_RANGE_UNIT,
    O.REFERENCE_RANGE_DISPLAY,
    CASE 
        WHEN O.DATA_SOURCE IN ('carequality', 'commonwell') THEN TRUE 
        ELSE FALSE 
    END AS ehr_documentation,
    ETC.CODE AS encounter_type_code
FROM OBSERVATION AS O
LEFT JOIN OBSERVATION_INTERPRETATION_CODING AS OIC 
    ON O.OBSERVATION_INTERPRETATION_ID = OIC.OBSERVATION_INTERPRETATION_ID
LEFT JOIN LENS_ENCOUNTER AS E
    ON O.EFFECTIVE_START = E.PERIOD_START
LEFT JOIN LENS_ENCOUNTER_TYPE AS ET
    ON E.LENS_ENCOUNTER_TYPE_ID = ET.ID
LEFT JOIN LENS_ENCOUNTER_TYPE_CODING AS ETC
    ON ET.ID = ETC.LENS_ENCOUNTER_TYPE_ID
WHERE 
    O.CODE_LOINC IN ('4548-4', '17856-6', '4549-2')
    AND O.STATUS NOT IN ('cancelled', 'entered-in-error')
    AND O.VALUE_QUANTITY_VALUE >= 9;
