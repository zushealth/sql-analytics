WITH PROCESSED_PHONE_NUMBERS AS (
    SELECT
        p.upid,
        cp.use AS phone_use,
        REGEXP_REPLACE(REPLACE(cp.value, '+1', ''), '[^0-9]', '') AS phone_number,
        CONCAT(
            SUBSTR(REGEXP_REPLACE(REPLACE(cp.value, '+1', ''), '[^0-9]', ''), 1, 3),  -- Area code (XXX)
            '-',
            SUBSTR(REGEXP_REPLACE(REPLACE(cp.value, '+1', ''), '[^0-9]', ''), 4, 3),  -- First three digits (XXX)
            '-',
            SUBSTR(REGEXP_REPLACE(REPLACE(cp.value, '+1', ''), '[^0-9]', ''), 7, 4)   -- Last four digits (XXXX)
        ) AS formatted_phone_number,
        p.data_source,
        COALESCE(
            encounter.period_end,
            encounter.period_start, 
            TRY_TO_TIMESTAMP(document_reference.period_end),
            TRY_TO_TIMESTAMP(document_reference.period_start),
            document_reference.document_date, 
            document_reference.last_updated, 
            p.last_updated
        ) AS phone_number_recorded_date
    FROM patient p
    JOIN patient_telecom pt ON p.id = pt.patient_id
    JOIN contact_point cp ON pt.contact_point_id = cp.id
    LEFT JOIN document_reference ON document_reference.subject_patient_id = p.id
    LEFT JOIN encounter ON document_reference.encounter_id = encounter.id
    WHERE cp.system = 'phone'
      AND LENGTH(REGEXP_REPLACE(REPLACE(cp.value, '+1', ''), '[^0-9]', '')) = 10
      AND NOT (REGEXP_REPLACE(REPLACE(cp.value, '+1', ''), '[^0-9]', '') LIKE ANY ('%0000%','%8888%','%5555%','%9999%')) 
)
, FIRST_PARTY_PHONE_NUMBERS AS (
    SELECT 
        upid,
        ARRAY_UNIQUE_AGG(phone_use) AS phone_use,
        ARRAY_UNIQUE_AGG(formatted_phone_number) AS phone_numbers
    FROM PROCESSED_PHONE_NUMBERS
    WHERE data_source IS NULL
    GROUP BY upid
), 
THIRD_PARTY_PHONE_NUMBERS AS (
    SELECT 
        upid,
        ARRAY_UNIQUE_AGG(phone_use) AS phone_use,
        formatted_phone_number,
        phone_number_recorded_date,
        RANK() OVER (PARTITION BY upid, formatted_phone_number ORDER BY phone_number_recorded_date DESC NULLS LAST) AS recency_rank
    FROM PROCESSED_PHONE_NUMBERS
    WHERE data_source IS NOT NULL
    GROUP BY upid, formatted_phone_number, phone_number_recorded_date
    QUALIFY recency_rank = 1
)
SELECT 
    tp.upid AS upid,
    tp.phone_use AS third_party_phone_use,
    tp.formatted_phone_number AS third_party_phone_number,
    tp.phone_number_recorded_date AS third_party_phone_recorded_date,
    fp.phone_use AS first_party_phone_use,
    fp.phone_numbers AS first_party_phone_numbers,
FROM THIRD_PARTY_PHONE_NUMBERS tp
LEFT JOIN FIRST_PARTY_PHONE_NUMBERS fp
ON fp.upid = tp.upid
AND NOT ARRAY_CONTAINS(tp.formatted_phone_number::variant, fp.phone_numbers)
ORDER BY tp.upid, tp.phone_number_recorded_date DESC NULLS LAST;
