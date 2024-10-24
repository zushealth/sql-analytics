-- Count distinct patients by RxNorm code from the Lens_RxNorm_Medication_Statement table
SELECT
  CODE_RXNORM, 
  CODE_DISPLAY, 
  COUNT(DISTINCT UPID) as distinct_upid_count
FROM 
  LENS_RXNORM_MEDICATION_STATEMENT
GROUP BY 
  CODE_RXNORM, 
  CODE_DISPLAY
ORDER BY 
  distinct_upid_count DESC
