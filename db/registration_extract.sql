SELECT text_for_obs(encounter_id, 8389) AS ANC_number,
text_for_obs(encounter_id, 7014) AS Art_number,
text_for_obs(encounter_id, 8182) AS ARVs_in_Labour,
text_for_obs(encounter_id, 8186) AS Baby_ARVs_at_Birth,
text_for_obs(encounter_id, 8187) AS Baby_ARVs_cont_d,
text_for_obs(encounter_id, 8039) AS Breast_feeding,
text_for_obs(encounter_id, 3590) AS Co_trimoxazole_given_to_patient,
text_for_obs(encounter_id, 7882) AS Confirmatory_HIV_test_date,
text_for_obs(encounter_id, 2516) AS Date_antiretrovirals_started,
text_for_obs(encounter_id, 8398) AS Delivery_location,
text_for_obs(encounter_id, 8406) AS Distance_between_home_and_health_center,
text_for_obs(encounter_id, 8392) AS Enrolled_at_first_ANC_visit,
text_for_obs(encounter_id, 5596) AS Estimated_date_of_confinement,
text_for_obs(encounter_id, 7754) AS Ever_received_ART,
text_for_obs(encounter_id, 7415) AS Gestation_weeks,
text_for_obs(encounter_id, 8415) AS Gestation_weeks_at_enrolment,
text_for_obs(encounter_id, 1688) AS Highest_level_of_school_completed,
text_for_obs(encounter_id, 1169) AS HIV_infected,
text_for_obs(encounter_id, 8401) AS Marital_Status,
text_for_obs(encounter_id, 975) AS Method_of_transportation,
text_for_obs(encounter_id, 3595) AS Mother_HIV_test_date,
text_for_obs(encounter_id, 1186) AS Number_of_weeks_on_treatment,
text_for_obs(encounter_id, 1053) AS Parity,
text_for_obs(encounter_id, 8391) AS Patient_NOT_enrolled_at_other_facility,
text_for_obs(encounter_id, 1755) AS Patient_pregnant,
text_for_obs(encounter_id, 8388) AS Patient_signed_informed_consent_form,
text_for_obs(encounter_id, 8365) AS Patient_transferred_in,
text_for_obs(encounter_id, 8387) AS Plan_to_NOT_move,
text_for_obs(encounter_id, 8386) AS Provide_voluntary_consent_form,
text_for_obs(encounter_id, 1427) AS Transfer_in_from,
text_for_obs(encounter_id, 7759) AS Workstation_location
 FROM encounter 
WHERE encounter_type = 114 AND voided != 0 ORDER by encounter_datetime
INTO OUTFILE '/home/temtct/TeMTCT/db/trial.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
