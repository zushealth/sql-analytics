-- Query to identify patients with missed medication refills
WITH unique_dispenses AS (
    SELECT DISTINCT
        mr.UPID,
        codes.VALUE:code::varchar AS rxnorm_active_ingredient,
        mr.NUMBER_OF_REPEATS_ALLOWED,
        md.WHEN_PREPARED,
        md.WHEN_HANDED_OVER,
        md.DAYS_SUPPLY
    FROM MEDICATION_DISPENSE md
    JOIN MEDICATION_REQUEST mr
        ON mr.ID = md.AUTHORIZING_PRESCRIPTION_MEDICATION_REQUEST_ID,
    LATERAL FLATTEN(input => mr.RESOURCE_JSON:medicationCodeableConcept:coding) AS codes,
    LATERAL FLATTEN(input => codes.VALUE:extension) AS codes_extension
    WHERE mr.NUMBER_OF_REPEATS_ALLOWED IS NOT NULL
      AND mr.NUMBER_OF_REPEATS_ALLOWED > 0
      AND codes_extension.VALUE:valueString = 'ActiveIngredient'
)
SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY UPID, rxnorm_active_ingredient 
        ORDER BY COALESCE(WHEN_HANDED_OVER, WHEN_PREPARED) DESC NULLS LAST
    ) AS rnk,
    DATEDIFF('day', COALESCE(WHEN_HANDED_OVER, WHEN_PREPARED), CURRENT_DATE()) AS days_since_last_dispense_or_fill
FROM unique_dispenses
QUALIFY rnk = 1
  AND DATEDIFF('day', COALESCE(WHEN_HANDED_OVER, WHEN_PREPARED), CURRENT_DATE()) > 
      GREATEST(36, days_supply + 5)
ORDER BY COALESCE(WHEN_HANDED_OVER, WHEN_PREPARED) DESC;
