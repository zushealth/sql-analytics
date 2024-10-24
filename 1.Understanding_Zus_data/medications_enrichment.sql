-- Count number of distinct patients (UPIDs) by Rx-Norm coded MedicationStatements
SELECT
  CODE_RXNORM, 
  CODE_DISPLAY, 
  COUNT(DISTINCT UPID) as distinct_upid_count
FROM 
  MEDICATION_STATEMENT
GROUP BY 
  CODE_RXNORM, 
  CODE_DISPLAY
ORDER BY 
  distinct_upid_count DESC
