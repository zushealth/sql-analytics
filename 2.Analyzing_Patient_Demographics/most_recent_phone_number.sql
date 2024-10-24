-- Query to identify both first-party phone numbers and third-party phone numbers
WITH PROCESSED_PHONE_NUMBERS AS (
    SELECT
        p.UPID,
        cp.USE AS phone_use,
        REGEXP_REPLACE(REPLACE(cp.VALUE, '+1', ''), '[^0-9]', '') AS phone_number,
        CONCAT(
            SUBSTR(REGEXP_REPLACE(REPLACE(cp.VALUE, '+1', ''), '[^0-9]', ''), 1, 3),  -- Area code (XXX)
            '-',
            SUBSTR(REGEXP_REPLACE(REPLACE(cp.VALUE, '+1', ''), '[^0-9]', ''), 4, 3),  -- First three digits (XXX)
            '-',
            SUBSTR(REGEXP_REPLACE(REPLACE(cp.VALUE, '+1', ''), '[^0-9]', ''), 7, 4)   -- Last four digits (XXXX)
        ) AS formatted_phone_number,
        p.DATA_SOURCE,
        COALESCE(
            ENCOUNTER.PERIOD_END,
            ENCOUNTER.PERIOD_START, 
            TRY_TO_TIMESTAMP(DOCUMENT_REFERENCE.PERIOD_END),
            TRY_TO_TIMESTAMP(DOCUMENT_REFERENCE.PERIOD_START),
            DOCUMENT_REFERENCE.DOCUMENT_DATE, 
            DOCUMENT_REFERENCE.LAST_UPDATED, 
            p.LAST_UPDATED
        ) AS phone_number_recorded_date
    FROM PATIENT p
    JOIN PATIENT_TELECOM pt ON p.ID = pt.PATIENT_ID
    JOIN CONTACT_POINT cp ON pt.CONTACT_POINT_ID = cp.ID
    LEFT JOIN DOCUMENT_REFERENCE ON DOCUMENT_REFERENCE.SUBJECT_PATIENT_ID = p.ID
    LEFT JOIN ENCOUNTER ON DOCUMENT_REFERENCE.ENCOUNTER_ID = ENCOUNTER.ID
    WHERE cp.SYSTEM = 'phone'
      AND LENGTH(REGEXP_REPLACE(REPLACE(cp.VALUE, '+1', ''), '[^0-9]', '')) = 10
      AND NOT (REGEXP_REPLACE(REPLACE(cp.VALUE, '+1', ''), '[^0-9]', '') LIKE ANY ('%0000%','%8888%','%5555%','%9999%')) 
)
, FIRST_PARTY_PHONE_NUMBERS AS (
    SELECT 
        UPID,
        ARRAY_UNIQUE_AGG(PHONE_USE) AS phone_use,
        ARRAY_UNIQUE_AGG(FORMATTED_PHONE_NUMBER) AS phone_numbers
    FROM PROCESSED_PHONE_NUMBERS
    WHERE DATA_SOURCE IS NULL
    GROUP BY UPID
), 
THIRD_PARTY_PHONE_NUMBERS AS (
    SELECT 
        UPID,
        ARRAY_UNIQUE_AGG(PHONE_USE) AS phone_use,
        FORMATTED_PHONE_NUMBER,
        PHONE_NUMBER_RECORDED_DATE,
        RANK() OVER (PARTITION BY UPID, FORMATTED_PHONE_NUMBER ORDER BY PHONE_NUMBER_RECORDED_DATE DESC NULLS LAST) AS recency_rank
    FROM PROCESSED_PHONE_NUMBERS
    WHERE DATA_SOURCE IS NOT NULL
    GROUP BY UPID, FORMATTED_PHONE_NUMBER, PHONE_NUMBER_RECORDED_DATE
    QUALIFY recency_rank = 1
)
SELECT 
    tp.UPID AS upid,
    tp.PHONE_USE AS third_party_phone_use,
    tp.FORMATTED_PHONE_NUMBER AS third_party_phone_number,
    tp.PHONE_NUMBER_RECORDED_DATE AS third_party_phone_recorded_date,
    fp.PHONE_USE AS first_party_phone_use,
    fp.PHONE_NUMBERS AS first_party_phone_numbers,
FROM THIRD_PARTY_PHONE_NUMBERS tp
LEFT JOIN FIRST_PARTY_PHONE_NUMBERS fp
ON fp.UPID = tp.UPID
AND NOT ARRAY_CONTAINS(tp.FORMATTED_PHONE_NUMBER::variant, fp.phone_numbers)
ORDER BY tp.UPID, tp.PHONE_NUMBER_RECORDED_DATE DESC NULLS LAST;
