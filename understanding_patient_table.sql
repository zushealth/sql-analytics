-- Count number of distinct patient resources and distinct UPIDs from the patient table
SELECT 
    COUNT(DISTINCT(ID)) AS count_patient_resources,
    COUNT(DISTINCT(UPID)) AS count_upids
FROM
    PATIENT;
