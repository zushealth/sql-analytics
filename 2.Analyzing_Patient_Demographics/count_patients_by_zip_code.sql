-- Count distinct patients (UPIDs) by zip code
SELECT 
    LEFT(PA.POSTAL_CODE, 5) as zip_code, 
    COUNT(DISTINCT(P.UPID)) as distinct_upid_count
FROM 
    PATIENT AS P
LEFT JOIN PATIENT_ADDRESS AS PA
    ON P.ID = PA.PATIENT_ID
WHERE 
    zip_code IS NOT NULL
GROUP BY
    zip_code
ORDER BY 
    distinct_upid_count DESC;
