SELECT 
	ht.id,
	ht."name",
	ht2."name" AS equipo_asistencia,
	rp."name" AS asignada_a,
	rp2."name" AS solicitante,
	htt."name"AS tipo_vale,
	ht.working_days,
	hs.name AS estado,
	(ht.create_date - INTERVAL '6 hours') AS fecha_creacion,
	(ht.assign_date - INTERVAL '6 hours') AS fecha_asignacion,
	(ht.close_date - INTERVAL '6 hours') AS fecha_cierre,
	ht.close_hours,
	ht.partner_name,
	ROUND (((EXTRACT (EPOCH FROM (ht.close_date - INTERVAL '6 hours'))) - (EXTRACT (epoch FROM (ht.assign_date - INTERVAL '6 hours')))) / 3600,4) AS horas_trabajadas,
	CASE 
	 WHEN ht.rating_last_value = 0 THEN 'no calificado'
	 WHEN ht.rating_last_value = 1 THEN 'muy insatisfecho'
	 WHEN ht.rating_last_value = 5 THEN 'insatisfecho'
	 WHEN ht.rating_last_value = 10 THEN 'satisfecho'
	 END AS calificacion
FROM 
	helpdesk_ticket ht 
LEFT JOIN helpdesk_team ht2 ON ht2.id = ht.team_id
LEFT JOIN res_users ru ON ru.id = ht.user_id
LEFT JOIN res_partner rp ON rp.id =ru.partner_id
LEFT JOIN res_partner rp2 ON rp2.id = ht.partner_id
LEFT JOIN helpdesk_ticket_type htt ON htt.id =ht.ticket_type_id
LEFT JOIN helpdesk_stage hs ON hs.id =ht.stage_id
--LEFT JOIN rating_rating rr ON rr.res_id  = ht.id 
WHERE
ht.team_id IN (38,30,28)
