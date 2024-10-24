-- Query to filter for patients (UPIDs) with a record of ICD-10 code E11.9, indicating that they’ve previously been diagnosed with diabetes mellitus
SELECT 
    DISTINCT UPID,
FROM
    LENS_SNOMED_CONDITION
WHERE 
    CODE_ICD10CM = 'E11.9'
