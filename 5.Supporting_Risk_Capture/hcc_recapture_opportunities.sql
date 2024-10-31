
-- Step 1: Identify HCC codes found by first-party and the third-party sources for each patient (UPID)
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
), THIRD_PARTY_HCCS AS (
    SELECT
        UPID,
        CODE_HCC
    FROM
        CONDITION
    WHERE
        DATA_SOURCE IS NOT NULL
        AND CODE_HCC IS NOT NULL
    GROUP BY 
        UPID,
        CODE_HCC
),
-- Step 2: Identify HCC codes that are found only by third-party sources for each patient
THIRD_PARTY_ONLY_HCCS AS (
    SELECT
        tp.UPID,
        tp.CODE_HCC,
    FROM
        THIRD_PARTY_HCCS tp
    LEFT JOIN FIRST_PARTY_HCCS fp
        ON tp.UPID = fp.UPID 
        AND tp.CODE_HCC = fp.CODE_HCC
    WHERE
        fp.CODE_HCC IS NULL
),
-- Step 3: Count distinct HCCs per patient from both third and first-party sources
PATIENT_HCC_COUNTS AS (
    SELECT
        UPID,
        COUNT(DISTINCT CASE WHEN DATA_SOURCE IS NULL THEN CODE_HCC END) AS FIRST_PARTY_HCC_COUNT,
        COUNT(DISTINCT CASE WHEN DATA_SOURCE IS NOT NULL THEN CODE_HCC END) AS THIRD_PARTY_HCC_COUNT
    FROM
        CONDITION
    WHERE CODE_HCC IS NOT NULL
    GROUP BY
        UPID
),
-- Step 4: Count the new condition count per patient
NEW_CONDITIONS_AGG AS (
    SELECT
        UPID,
        COUNT(DISTINCT CODE_HCC) AS NEW_HCC_COUNT
    FROM
        THIRD_PARTY_ONLY_HCCS
    GROUP BY
        UPID
)
-- Step 5: Combine the aggregated results with the net new HCC codes and list them
SELECT
    phc.UPID,
    CONCAT('https://app.zushealth.com/patients/',phc.UPID, '/conditions') AS ZusAppLink,
    phc.FIRST_PARTY_HCC_COUNT,
    phc.THIRD_PARTY_HCC_COUNT,
    COALESCE(nca.NEW_HCC_COUNT, 0) AS NEW_HCC_COUNT,
    LISTAGG(DISTINCT tpo.CODE_HCC, ', ') WITHIN GROUP (ORDER BY tpo.CODE_HCC) AS NEW_HCC_CODES,
FROM
    PATIENT_HCC_COUNTS phc
LEFT JOIN
    NEW_CONDITIONS_AGG nca ON phc.UPID = nca.UPID
LEFT JOIN
    THIRD_PARTY_ONLY_HCCS tpo ON phc.UPID = tpo.UPID
GROUP BY
    phc.UPID, phc.FIRST_PARTY_HCC_COUNT, phc.THIRD_PARTY_HCC_COUNT, nca.NEW_HCC_COUNT
ORDER BY
    FIRST_PARTY_HCC_COUNT DESC NULLS LAST;
