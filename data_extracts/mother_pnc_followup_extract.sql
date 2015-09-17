SELECT 
'Facility code'                    ,
'Participant Number',
'Visit date',
'Next appointment date'                          ,
'Family planning method'                          ,
'Other family planning method'                          ,
'Refill family planning'                         ,
'Refill ARV drug supply',
'Number of pills',
'Number of days',
'ART Regimen',
'Double data entered',
'Notes'            
UNION
SELECT 
location_for_obs(encounter_id, 7759) AS Facility_code,
participant_id(encounter_id), 
encounter_datetime AS visit_date,
text_for_obs(encounter_id, 5096) AS Next_appointment_date,
text_for_obs(encounter_id, 374) AS Family_planning_method,
text_for_obs(encounter_id, 7215) AS Other_family_planning_method,
text_for_obs(encounter_id, 8397) AS Refill_FPM,
text_for_obs(encounter_id, 8394) AS Picked_up_drug_supply,
text_for_obs(encounter_id, 8434) AS Number_of_pills,
text_for_obs(encounter_id, 8433) AS Number_of_days,
text_for_obs(encounter_id, 6882) AS ART_regimen,
text_for_obs(encounter_id, 8411) AS Double_data_entered,
text_for_obs(encounter_id, 2688) AS Notes
 FROM encounter 
WHERE encounter_type = 116 AND (DATEDIFF(encounter_datetime, dob(patient_id))/365) > 5 AND voided = 0 
INTO OUTFILE '/tmp/mother_pnc_followup.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
