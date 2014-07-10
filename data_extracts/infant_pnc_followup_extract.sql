SELECT 
'Facility code'                    ,
'Participant Number',
--'ART number'                              ,
'Visit date',
'Next appointment date'                          ,
'Family planning method'                          ,
'Other family planning method'                          ,
'Refill family planning'                         ,
'Refill ARV drug supply'            
'Treatment_regimen'            
'Other_treatment_regimen'            
UNION
SELECT 
location_for_obs(encounter_id, 7759) AS Facility_code,
participant_id(encounter_id), 
--text_for_obs(encounter_id, 7014) AS ART_number,
encounter_datetime AS visit_date,
text_for_obs(encounter_id, 8039) AS Breast_feeding,
text_for_obs(encounter_id, 3590) AS Co_trimoxazole_given,
text_for_obs(encounter_id, 3657) AS Rapid_test_done,
text_for_obs(encounter_id, 2169) AS Rapid_test_results,
text_for_obs(encounter_id, 1576) AS Initiated_ARVs_at_visit,
text_for_obs(encounter_id, 8394) AS Refill_ARVs,
text_for_obs(encounter_id, 6882) AS Treatment_regimen,
text_for_obs(encounter_id, 7215) AS Other_treatment_regimen
 FROM encounter 
WHERE encounter_type = 116 AND (DATEDIFF(encounter_datetime, dob(patient_id))/365) < 5 AND voided = 0 
INTO OUTFILE '/tmp/infant_pnc_followupter.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';