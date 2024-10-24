-- Query to filter for patients (UPIDs) with a record of RxNorm code `31265` in the last 12 months, indicating a record of the patient taking prednisone 20 MG Oral Tablet in the past year.
SELECT 
    DISTINCT UPID
FROM 
    LENS_RXNORM_MEDICATION_STATEMENT
WHERE 
    CODE_RXNORM = '312615' AND
    (DATE_ASSERTED >= DATEADD(YEAR,-1,CURRENT_DATE()) OR 
    LAST_FILL_DATE >= DATEADD(YEAR,-1,CURRENT_DATE()))
