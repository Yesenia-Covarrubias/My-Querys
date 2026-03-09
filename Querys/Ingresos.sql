--INGRESOS DE MATERIAL A ALMACEN DEL AÑO EN CURSO

WITH 
	users AS (
	SELECT 
		ru.id AS user_id,
		rp.name AS user_name
	FROM 
		res_users ru
		INNER JOIN res_partner rp ON rp.id = ru.partner_id 
		)
SELECT
	sm.reference, 
	pp.default_code,
	uu.name AS uom,
	sm.product_qty,
	CASE WHEN po.currency_id = 33 THEN (pol.price_unit / po.custom_rate) ELSE pol.price_unit END AS price_unit_usd,
	--pol.price_unit AS precio_unit_monedapo,
	--rcc.name AS moneda_po,
	rp.name AS proveedor,
	(sm.date - INTERVAL '6 hours')::date AS fecha_ingreso,
	(pol.date_planned - INTERVAL '6 hours')::date AS fecha_prevista,
	sw.name AS almacen,
	po.name AS po,
	pol.id AS pol_id,
	us2.user_name AS comprador,
	CASE WHEN pol.qty_received < pol.product_qty THEN 'backorder' ELSE 'completa' END AS filtro_linea 
FROM
	stock_move sm 
	INNER JOIN product_product pp ON pp.id = sm.product_id 
	LEFT JOIN product_template pt ON pt.id = pp.product_tmpl_id 
	LEFT JOIN res_partner rp ON rp.id = pt.default_seller_id 
	LEFT JOIN stock_picking_type spt ON spt.id = sm.picking_type_id
	LEFT JOIN stock_warehouse sw ON sw.id = spt.warehouse_id 
	LEFT JOIN purchase_order_line pol ON pol.id = sm.purchase_line_id 
	LEFT JOIN purchase_order po ON po.id = pol.order_id
	LEFT JOIN purchase_sale_line_rel pslr ON pslr.purchase_line_id = pol.id
	LEFT JOIN sale_order_line sol ON sol.id = pslr.sale_line_id 
	LEFT JOIN sale_order so ON so.id = sol.order_id 
	LEFT JOIN uom_uom uu ON uu.id = pol.product_uom 
	LEFT JOIN users us2 ON us2.user_id = po.user_id 
	LEFT JOIN res_currency rcc ON rcc.id = po.currency_id
WHERE 
	sm.location_id = 8
	AND sm.state = 'done'
	AND sm.date >= '2025-10-01'
ORDER BY sm.date DESC
 
