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

	IF @obs_value IS NULL THEN
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
