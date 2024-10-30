-- -- Query to identify both first-party emails and third-party emails
WITH PROCESSED_EMAILS AS (
    SELECT
        p.UPID,
        cp.USE AS email_use,
        LOWER(TRIM(REPLACE(cp.VALUE, ' ', ''))) AS email_address,  -- Trim, remove spaces, and convert to lowercase
        p.DATA_SOURCE,
        COALESCE(
            ENCOUNTER.PERIOD_END,
            ENCOUNTER.PERIOD_START, 
            TRY_TO_TIMESTAMP(DOCUMENT_REFERENCE.PERIOD_END),
            TRY_TO_TIMESTAMP(DOCUMENT_REFERENCE.PERIOD_START),
            DOCUMENT_REFERENCE.DOCUMENT_DATE, 
            DOCUMENT_REFERENCE.LAST_UPDATED, 
            p.LAST_UPDATED
        ) AS email_recorded_date
    FROM PATIENT p
    JOIN PATIENT_TELECOM pt ON p.ID = pt.PATIENT_ID
    JOIN CONTACT_POINT cp ON pt.CONTACT_POINT_ID = cp.ID
    LEFT JOIN DOCUMENT_REFERENCE ON DOCUMENT_REFERENCE.SUBJECT_PATIENT_ID = p.ID
    LEFT JOIN ENCOUNTER ON DOCUMENT_REFERENCE.ENCOUNTER_ID = ENCOUNTER.ID
    WHERE cp.SYSTEM = 'email'
      AND cp.VALUE REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'  -- Validate email format
      AND NOT (EMAIL_ADDRESS LIKE ANY ('%noemail%', '%none%', '%opt-out%', '%donotreply%', '%unsubscribe%', '%invalid%', '%test%'))
      AND cp.VALUE IS NOT NULL
      AND cp.VALUE != ''

)
, FIRST_PARTY_EMAILS AS (
    SELECT 
        UPID,
        ARRAY_UNIQUE_AGG(EMAIL_ADDRESS) AS email_addresses
    FROM PROCESSED_EMAILS
    WHERE DATA_SOURCE IS NULL
    GROUP BY UPID
), 
THIRD_PARTY_EMAILS AS (
    SELECT 
        UPID,
        EMAIL_ADDRESS,
        EMAIL_RECORDED_DATE,
        RANK() OVER (PARTITION BY UPID, EMAIL_ADDRESS ORDER BY EMAIL_RECORDED_DATE DESC NULLS LAST) AS recency_rank
    FROM PROCESSED_EMAILS
    WHERE DATA_SOURCE IS NOT NULL
    GROUP BY UPID, EMAIL_ADDRESS, EMAIL_RECORDED_DATE
    QUALIFY recency_rank = 1
)
SELECT 
    tp.UPID AS UPID,
    tp.EMAIL_ADDRESS AS third_party_email_address,
    tp.EMAIL_RECORDED_DATE AS third_party_email_recorded_date,
    fp.EMAIL_ADDRESSES AS first_party_email_addresses
FROM THIRD_PARTY_EMAILS tp
LEFT JOIN FIRST_PARTY_EMAILS fp
ON fp.UPID = tp.UPID
WHERE NOT ARRAY_CONTAINS(third_party_email_address::variant, first_party_email_addresses)
ORDER BY fp.UPID, tp.EMAIL_RECORDED_DATE DESC NULLS LAST;
