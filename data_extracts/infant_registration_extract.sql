SELECT 
'Facility code'                    ,
'Participant Number',
--'ANC number'                              ,
--'ART number'                              ,
'Date of Birth',
'Sex',
'Visit date',
'ARVs in Labour'                          ,
'Baby ARVs at Birth'                      ,
'Baby ARVs cont_d'                        ,
'Baby ARVs adherence'                          ,
'Delivery location'                          ,
'Gestation weeks at birth'            ,
'Co-trimoxazole given'         ,
'Breast feeding'
UNION
SELECT 
location_for_obs(encounter_id, 7759) AS Facility_code,
participant_id(encounter_id), 
--text_for_obs(encounter_id, 8389) AS ANC_number,
--text_for_obs(encounter_id, 7014) AS Art_number,
dob(patient_id) AS Date_of_birth,
sex(patient_id) AS Sex,
encounter_datetime AS Visit_date,
text_for_obs(encounter_id, 8182) AS ARVs_in_Labour,
text_for_obs(encounter_id, 8186) AS Baby_ARVs_at_Birth,
text_for_obs(encounter_id, 8187) AS Baby_ARVs_cont_d,
text_for_obs(encounter_id, 1186) AS Baby_ARVs_adherence,
text_for_obs(encounter_id, 8398) AS Delivery_location,
text_for_obs(encounter_id, 7415) AS Gestation_weeks_at_birth,
text_for_obs(encounter_id, 3590) AS Co_trimoxazole_given,
text_for_obs(encounter_id, 8039) AS Breast_feeding
 FROM encounter 
WHERE encounter_type = 114 AND (DATEDIFF(encounter_datetime, dob(patient_id))/365) < 5 AND voided = 0 
INTO OUTFILE '/tmp/infant_registration.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';



