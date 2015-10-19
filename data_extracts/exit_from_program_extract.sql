SELECT 
'Facility code'                    ,
'Participant Number',
'Date',
'Reason for study exit'                          ,
'Specify'                          ,
'Date of death known'                          ,
'Date of death'                          ,
'Cause of death known'                         ,
'Cause of death'                         ,
'Notes',
'Entered by'            
UNION
SELECT 
location_for_obs(encounter_id, 7759) AS Facility_code,
participant_id(encounter_id), 
encounter_datetime AS visit_date,
text_for_obs(encounter_id, 8416) AS Reason_for_exit,
text_for_obs(encounter_id, 7215) AS Specify,
text_for_obs(encounter_id, 8427) AS DOD_known,
text_for_obs(encounter_id, 1815) AS DOD,
text_for_obs(encounter_id, 8426) AS COD_known,
text_for_obs(encounter_id, 5002) AS COD,
text_for_obs(encounter_id, 2688) AS Notes,
text_for_creator(creator) AS entered_by
FROM encounter 
WHERE encounter_type = 118 AND voided = 0 
INTO OUTFILE '/tmp/exit_from_program.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
