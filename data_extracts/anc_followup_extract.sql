SELECT 
'Facility code'                    ,
'Participant Number',
'Visit date'                              ,
'Purpose of visit',
'ANC visit number',
'Next appointment date',
'Abortion',
'Date of Abortion',
'Treatment status',
'Drug refill',
'Number of pills',
'Days',
'ART Regimen',
'Other ART Regimen',
'Double data entered',
'Notes'
UNION
SELECT 
location_for_obs(encounter_id, 7759) AS Facility_code,
participant_id(encounter_id), 
encounter_datetime AS visit_date,
text_for_obs(encounter_id, 6189) AS Purpose_of_visit,
text_for_obs(encounter_id, 6259) AS ANC_visit,
text_for_obs(encounter_id, 5096) AS Appointment_date,
text_for_obs(encounter_id, 50) AS Abortion,
text_for_obs(encounter_id, 8429) AS Date_of_bortion,
text_for_obs(encounter_id, 1576) AS Treatment_status,
text_for_obs(encounter_id, 8394) AS Drug_refill,
text_for_obs(encounter_id, 2679) AS Number_of_pills,
text_for_obs(encounter_id, 1072) AS Days,
text_for_obs(encounter_id, 6882) AS ART_regimen,
text_for_obs(encounter_id, 7215) AS Other_art_regimen,
text_for_obs(encounter_id, 1345) AS Double_data_entered,
text_for_obs(encounter_id, 2688) AS Notes
FROM encounter 
WHERE encounter_type = 115 AND voided = 0 
INTO OUTFILE '/tmp/anc_followup.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
