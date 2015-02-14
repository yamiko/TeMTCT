SELECT 
'User Name'                    ,
'MR',
'MR Rekey',
'IR',
'IR Rekey',
'M PNC'                          ,
'M PNC Rekey'                      ,
'I PNC'                          ,
'I PNC Rekey'                      ,
'DNA-PCR'                        ,
'DNA-PCR Rekey'                          ,
'TL'                          ,
'TL Rekey'            ,
'SE'         ,
'SE Rekey'
UNION
SELECT 
username, 
totals_for_user(114, user_id, 2),
totals_rekeyed_by_user(114, user_id, 2),
totals_for_user(114, user_id, 1),
totals_rekeyed_by_user(114, user_id, 1),
totals_for_user(116, user_id, 1),
totals_rekeyed_by_user(116, user_id, 1),
totals_for_user(116, user_id, 2),
totals_rekeyed_by_user(116, user_id, 2),
totals_for_user(117, user_id, 0),
totals_rekeyed_by_user(117, user_id, 0),
totals_for_user(119, user_id, 0),
totals_rekeyed_by_user(119, user_id, 0),
totals_for_user(118, user_id, 0),
totals_rekeyed_by_user(118, user_id, 0)
	FROM users 
WHERE (totals_for_user(114, user_id, 2) +
totals_rekeyed_by_user(114, user_id, 2) +
totals_for_user(114, user_id, 1) +
totals_rekeyed_by_user(114, user_id, 1) +
totals_for_user(116, user_id, 1) +
totals_rekeyed_by_user(116, user_id, 1) +
totals_for_user(116, user_id, 2) +
totals_rekeyed_by_user(116, user_id, 2) +
totals_for_user(117, user_id, 0) +
totals_rekeyed_by_user(117, user_id, 0) +
totals_for_user(119, user_id, 0) +
totals_rekeyed_by_user(119, user_id, 0) +
totals_for_user(118, user_id, 0) +
totals_rekeyed_by_user(118, user_id, 0)) > 0 
INTO OUTFILE '/tmp/user_stats.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';



