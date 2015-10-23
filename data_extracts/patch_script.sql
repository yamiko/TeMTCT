-- Script to buffer duplicate observations that cannot be handled by OpenMRS app
-- Please change the Encounter ID of the desired encounter

SET @my_status = NULL;
CALL update_regimens(@my_status);

