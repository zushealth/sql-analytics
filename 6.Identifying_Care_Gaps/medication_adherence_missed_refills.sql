-- Query to identify patients with missed medication refills
WITH unique_dispenses AS (
    SELECT DISTINCT
        mr.upid,
        codes.VALUE:code::varchar AS rxnorm_active_ingredient,
        mr.number_of_repeats_allowed,
        md.when_prepared,
        md.when_handed_over,
        md.days_supply
    FROM medication_dispense md
    JOIN medication_request mr
        ON mr.id = md.authorizing_prescription_medication_request_id
    LATERAL FLATTEN(input => mr.resource_json:medicationCodeableConcept:coding) AS codes
    LATERAL FLATTEN(input => codes.VALUE:extension) AS codes_extension
    WHERE mr.number_of_repeats_allowed IS NOT NULL
      AND mr.number_of_repeats_allowed > 0
      AND codes_extension.VALUE:valueString = 'ActiveIngredient'
)
SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY upid, rxnorm_active_ingredient 
        ORDER BY COALESCE(when_handed_over, when_prepared) DESC NULLS LAST
    ) AS rnk,
    DATEDIFF('day', COALESCE(when_handed_over, when_prepared), CURRENT_DATE()) AS days_since_last_dispense_or_fill
FROM unique_dispenses
QUALIFY rnk = 1
  AND DATEDIFF('day', COALESCE(when_handed_over, when_prepared), CURRENT_DATE()) > 
      GREATEST(36, days_supply + 5)
ORDER BY COALESCE(when_handed_over, when_prepared) DESC;
