-- Query to filter for patients (UPIDs) with a record of SNOMED codes 73211009, 313436004, 44054006, or 111552007, indicating that they’ve previously been diagnosed with diabetes mellitus
SELECT 
    DISTINCT UPID
FROM
    LENS_SNOMED_CONDITION
WHERE 
    CODE_SNOMED IN ('73211009','313436004','44054006','111552007');
