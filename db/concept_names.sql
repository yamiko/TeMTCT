SELECT DISTINCT o.concept_id, cn.name FROM obs o LEFT JOIN concept_name cn ON o.concept_id = cn.concept_id AND cn.concept_name_type = 'FULLY_SPECIFIED' ORDER BY cn.name;

