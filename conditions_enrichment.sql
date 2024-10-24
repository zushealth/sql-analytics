-- Count number of distinct patients (UPIDs) by SNOMED-coded condition
SELECT 
  CODE_SNOMED,
  CODE_DISPLAY,
  COUNT(DISTINCT UPID) as distinct_upid_count
FROM
  CONDITION
GROUP BY
  CODE_SNOMED,
  CODE_DISPLAY
ORDER BY 
  distinct_upid_count DESC
