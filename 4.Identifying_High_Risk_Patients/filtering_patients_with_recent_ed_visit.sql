-- Query to identify patients with recent a ED visit
SELECT 
    CONCAT('https://app.zushealth.com/patients/', t.upid, '/aggregated-profile') AS zus_app_link,
    t.period_start, 
    t.period_end,
    l.name AS location_name,
    dd.display AS discharge_disposition,
    ARRAY_AGG(DISTINCT c.code_display) AS conditions,
    CASE 
        WHEN am.document_reference_id IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END AS documentation_available
FROM 
    lens_transition_of_care AS t
JOIN 
    location AS l 
    ON t.admitting_location_id = l.id
    AND t.encounter_class_code = 'EMER'
    AND t.period_start >= DATEADD(MONTH, -12, CURRENT_DATE())
    AND TO_DATE(t.period_start) <= CURRENT_DATE()
LEFT JOIN 
    lens_transition_of_care_diagnosis AS d 
    ON d.lens_transition_of_care_id = t.id
LEFT JOIN 
    lens_snomed_condition AS c 
    ON c.id = d.condition_id
LEFT JOIN 
    lens_transition_of_care_discharge_disposition AS dd 
    ON t.lens_transition_of_care_discharge_disposition_id = dd.id
LEFT JOIN 
    lens_transition_of_care_adt_message AS am 
    ON am.lens_transition_of_care_id = t.id
GROUP BY 
    CONCAT('https://app.zushealth.com/patients/', t.upid, '/aggregated-profile'), 
    t.period_start, 
    t.period_end, 
    l.name, 
    dd.display, 
    documentation_available
ORDER BY 
    t.period_start DESC;
