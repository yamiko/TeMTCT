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
UNION
SELECT 
location_for_obs(encounter_id, 7759) AS Facility_code,
participant_id(encounter_id), 
--text_for_obs(encounter_id, 7014) AS ART_number,
encounter_datetime AS visit_date,
text_for_obs(encounter_id, 5096) AS Next_appointment_date,
text_for_obs(encounter_id, 374) AS Family_planning_method,
text_for_obs(encounter_id, 7215) AS Other_family_planning_method,
text_for_obs(encounter_id, 8397) AS Refill_FPM,
text_for_obs(encounter_id, 8394) AS Picked_up_drug_supply
 FROM encounter 
WHERE encounter_type = 116 AND (DATEDIFF(encounter_datetime, dob(patient_id))/365) > 5 AND voided = 0 
INTO OUTFILE '/tmp/mother_pnc_followupter.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
