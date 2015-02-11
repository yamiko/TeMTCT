UPDATE person SET gender = LEFT('Male', 1) WHERE person_id = (SELECT patient_id FROM patient_identifier WHERE identifier = '19111C');
UPDATE person SET gender = LEFT('Female', 1) WHERE person_id = (SELECT patient_id FROM patient_identifier WHERE identifier = '14113C');
UPDATE person SET gender = LEFT('Female', 1) WHERE person_id = (SELECT patient_id FROM patient_identifier WHERE identifier = '22102C');
UPDATE person SET gender = LEFT('Female', 1) WHERE person_id = (SELECT patient_id FROM patient_identifier WHERE identifier = '19104C');
UPDATE person SET gender = LEFT('Female', 1) WHERE person_id = (SELECT patient_id FROM patient_identifier WHERE identifier = '12122C');

