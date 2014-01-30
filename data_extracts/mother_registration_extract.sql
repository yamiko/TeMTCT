SELECT 
'Patient signed informed consent form'    ,
'Facility code'                    ,
'Participant Number',
'ANC number'                              ,
'ART number'                              ,
'Enrolment date',
'Date of birth'                          ,
'DOB estimated'                          ,
'Estimated delivery date'                          ,
'Gestation weeks at first ANC visit'                         ,
'Gestation weeks at enrolment'            ,
'Parity'                                  ,
'Marital Status'                          ,
'Highest level of education completed'       ,
'Distance between home and health center' ,
'Mode of transportation'                ,
'Other mode of transportation'                ,
'Enrolled at first ANC visit'             ,
'Patient transferred in'                  ,
'Transfer in from'                        ,
'Date of initial HIV+ diagnosis'                    ,
'On ART prior to enrolment'                      ,
'Date treatment initiation prior to enrolment',
'Doube data entered'            
UNION
SELECT 
text_for_obs(encounter_id, 8388) AS Patient_signed_informed_consent_form,
location_for_obs(encounter_id, 7759) AS Facility_code,
participant_id(encounter_id), 
text_for_obs(encounter_id, 8389) AS ANC_number,
text_for_obs(encounter_id, 7014) AS Art_number,
encounter_datetime AS enrolment_date,
dob(patient_id) AS Date_of_birth,
dob_estimated(patient_id) AS DOB_Estimated,
text_for_obs(encounter_id, 5596) AS Estimated_delivery_date,
text_for_obs(encounter_id, 7415) AS Gestation_weeks_at_first_ANC_visit,
text_for_obs(encounter_id, 8415) AS Gestation_weeks_at_enrolment,
text_for_obs(encounter_id, 1053) AS Parity,
text_for_obs(encounter_id, 8401) AS Marital_Status,
text_for_obs(encounter_id, 1688) AS Highest_level_of_school_completed,
text_for_obs(encounter_id, 8406) AS Distance_between_home_and_health_center,
text_for_obs(encounter_id, 975) AS Mode_of_transportation,
text_for_obs(encounter_id, 7215) AS Other_mode_of_transportation,
text_for_obs(encounter_id, 8392) AS Enrolled_at_first_ANC_visit,
text_for_obs(encounter_id, 8365) AS Patient_transferred_in,
location_for_obs(encounter_id, 1427) AS Transfer_in_from,
text_for_obs(encounter_id, 3595) AS Date_of_initial_HIV_pos_diagnosis,
text_for_obs(encounter_id, 7754) AS On_ART_prior_to_enrolment,
text_for_obs(encounter_id, 2516) AS Date_of_treatment_initiation_prior_to_enrolment,
text_for_obs(encounter_id, 1345) AS Doube_data_entered
	FROM encounter 
		WHERE encounter_type = 114 AND (DATEDIFF(encounter_datetime, dob(patient_id))/365) > 5 
			AND voided = 0 
INTO OUTFILE '/tmp/mother_registration.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
