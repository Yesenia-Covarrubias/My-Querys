WITH clientes AS (SELECT 
rp.id,
rp.trade_name,
rp."name",
rp.vat  AS RFC,
rp.segment,
rp.phone,
rp.street,
rp.email,
rp2."name" AS vendedor,
string_agg(dd."name", ', ') AS Division,
rp.parent_id
FROM 
	res_partner rp
LEFT JOIN
	res_partner_res_users_rel rprur ON rprur.res_partner_id = rp.id 
LEFT JOIN 
	res_users ru ON ru.id = rprur.res_users_id
LEFT JOIN 
	res_partner rp2 ON rp2.id = ru.partner_id 
LEFT JOIN 
	division_division_res_partner_rel ddrpr ON ddrpr.res_partner_id = rp.id
LEFT JOIN 
	division_division dd ON dd.id = ddrpr.division_division_id
WHERE
	rp.active IS TRUE 
AND ru.active IS TRUE
AND rp.customer IS TRUE
AND rp."name" IS NOT NULL
AND rp.parent_id IS NULL
GROUP BY rp.id, rp2.id),
--
conteo AS  (SELECT 
clientes."name", 
clientes.id, 
COUNT(*) AS Conteo 
FROM clientes 
GROUP BY clientes.id, clientes."name" 
HAVING count(*)>1
ORDER BY clientes.id ASC)
--
SELECT
cl."name",
cl.id,
con.conteo,
cl.vendedor,
cl.segment,
cl.division
FROM conteo con 
LEFT JOIN clientes cl ON cl.id = con.id
