-- Count de-duplicated encounters by encounter type from the Lens Encounter Table
SELECT
    CLASS_CODE,
    CLASS_DISPLAY,
    COUNT(DISTINCT(ID)) AS count_encounters
FROM 
    LENS_ENCOUNTER
GROUP BY 
    CLASS_CODE, 
    CLASS_DISPLAY
ORDER BY 
    count_encounters DESC;
