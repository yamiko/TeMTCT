SELECT 
'Facility code'                    ,
'Participant Number',
--'ANC number'                              ,
'Visit date'                              ,
'Treatment status',
'Drug refill',
'ART Regimen',
'Other ART Regimen'
UNION
SELECT 
location_for_obs(encounter_id, 7759) AS Facility_code,
participant_id(encounter_id), 
--text_for_obs(encounter_id, 8389) AS ANC_number,
encounter_datetime AS visit_date,
text_for_obs(encounter_id, 1576) AS Treatment_status,
text_for_obs(encounter_id, 8394) AS Drug_refill,
text_for_obs(encounter_id, 6882) AS ART_regimen,
text_for_obs(encounter_id, 7215) AS Other_art_regimen
FROM encounter 
WHERE encounter_type = 115 AND voided = 0 
INTO OUTFILE '/tmp/anc_followup.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
