-- Step 1: For each patient (UPID), identify HCC codes found by first-party sources and by third-party sources in the past 2 years
WITH FIRST_PARTY_HCCS AS (
    SELECT
        UPID,
        CODE_HCC
    FROM
        CONDITION
    WHERE
        DATA_SOURCE IS NULL
        AND CODE_HCC IS NOT NULL
    GROUP BY 
        UPID,
        CODE_HCC
), RECENT_THIRD_PARTY_HCCS AS (
    SELECT
        UPID,
        CODE_HCC
    FROM
        CONDITION
    WHERE
        DATA_SOURCE IS NOT NULL
        AND CODE_HCC IS NOT NULL
        AND RECORDED_DATE >= DATEADD('year', -2, CURRENT_DATE)
    GROUP BY 
        UPID,
        CODE_HCC
),
-- Step 2: Identify HCC codes that are found only by third-party sources within the last 2 years for each patient
RECENT_THIRD_PARTY_ONLY_HCCS AS (
    SELECT
        tp.UPID,
        tp.CODE_HCC,
    FROM
        RECENT_THIRD_PARTY_HCCS tp
    LEFT JOIN FIRST_PARTY_HCCS fp
        ON tp.UPID = fp.UPID 
        AND tp.CODE_HCC = fp.CODE_HCC
    WHERE
        fp.CODE_HCC IS NULL
),
-- Step 3: Count distinct HCCs per patient from both first and third-party sources
PATIENT_HCC_COUNTS AS (
    SELECT
        UPID,
        COUNT(DISTINCT CASE WHEN DATA_SOURCE IS NULL THEN CODE_HCC END) AS FIRST_PARTY_HCC_COUNT,
        COUNT(DISTINCT CASE WHEN DATA_SOURCE IS NOT NULL 
            AND RECORDED_DATE >= DATEADD('year', -2, CURRENT_DATE) 
            THEN CODE_HCC END) AS RECENT_THIRD_PARTY_HCC_COUNT
    FROM
        CONDITION
    WHERE CODE_HCC IS NOT NULL
    GROUP BY
        UPID
),
-- Step 4: Count the HCC opportunities per patient
HCC_OPPORTUNITY_AGG AS (
    SELECT
        UPID,
        COUNT(DISTINCT CODE_HCC) AS HCC_OPPORTUNITY_COUNT
    FROM
        RECENT_THIRD_PARTY_ONLY_HCCS
    GROUP BY
        UPID
)
-- Step 5: Combine the zaggregated results with the HCC opportunity codes and list them
SELECT
    phc.UPID,
    CONCAT('https://app.zushealth.com/patients/',phc.UPID, '/conditions') AS ZusAppLink,
    phc.FIRST_PARTY_HCC_COUNT,
    phc.RECENT_THIRD_PARTY_HCC_COUNT,
    COALESCE(hca.HCC_OPPORTUNITY_COUNT, 0) AS HCC_OPPORTUNITY_COUNT,
    LISTAGG(DISTINCT tpo.CODE_HCC, ', ') WITHIN GROUP (ORDER BY tpo.CODE_HCC) AS HCC_OPPORTUNITY_CODES,
FROM
    PATIENT_HCC_COUNTS phc
LEFT JOIN
    HCC_OPPORTUNITY_AGG hca ON phc.UPID = hca.UPID
LEFT JOIN
    RECENT_THIRD_PARTY_ONLY_HCCS tpo ON phc.UPID = tpo.UPID
GROUP BY
    phc.UPID, phc.FIRST_PARTY_HCC_COUNT, phc.RECENT_THIRD_PARTY_HCC_COUNT, hca.HCC_OPPORTUNITY_COUNT
ORDER BY
    FIRST_PARTY_HCC_COUNT DESC NULLS LAST;
