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


DROP FUNCTION IF EXISTS `totals_for_user`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `totals_for_user`(my_encounter_type_id INT, my_user_id INT, my_infant_flag INT) RETURNS VARCHAR(255)
BEGIN
	SET @total_records = NULL;

	IF my_infant_flag = 0 THEN
		SELECT COUNT(*) INTO @total_records FROM encounter 
			WHERE encounter_type = my_encounter_type_id AND creator = my_user_id AND voided = 0;
	ELSE
		IF my_infant_flag = 1 THEN
			SELECT COUNT(*) INTO @total_records FROM encounter 
				WHERE encounter_type = my_encounter_type_id 
					AND creator = my_user_id AND voided = 0 AND (DATEDIFF(encounter_datetime, dob(patient_id))/365) < 5;
		ELSE
			SELECT COUNT(*) INTO @total_records FROM encounter 
				WHERE encounter_type = my_encounter_type_id 
					AND creator = my_user_id AND voided = 0 AND (DATEDIFF(encounter_datetime, dob(patient_id))/365) >= 5;
		END IF;
	END IF;

	RETURN @total_records;
END */;;
DELIMITER ;

DROP FUNCTION IF EXISTS `totals_rekeyed_by_user`;
DELIMITER ;;
/*!50003 CREATE*/ /*!50020 */ /*!50003 FUNCTION `totals_rekeyed_by_user`(my_encounter_type_id INT, my_user_id INT, my_infant_flag INT) RETURNS VARCHAR(255)
BEGIN
	SET @total_records = NULL;


	IF my_infant_flag = 0 THEN
		SELECT COUNT(*) INTO @total_records FROM encounter e INNER JOIN obs o ON e.encounter_id = o.encounter_id AND o.concept_id = 8411  
			WHERE e.encounter_type = my_encounter_type_id AND text_for_obs(e.encounter_id, 8411) = 'Yes' AND o.creator = my_user_id AND o.voided = 0 AND e.voided = 0;
	ELSE
		IF my_infant_flag = 1 THEN
			SELECT COUNT(*) INTO @total_records 
				FROM encounter e INNER JOIN obs o 
					ON e.encounter_id = o.encounter_id AND o.concept_id = 8411 AND (DATEDIFF(e.encounter_datetime, dob(e.patient_id))/365) < 5 
				WHERE e.encounter_type = my_encounter_type_id AND text_for_obs(e.encounter_id, 8411) = 'Yes' AND o.creator = my_user_id AND o.voided = 0 AND e.voided = 0;
		ELSE
			SELECT COUNT(*) INTO @total_records 
				FROM encounter e INNER JOIN obs o 
					ON e.encounter_id = o.encounter_id AND o.concept_id = 8411  AND (DATEDIFF(e.encounter_datetime, dob(e.patient_id))/365) >= 5 
				WHERE e.encounter_type = my_encounter_type_id AND text_for_obs(e.encounter_id, 8411) = 'Yes' AND o.creator = my_user_id AND o.voided = 0 AND e.voided = 0;
		END IF;
	END IF;
	RETURN @total_records;
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
