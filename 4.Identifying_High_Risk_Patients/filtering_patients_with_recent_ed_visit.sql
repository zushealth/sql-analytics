-- Query to identify patients with recent a ED visit
SELECT 
    t.UPID,
    CONCAT('https://app.zushealth.com/patients/', t.UPID, '/aggregated-profile') AS ZUS_APP_LINK,
    t.PERIOD_START, 
    t.PERIOD_END,
    l.NAME AS location_name,
    dd.DISPLAY AS discharge_disposition,
    ARRAY_AGG(DISTINCT c.CODE_DISPLAY) AS conditions
FROM 
    LENS_TRANSITION_OF_CARE AS t
JOIN 
    LOCATION AS l 
    ON t.ADMITTING_LOCATION_ID = l.ID
    AND t.ENCOUNTER_CLASS_CODE = 'EMER'
    AND t.PERIOD_START >= DATEADD(MONTH, -12, CURRENT_DATE())
    AND TO_DATE(t.PERIOD_START) <= CURRENT_DATE()
LEFT JOIN 
    LENS_TRANSITION_OF_CARE_DIAGNOSIS AS d 
    ON d.LENS_TRANSITION_OF_CARE_ID = t.ID
LEFT JOIN 
    LENS_SNOMED_CONDITION AS c 
    ON c.ID = d.CONDITION_ID
LEFT JOIN 
    LENS_TRANSITION_OF_CARE_DISCHARGE_DISPOSITION AS dd 
    ON t.LENS_TRANSITION_OF_CARE_DISCHARGE_DISPOSITION_ID = dd.ID
LEFT JOIN 
    LENS_TRANSITION_OF_CARE_ADT_MESSAGE AS am 
    ON am.LENS_TRANSITION_OF_CARE_ID = t.ID
GROUP BY 
    t.UPID,
    CONCAT('https://app.zushealth.com/patients/', t.UPID, '/aggregated-profile'), 
    t.PERIOD_START, 
    t.PERIOD_END, 
    l.NAME, 
    dd.DISPLAY
ORDER BY 
    t.PERIOD_START DESC;
