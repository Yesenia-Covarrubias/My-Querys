SELECT 
rp.id,
rp.trade_name,
rp."name",
rp.vat  AS RFC,
rp.segment,
rp.phone,
rp.street,
rp.email,
dd."name" AS Division,
rp2."name" AS vendedor
FROM 
	res_partner rp
LEFT JOIN
	res_partner_res_users_rel rprur ON rprur.res_partner_id = rp.id 
LEFT JOIN 
	res_users ru ON ru.id = rprur.res_users_id
LEFT JOIN 
	res_partner rp2 ON rp2.id = ru.partner_id 
LEFT JOIN 
	division_division dd ON dd.id = rp.division_id 
WHERE
	rp.active IS TRUE
AND 
	ru.active IS TRUE
AND 
	rp.customer IS TRUE
AND 
	rp.trade_name  = 'CLIMAS DE LA FRONTERA, S.C.'
