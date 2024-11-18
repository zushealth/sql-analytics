WITH diab AS (
  SELECT DISTINCT UPID 
  FROM CONDITION
  WHERE CODE_CCS IN ('END002','END003')
),
retin AS (
  SELECT C.ID AS CONDITION_ID, UPID, RECORDED_DATE, COALESCE(CODE_SNOMED, CODE_ICD10CM) AS CODE, CODE_DISPLAY, CCC.CODE AS CAT_CODE, CCC.DISPLAY AS CAT_DISPLAY, C.ENCOUNTER_ID 
  FROM CONDITION AS C
  LEFT JOIN CONDITION_CATEGORY_CODING AS CCC 
    ON C.CONDITION_CATEGORY_ID = CCC.CONDITION_CATEGORY_ID
  WHERE COALESCE(CODE_SNOMED, CODE_ICD10CM) IN ('193349004', '193350004', '232020009', '232021008', '232022001', '232023006', '25412000', '311782002', 
  '312903003', '312904009', '312905005', '312906006', '312907002', '312908007', '312909004', '312912001', '314010006', '314011005', '314014002', '314015001', 
  '390834004', '399862001', '399863006', '399864000', '399865004', '399866003', '399868002', '399869005', '399870006', '399871005', '399872003', '399873008', 
  '399874002', '399875001', '399876000', '399877009', '420486006', '420789003', '421779007', '422034002', '4855003', '59276001', '870420005', 'E08.311', 'E08.319', 
  'E08.3211', 'E08.3212', 'E08.3213', 'E08.3291', 'E08.3292', 'E08.3293', 'E08.3311', 'E08.3312', 'E08.3313', 'E08.3391', 'E08.3392', 'E08.3393', 'E08.3411', 'E08.3412', 
  'E08.3413', 'E08.3491', 'E08.3492', 'E08.3493', 'E08.3511', 'E08.3512', 'E08.3513', 'E08.3521', 'E08.3522', 'E08.3523', 'E08.3531', 'E08.3532', 'E08.3533', 'E08.3541', 
  'E08.3542', 'E08.3543', 'E08.3551', 'E08.3552', 'E08.3553', 'E08.3591', 'E08.3592', 'E08.3593', 'E09.311', 'E09.319', 'E09.3211', 'E09.3212', 'E09.3213', 'E09.3291', 
  'E09.3292', 'E09.3293', 'E09.3311', 'E09.3312', 'E09.3313', 'E09.3391', 'E09.3392', 'E09.3393', 'E09.3411', 'E09.3412', 'E09.3413', 'E09.3491', 'E09.3492', 'E09.3493', 
  'E09.3511', 'E09.3512', 'E09.3513', 'E09.3521', 'E09.3522', 'E09.3523', 'E09.3531', 'E09.3532', 'E09.3533', 'E09.3541', 'E09.3542', 'E09.3543', 'E09.3551', 'E09.3552', 
  'E09.3553', 'E09.3591', 'E09.3592', 'E09.3593', 'E10.311', 'E10.319', 'E10.3211', 'E10.3212', 'E10.3213', 'E10.3291', 'E10.3292', 'E10.3293', 'E10.3311', 'E10.3312', 
  'E10.3313', 'E10.3391', 'E10.3392', 'E10.3393', 'E10.3411', 'E10.3412', 'E10.3413', 'E10.3491', 'E10.3492', 'E10.3493', 'E10.3511', 'E10.3512', 'E10.3513', 'E10.3521', 
  'E10.3522', 'E10.3523', 'E10.3531', 'E10.3532', 'E10.3533', 'E10.3541', 'E10.3542', 'E10.3543', 'E10.3551', 'E10.3552', 'E10.3553', 'E10.3591', 'E10.3592', 'E10.3593', 
  'E11.311', 'E11.319', 'E11.3211', 'E11.3212', 'E11.3213', 'E11.3291', 'E11.3292', 'E11.3293', 'E11.3311', 'E11.3312', 'E11.3313', 'E11.3391', 'E11.3392', 'E11.3393', 
  'E11.3411', 'E11.3412', 'E11.3413', 'E11.3491', 'E11.3492', 'E11.3493', 'E11.3511', 'E11.3512', 'E11.3513', 'E11.3521', 'E11.3522', 'E11.3523', 'E11.3531', 'E11.3532', 
  'E11.3533', 'E11.3541', 'E11.3542', 'E11.3543', 'E11.3551', 'E11.3552', 'E11.3553', 'E11.3591', 'E11.3592', 'E11.3593', 'E13.311', 'E13.319', 'E13.3211', 'E13.3212', 
  'E13.3213', 'E13.3291', 'E13.3292', 'E13.3293', 'E13.3311', 'E13.3312', 'E13.3313', 'E13.3391', 'E13.3392', 'E13.3393', 'E13.3411', 'E13.3412', 'E13.3413', 'E13.3491', 
  'E13.3492', 'E13.3493', 'E13.3511', 'E13.3512', 'E13.3513', 'E13.3521', 'E13.3522', 'E13.3523', 'E13.3531', 'E13.3532', 'E13.3533', 'E13.3541', 'E13.3542', 'E13.3543', 
  'E13.3551', 'E13.3552', 'E13.3553', 'E13.3591', 'E13.3592', 'E13.3593')
),
eye AS (
  SELECT P.ID AS PROCEDURE_ID, UPID, CODE_SNOMED, CODE_DISPLAY, P.ENCOUNTER_ID, ENC_TYPE_CODE, PERFORMED_START, PERFORMED_END 
  FROM PROCEDURE AS P
  LEFT JOIN (
    SELECT 
      E.ID, 
      ETC.CODE AS ENC_TYPE_CODE 
    FROM ENCOUNTER AS E
    LEFT JOIN ENCOUNTER_TYPE_CODING AS ETC 
      ON E.ENCOUNTER_TYPE_ID = ETC.ENCOUNTER_TYPE_ID
    WHERE ETC.USER_SELECTED IS NOT NULL
  ) AS E 
  ON E.ID = P.ENCOUNTER_ID
  WHERE CODE_SNOMED IN ('252779009', '252780007', '252781006', '252782004', '252783009', '252784003', '252788000', '252789008', '252790004', '274795007', '274798009', '308110009', '314971001', '314972008', '410451008', '410452001', '410453006', '410455004', '420213007', '425816006', '427478009', '6615001', '722161008')
),
pz_us AS (
  SELECT 
    patient.upid AS zus_upid, 
    identifier.value AS organization_patient_id
  FROM patient
  JOIN patient_identifier 
    ON patient.id = patient_identifier.patient_id
  JOIN identifier 
    ON identifier.id = patient_identifier.identifier_id
  WHERE identifier.system = 'https://www.sprinterhealth.com/externalID'
)
SELECT 
  diab.UPID,
  pz_us.organization_patient_id,
  'DIAGNOSIS' AS CARE_TYPE, 
  CODE, 
  CODE_DISPLAY, 
  RECORDED_DATE AS DATE, 
  '' AS ENCOUNTER_ID,
  '' AS ENC_TYPE_CODE,
  CONDITION_ID AS DIAGNOSIS_ID,
  NULL AS PROCEDURE_ID
FROM diab
JOIN retin ON diab.UPID = retin.UPID
LEFT JOIN pz_us ON diab.UPID = pz_us.zus_upid
UNION ALL
SELECT 
  diab.UPID,
  pz_us.organization_patient_id,en
  'PROCEDURE' AS CARE_TYPE, 
  CODE_SNOMED AS CODE, 
  CODE_DISPLAY, 
  PERFORMED_START AS DATE, 
  ENCOUNTER_ID, 
  ENC_TYPE_CODE,
  NULL AS DIAGNOSIS_ID,
  PROCEDURE_ID
FROM diab
JOIN eye ON diab.UPID = eye.UPID
LEFT JOIN pz_us ON diab.UPID = pz_us.zus_upid