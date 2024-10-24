-- -- Query to identify both first-party emails and third-party emails
WITH PROCESSED_EMAILS AS (
    SELECT
        p.upid,
        cp.use AS email_use,
        LOWER(TRIM(REPLACE(cp.value, ' ', ''))) AS email_address,  -- Trim, remove spaces, and convert to lowercase
        p.data_source,
        COALESCE(
            encounter.period_end,
            encounter.period_start, 
            TRY_TO_TIMESTAMP(document_reference.period_end),
            TRY_TO_TIMESTAMP(document_reference.period_start),
            document_reference.document_date, 
            document_reference.last_updated, 
            p.last_updated
        ) AS email_recorded_date
    FROM patient p
    JOIN patient_telecom pt ON p.id = pt.patient_id
    JOIN contact_point cp ON pt.contact_point_id = cp.id
    LEFT JOIN document_reference ON document_reference.subject_patient_id = p.id
    LEFT JOIN encounter ON document_reference.encounter_id = encounter.id
    WHERE cp.system = 'email'
      AND cp.value REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'  -- Validate email format
      AND NOT (email_address LIKE ANY ('%noemail%', '%none%', '%opt-out%', '%donotreply%', '%unsubscribe%', '%invalid%', '%test%'))
      AND cp.value IS NOT NULL
      AND cp.value != ''

)
, FIRST_PARTY_EMAILS AS (
    SELECT 
        upid,
        ARRAY_UNIQUE_AGG(email_use) AS email_use,
        ARRAY_UNIQUE_AGG(email_address) AS email_addresses
    FROM PROCESSED_EMAILS
    WHERE data_source IS NULL
    GROUP BY upid
), 
THIRD_PARTY_EMAILS AS (
    SELECT 
        upid,
        ARRAY_UNIQUE_AGG(email_use) AS email_use,
        email_address,
        email_recorded_date,
        RANK() OVER (PARTITION BY upid, email_address ORDER BY email_recorded_date DESC NULLS LAST) AS recency_rank
    FROM PROCESSED_EMAILS
    WHERE data_source IS NOT NULL
    GROUP BY upid, email_address, email_recorded_date
    QUALIFY recency_rank = 1
)
SELECT 
    fp.upid AS upid,
    tp.email_use AS third_party_email_use,
    tp.email_address AS third_party_email_address,
    tp.email_recorded_date AS third_party_email_recorded_date,
    fp.email_use AS first_party_phone_use,
    fp.email_addresses AS first_party_phone_numbers
FROM THIRD_PARTY_EMAILS tp
LEFT JOIN FIRST_PARTY_EMAILS fp
ON fp.upid = tp.upid
AND NOT ARRAY_CONTAINS(tp.email_address::variant, fp.email_addresses)
ORDER BY fp.upid, tp.email_recorded_date DESC NULLS LAST;
