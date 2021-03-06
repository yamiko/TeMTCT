--
-- Dumping routines for database 'bart2'
--
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;

DROP FUNCTION IF EXISTS `text_for_obs`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `text_for_obs`(my_encounter_id INT, my_concept_id INT) RETURNS VARCHAR(255)
BEGIN
	SET @obs_value = NULL;

	SELECT cn.name INTO @obs_value FROM obs o
			LEFT JOIN concept_name cn ON o.value_coded = cn.concept_id AND cn.concept_name_type = 'FULLY_SPECIFIED' 
		WHERE encounter_id = my_encounter_id
			AND o.voided = 0 
			AND o.concept_id = my_concept_id 
			AND o.voided = 0 LIMIT 1;

	IF @obs_value IS NULL THEN
		SELECT value_text INTO @obs_value FROM obs
			WHERE encounter_id = my_encounter_id
				AND voided = 0 
				AND concept_id = my_concept_id 
				AND voided = 0 LIMIT 1;
	END IF;

	IF @obs_value IS NULL OR CHARACTER_LENGTH(LTRIM(@obs_value)) = 0 THEN
		SELECT value_numeric INTO @obs_value FROM obs
			WHERE encounter_id = my_encounter_id
				AND voided = 0 
				AND concept_id = my_concept_id 
				AND voided = 0 LIMIT 1;
	END IF;

	IF @obs_value IS NULL THEN
		SELECT value_datetime INTO @obs_value FROM obs
			WHERE encounter_id = my_encounter_id
				AND voided = 0 
				AND concept_id = my_concept_id 
				AND voided = 0 LIMIT 1;
	END IF;

	IF @obs_value IS NULL THEN
		SELECT cn.name INTO @obs_value FROM obs o
				LEFT JOIN concept_name cn ON o.value_coded = cn.concept_id  
			WHERE encounter_id = my_encounter_id
				AND o.voided = 0 
				AND o.concept_id = my_concept_id 
				AND o.voided = 0 LIMIT 1;
	END IF;

	RETURN @obs_value;
END */;;
DELIMITER ;

DROP FUNCTION IF EXISTS `participant_id`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `participant_id`(my_encounter_id INT) RETURNS VARCHAR(255)
BEGIN
	SET @participant_id = NULL;

	SELECT i.identifier INTO @participant_id FROM encounter e 
			LEFT JOIN patient_identifier i ON e.patient_id = i.patient_id AND i.identifier_type = 3 AND i.voided = 0 
		WHERE e.encounter_id = my_encounter_id
			AND e.voided = 0 LIMIT 1;

	RETURN @participant_id;
END */;;
DELIMITER ;

DROP FUNCTION IF EXISTS `dob`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `dob`(my_person_id INT) RETURNS VARCHAR(255)
BEGIN
	SET @dob = NULL;

	SELECT p.birthdate INTO @dob FROM person p 
		WHERE p.person_id = my_person_id
			AND p.voided = 0 LIMIT 1;

	RETURN @dob;
END */;;
DELIMITER ;

DROP FUNCTION IF EXISTS `dob_estimated`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `dob_estimated`(my_person_id INT) RETURNS VARCHAR(255)
BEGIN
	SET @dob_e_flag = NULL;
	SET @dob_e_resp = NULL;

	SELECT p.birthdate_estimated INTO @dob_e_flag FROM person p 
		WHERE p.person_id = my_person_id
			AND p.voided = 0 LIMIT 1;

	IF @dob_e_flag = 1 THEN
		SET @dob_e_resp = 'YES';
	ELSE
		SET @dob_e_resp = 'NO';
	END IF;

	RETURN @dob_e_resp;
END */;;
DELIMITER ;

DROP FUNCTION IF EXISTS `location_for_obs`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `location_for_obs`(my_encounter_id INT, my_concept_id INT) RETURNS VARCHAR(255)
BEGIN
	SET @location_name = NULL;
	SET @obs_text = NULL;

	SELECT text_for_obs(my_encounter_id, my_concept_id) INTO @obs_text;

	SELECT name INTO @location_name FROM location 
		WHERE location_id = @obs_text LIMIT 1;

	IF @location_name IS NULL THEN
		SET @my_participant_id = NULL;
		SELECT participant_id(my_encounter_id) INTO @my_participant_id;
        SELECT LEFT(@my_participant_id, 2) INTO @location_name;
	END IF;


	RETURN @location_name;
END */;;
DELIMITER ;

DROP FUNCTION IF EXISTS `sex`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `sex`(my_person_id INT) RETURNS VARCHAR(255)
BEGIN
	SET @sex = NULL;

	SELECT p.gender INTO @sex FROM person p 
		WHERE p.person_id = my_person_id
			AND p.voided = 0 LIMIT 1;

	RETURN @sex;
END */;;
DELIMITER ;

DROP FUNCTION IF EXISTS `text_for_creator`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `text_for_creator`(my_creator_id INT) RETURNS VARCHAR(255)
BEGIN
	SET @creator = NULL;

	SELECT u.username INTO @creator FROM users u 
		WHERE u.user_id = my_creator_id
			AND u.retired = 0 LIMIT 1;

	RETURN @creator;
END */;;
DELIMITER ;

DROP FUNCTION IF EXISTS `text_for_double_enterer`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `text_for_double_enterer`(my_encounter_id INT) RETURNS VARCHAR(255)
BEGIN
	SET @creator = NULL;
	SET @creator_id = NULL;
	SET @obs_id = NULL;

	SELECT creator INTO @creator_id FROM obs o 
		WHERE o.concept_id = 8411 AND text_for_obs(my_encounter_id, 8411) = 'Yes' AND encounter_id = my_encounter_id AND voided = 0 LIMIT 1;

	IF @creator_id IS NULL THEN
		SET @creator = NULL;
	ELSE
		SELECT u.username INTO @creator FROM users u 
			WHERE u.user_id = @creator_id
				AND u.retired = 0 LIMIT 1;
	END IF;

	RETURN @creator;
END */;;
DELIMITER ;


DROP FUNCTION IF EXISTS `reserve_duplicates`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `reserve_duplicates`(my_encounter_id INT) RETURNS VARCHAR(255)
BEGIN
	SET @done = "Done";

	SET @new_id = my_encounter_id - 1;
	SET @void_reason = CONCAT("Temporary ", my_encounter_id);

	UPDATE obs SET encounter_id = @new_id, void_reason = @void_reason 
		WHERE encounter_id = my_encounter_id AND voided = 1;

	RETURN "Done";
END */;;
DELIMITER ;

DROP FUNCTION IF EXISTS `restore_observations`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `restore_observations`(my_encounter_id INT) RETURNS VARCHAR(255)
BEGIN
	SET @done = "Done";

	SET @new_id = my_encounter_id - 1;
	SET @void_reason = CONCAT("Temporary ", my_encounter_id);
	SET @new_reason = NULL;

	UPDATE obs SET encounter_id = my_encounter_id, void_reason = @new_reason 
		WHERE encounter_id = @new_id AND voided = 1 AND void_reason  = @void_reason;

	RETURN "Done";
END */;;
DELIMITER ;

/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
