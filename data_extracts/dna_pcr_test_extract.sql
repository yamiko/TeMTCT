SELECT 
'Facility code'                    ,
'Participant Number',
'Testing sample date',
'HIV test result'                          ,
'Results received'                          ,
'Date results received'                          ,
'Results given',
'Date results given',
'Double data entered',
'Notes',
'Entered by'                          
UNION
SELECT 
location_for_obs(encounter_id, 7759) AS Facility_code,
participant_id(encounter_id), 
text_for_obs(encounter_id, 8047) AS Testing_sample_date,
text_for_obs(encounter_id, 2169) AS HIV_test_result,
text_for_obs(encounter_id, 8432) AS Result_received,
text_for_obs(encounter_id, 8053) AS Result_received_date,
text_for_obs(encounter_id, 8431) AS Result_given,
text_for_obs(encounter_id, 8059) AS Result_given_date,
text_for_obs(encounter_id, 8411) AS Double_data_entered,
text_for_obs(encounter_id, 2688) AS Notes,
text_for_creator(creator) AS entered_by
FROM encounter 
WHERE encounter_type = 117 AND voided = 0 
INTO OUTFILE '/tmp/infant_dna_pcr_test.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
