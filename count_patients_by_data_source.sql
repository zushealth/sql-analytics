-- Count number of distinct patient resources by data source in the patient table 
SELECT 
    DATA_SOURCE, 
    COUNT(DISTINCT(UPID)) as number_patients
FROM
    PATIENT
GROUP BY 
    DATA_SOURCE
ORDER BY 
    number_patients DESC
