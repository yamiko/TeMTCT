SELECT 
'Facility code'                    ,
'Participant Number',
'Visit date',
'Next appointment date'                          ,
'Breast feeding',
'Cotrimoxazole given',
'Rapid test done'                          ,
'Rapid test results'                         ,
'Initiated ARVs at this visit'                 ,
'Refill ARV drug supply',            
'Treatment_regimen', 
'Other_treatment_regimen',
'Double data entered',
'Notes',
'Entered by',
'Double entered by'
UNION
SELECT 
location_for_obs(encounter_id, 7759) AS Facility_code,
participant_id(encounter_id), 
encounter_datetime AS visit_date,
text_for_obs(encounter_id, 5096) AS Next_appointment_date,
text_for_obs(encounter_id, 8039) AS Breast_feeding,
text_for_obs(encounter_id, 3590) AS Co_trimoxazole_given,
text_for_obs(encounter_id, 3657) AS Rapid_test_done,
text_for_obs(encounter_id, 2169) AS Rapid_test_results,
text_for_obs(encounter_id, 1576) AS Initiated_ARVs_at_visit,
text_for_obs(encounter_id, 8394) AS Refill_ARVs,
text_for_obs(encounter_id, 6882) AS Treatment_regimen,
text_for_obs(encounter_id, 7215) AS Other_treatment_regimen,
text_for_obs(encounter_id, 8411) AS Double_data_entered,
text_for_obs(encounter_id, 2688) AS Notes,
text_for_creator(creator) AS entered_by,
text_for_double_enterer(encounter_id) AS Double_entered_by
 FROM encounter 
WHERE encounter_type = 116 AND (DATEDIFF(encounter_datetime, dob(patient_id))/365) < 5 AND voided = 0 
INTO OUTFILE '/tmp/infant_pnc_followup.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
