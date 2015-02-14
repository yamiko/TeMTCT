SELECT 
'Form type',
'MR',
'IR',
'M PNC'                          ,
'I PNC'                          ,
'DNA-PCR'                        ,
'TL'                          ,
'SE'         
UNION
SELECT 
'Keyed',
SUM(totals_for_user(114, user_id, 2)),
SUM(totals_for_user(114, user_id, 1)),
SUM(totals_for_user(116, user_id, 1)),
SUM(totals_for_user(116, user_id, 2)),
SUM(totals_for_user(117, user_id, 0)),
SUM(totals_for_user(119, user_id, 0)),
SUM(totals_for_user(118, user_id, 0))
	FROM users 
UNION
SELECT
'Rekeyed',
SUM(totals_rekeyed_by_user(114, user_id, 2)),
SUM(totals_rekeyed_by_user(114, user_id, 1)),
SUM(totals_rekeyed_by_user(116, user_id, 1)),
SUM(totals_rekeyed_by_user(116, user_id, 2)),
SUM(totals_rekeyed_by_user(117, user_id, 0)),
SUM(totals_rekeyed_by_user(119, user_id, 0)),
SUM(totals_rekeyed_by_user(118, user_id, 0))
	FROM users 
INTO OUTFILE '/tmp/user_stats_summary.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';



