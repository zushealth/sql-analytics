-- Count number of distinct patients (UPIDs) in each age bracket
SELECT
    CASE 
        WHEN DATEDIFF('year', birth_date, CURRENT_DATE) BETWEEN 0 AND 4 THEN '0-4'
        WHEN DATEDIFF('year', birth_date, CURRENT_DATE) BETWEEN 5 AND 12 THEN '5-12'
        WHEN DATEDIFF('year', birth_date, CURRENT_DATE) BETWEEN 13 AND 17 THEN '13-17'
        WHEN DATEDIFF('year', birth_date, CURRENT_DATE) BETWEEN 18 AND 24 THEN '18-24'
        WHEN DATEDIFF('year', birth_date, CURRENT_DATE) BETWEEN 25 AND 34 THEN '25-34'
        WHEN DATEDIFF('year', birth_date, CURRENT_DATE) BETWEEN 35 AND 44 THEN '35-44'
        WHEN DATEDIFF('year', birth_date, CURRENT_DATE) BETWEEN 45 AND 54 THEN '45-54'
        WHEN DATEDIFF('year', birth_date, CURRENT_DATE) BETWEEN 55 AND 64 THEN '55-64'
        WHEN DATEDIFF('year', birth_date, CURRENT_DATE) BETWEEN 65 AND 74 THEN '65-74'
        WHEN DATEDIFF('year', birth_date, CURRENT_DATE) BETWEEN 75 AND 84 THEN '75-84'
        ELSE '85+'
    END AS age_bucket,
    COUNT(DISTINCT UPID) AS patient_count
FROM 
    PATIENT
GROUP BY 
    age_bucket;
