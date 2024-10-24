-- Query to identify HCC recapture opportunities
WITH HCC AS (
  SELECT 
    UPID, 
    COUNT(DISTINCT CODE_HCC) AS hcc_count, 
    MIN(last_recorded) AS oldest_recorded_date, 
    MAX(last_recorded) AS latest_recorded_date, 
    COUNT(CASE WHEN DATEDIFF(YEAR, last_recorded, CURRENT_DATE()) < 2 THEN 1 END) AS hcc_count_within_2_years,
    MAX(CASE WHEN CODE_HCC IN ('17', '18', '19') THEN last_recorded END) AS diabetes_last_recorded,
    MAX(CASE WHEN CODE_HCC IN ('84', '85', '86', '87', '88', '96') THEN last_recorded END) AS cardiovascular_last_recorded,
    MAX(CASE WHEN CODE_HCC IN ('8', '9', '10', '11', '12') THEN last_recorded END) AS cancer_last_recorded,
    LISTAGG(CASE WHEN DATEDIFF(YEAR, last_recorded, CURRENT_DATE()) < 2 THEN CODE_HCC END, ', ') AS compliant_hccs,
    LISTAGG(CASE WHEN DATEDIFF(YEAR, last_recorded, CURRENT_DATE()) > 1 THEN CODE_HCC END, ', ') AS noncompliant_hccs
  FROM (
    SELECT 
      UPID, 
      CODE_HCC,
      MAX(
        CASE 
          WHEN LENGTH(CAST(RECORDED_DATE AS VARCHAR)) = 7 
            THEN TO_DATE(CAST(RECORDED_DATE AS VARCHAR) || '-01', 'YYYY-MM-DD')
          ELSE DATE_TRUNC('day', RECORDED_DATE)
        END
      ) AS last_recorded
    FROM LENS_SNOMED_CONDITION C
    GROUP BY UPID, CODE_HCC
  ) AS subquery
  GROUP BY UPID
)
SELECT
    UPID, 
    CONCAT('https://app.zushealth.com/patients/', UPID, '/conditions') AS zus_app_link, 
    DIABETES_LAST_RECORDED,
    CARDIOVASCULAR_LAST_RECORDED,
    CANCER_LAST_RECORDED,
    HCC_COUNT, 
    HCC_COUNT_WITHIN_2_YEARS,
    COMPLIANT_HCCs AS captured_hccs,
    NONCOMPLIANT_HCCS AS uncaptured_hccs
FROM HCC
WHERE hcc_count - hcc_count_within_2_years > 0;
