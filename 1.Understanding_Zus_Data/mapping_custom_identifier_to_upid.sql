-- Map from an organization's internal identifier (in this case with identifier system https://organizationName.com/ID) to Zus UPID
SELECT
  PATIENT.UPID as zus_upid,
  PATIENT_IDENTIFIER.VALUE as organization_patient_id
FROM
  PATIENT
JOIN PATIENT_IDENTIFIER
  ON PATIENT.ID = PATIENT_IDENTIFIER.PATIENT_ID
WHERE
  PATIENT_IDENTIFIER.SYSTEM = 'https://organizationName.com/ID' ;
