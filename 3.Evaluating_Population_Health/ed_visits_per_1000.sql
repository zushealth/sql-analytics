-- Query to calculate ED visits per 1000 patients for a given patient population
SELECT
    COUNT(DISTINCT t.ID) AS ed_visits,
    COUNT(DISTINCT p.UPID) AS members,
    ROUND(COUNT(DISTINCT t.ID) * 1000.0 / NULLIF(COUNT(DISTINCT p.upid), 0), 1) AS ed_visits_per_1000
FROM PATIENT p
LEFT JOIN LENS_TRANSITION_OF_CARE t
    ON p.UPID = t.PATIENT_ID
    AND t.ENCOUNTER_CLASS_CODE = 'EMER'
    AND t.PERIOD_START >= '2024-01-01' ;
