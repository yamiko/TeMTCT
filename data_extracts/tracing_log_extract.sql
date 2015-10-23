SELECT 
'Facility code'                    ,
'Participant Number',
'Date',
'Study arm'                          ,
'Date appointment missed'                          ,
'Reason for followup'                          ,
'Date to return'                          ,
'Date of meeting HSA'                          ,
'SMS sent'                          ,
'Name of requestor'                          ,
'Date of home visit'                          ,
'Outcome code'                          ,
'Date client returned'                          ,
'Notes',
'Entered by',
'Double entered by'
UNION
SELECT 
location_for_obs(encounter_id, 7759) AS Facility_code,
participant_id(encounter_id), 
encounter_datetime AS visit_date,
text_for_obs(encounter_id, 8438) AS Study_arm,
text_for_obs(encounter_id, 2875) AS Date_app_missed,
text_for_obs(encounter_id, 8450) AS Reason_for_followup,
text_for_obs(encounter_id, 8451) AS Date_to_return,
text_for_obs(encounter_id, 8452) AS Date_of_meeting_HSA,
text_for_obs(encounter_id, 8453) AS SMS_sent,
text_for_obs(encounter_id, 8454) AS Name_of_requestor,
text_for_obs(encounter_id, 8455) AS Date_of_home_visit,
text_for_obs(encounter_id, 8456) AS Outcome_code,
text_for_obs(encounter_id, 8462) AS Date_client_returned,
text_for_obs(encounter_id, 2688) AS Notes,
text_for_creator(creator) AS entered_by,
text_for_double_enterer(encounter_id) AS Double_entered_by
 FROM encounter 
WHERE encounter_type = 119 AND voided = 0 
INTO OUTFILE '/tmp/tracing_log.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
