WITH 
	anios_industriales AS (
				SELECT
					CASE 
						WHEN extract(month from current_date) >= 10 
						THEN date_trunc('year', current_date) + interval '9 months'
						ELSE date_trunc('year', current_date - interval '1 year') + interval '9 months'
					END -- interval '1 year' 
					AS fecha_inicio_industrial
					), 
	users AS (
			SELECT
				ru.id AS user_id, --esta columna es el nombre del usuario 
				rp.name AS user_name
			FROM
				res_users ru
				INNER JOIN res_partner rp ON rp.id = ru.partner_id 
				),
	ordenes AS (
	SELECT
			-- LINEAS INFORMACION SO
		so.id AS id_so,
		sol.id AS id_linea_so,
		so.name AS SO,
		rp2.id AS id_cliente,
		rp2.name AS cliente,
		rp2.financing_days AS dias_financiamiento_cliente,
		rp2.segment AS segmento_cliente,
		sw.name AS almacen,
		ct.name AS equipo_venta,
		unaccent(
		CASE
			WHEN ct.name IS NOT NULL AND split_part(upper(ct.name), ' ', 1) <> '' THEN split_part(upper(ct.name), ' ', 1)
			WHEN sw.name IS NOT NULL THEN upper(CASE 
													WHEN sw.name = '075C FUNDICION' THEN 'HERMOSILLO'
													WHEN sw.name = 'FORJAS' THEN 'AGUASCALIENTES'
													WHEN sw.name = 'CANANEA' THEN 'NOGALES'
													WHEN sw.name = 'MEX FORD' THEN 'MEXICO'
													WHEN sw.name = 'MAXION' THEN 'MEXICO'
													WHEN sw.name = 'TJ FRONTERA' THEN 'TIJUANA'
													WHEN sw.name = 'JZ FRONTERA' THEN 'JUAREZ'
													WHEN sw.name = 'NO USAR - AGUASCALIENTES' THEN 'AGUASCALIENTES'
													WHEN sw.name = 'PINOS ALTOS' THEN 'CHIHUAHUA'
													WHEN sw.name = 'CONS. CG' THEN 'MEXICO'
													ELSE sw.name
												END)
			ELSE 'NOIDENTIFICADO'
		END) AS sucursal, 
		dd.name AS division,
			-- LINEAS DE FECHAS
		(so.create_date - INTERVAL '6 hours')::date AS fecha_creacion,
		so.validity_date::date AS fecha_validez,
		(so.partner_order_date - INTERVAL '6 hours')::date AS fecha_orden_cliente,
		(so.reception_partner_order_date - INTERVAL '6 hours')::date AS fecha_recepcion_orden_cliente,
		(so.confirmation_date - INTERVAL '6 hours')::date AS fecha_confirmacion,
		sol.required_date::date AS fecha_requerida,
		sol.shipment_date::date AS fecha_entrega,
		(so.date_lost_reason_apply - INTERVAL '6 hours')::date AS fecha_razon_perdida,
		date((SELECT MIN(COALESCE(sm2.assigned_date, sm.assigned_date)) AS fecha_asignacion 
			FROM 
				sale_order_line soll
				INNER JOIN stock_move sm ON sm.sale_line_id = soll.id
				INNER JOIN stock_move_move_rel smmr ON smmr.move_dest_id = sm.id
				INNER JOIN stock_move sm2 ON sm2.id = smmr.move_orig_id
			WHERE 
				soll.id = sol.id
	)) AS fecha_reserva,
		(CASE 
			WHEN so.state IN ('sale', 'done') THEN so.confirmation_date
			ELSE so.create_date
		END - INTERVAL '6 hours')::date AS fecha_hit_rate, 
		so.client_order_ref AS referencia_cliente,
		ppl.name AS tarifa,
		so.custom_rate AS tasa_cambio_so,
		apt."name" AS terminos,
		CASE 
			WHEN sol.price_unit >= 999999999::numeric THEN 'error'::text
			ELSE 'ok'
		END AS error_precio,
		CASE 
			WHEN so.picking_policy = 'direct' THEN 'Entrega parcial'
			WHEN so.picking_policy = 'one' THEN 'Entrega completa'
			WHEN so.picking_policy = 'one_per_product' THEN 'Entrega linea completa'
		END AS politica_entrega,
		CASE 
			WHEN so.invoice_policy = 'order' THEN 'Cantidades pedidas'
			WHEN so.invoice_policy = 'delivery' THEN 'Cantidades entregadas'
		END AS politica_facturacion,
		CASE 
			WHEN so.state = 'draft' THEN 'Presupuesto'
			WHEN so.state = 'sent' THEN 'Presupuesto enviado'
			WHEN so.state = 'sale' THEN 'Pedido de venta'
			WHEN so.state = 'done' THEN 'Bloqueado'
			WHEN so.state = 'cancel' THEN 'Cancelado'
		END AS estado,
		CASE 
			WHEN so.state IN ('sale', 'done') THEN 'Ganada'
			WHEN so.state = 'cancel' THEN 'Perdida'
			WHEN so.state = 'draft' THEN 'Presupuesto'
			WHEN so.state = 'sent' THEN 'Presupuesto enviado'
			ELSE 'Otro'
		END AS estado_final,
		CASE 
			WHEN pp.default_code LIKE '%ANTICIPO%' THEN 'yes' ELSE 'no'
		END AS es_anticipo,
		pt.default_seller_id AS id_proveedor,
		rp.name AS proveedor,
		CASE WHEN pt.default_seller_id = 1940 THEN 'RAM'::text ELSE 'NORAM'::text END AS ramnoram,
		pp.default_code AS producto,
		rs.name AS sbu,
		uu.name AS udm,
		pp.global_rotation AS rotacion_global,
		sol.product_uom_qty AS cantidad_pedida,
		sol.qty_reserved AS cantidad_reservada,
		sol.qty_reserved_transit AS cantidad_reservada_transito,
		sol.qty_delivered AS cantidad_entregada,
		sol.qty_invoiced AS cantidad_facturada,
		COALESCE (sol.product_uom_qty-(sol.qty_invoiced + sol.qty_reserved + qty_reserved_transit),0) AS qty_pendiente_facturar,
		so.currency_id,
		rc.name AS moneda,
		sol.price_unit AS precio_unitario,
		sol.price_subtotal AS precio_subtotal,
		CASE WHEN so.currency_id = 33 THEN sol.price_unit / so.custom_rate ELSE sol.price_unit END AS precio_unitario_usd,
		CASE 
			WHEN so.currency_id = 33 THEN 
				CASE 
					WHEN so.custom_rate IS NULL OR so.custom_rate = 0 THEN sol.price_subtotal * rcr.rate
					ELSE sol.price_subtotal / so.custom_rate
				END
			ELSE sol.price_subtotal END AS precio_subtotal_usd,
		(sol.qty_reserved + qty_reserved_transit) AS cantidad_reservada_total,
		cu.user_name AS creado_por,
		ue.user_name AS vendedor_externo,
		ui.user_name AS vendedor_interno,
		uc.user_name AS comercial,
		rpi.name AS sector_clave,
		rpi.full_name AS sector_nombre,
		solr.name AS razon_perdida,
		so.lost_reason_id AS id_razon_perdida,
		ca."number" AS agreement_number,
		CASE 
			WHEN sol.identified_cost_sale_type = 1 THEN 'Desviacion'::text
			WHEN sol.identified_cost_sale_type = 2 THEN 'Acuerdo'::text
			WHEN sol.identified_cost_sale_type = 3 THEN 'Promedio'::text
			WHEN sol.identified_cost_sale_type = 4 THEN 'Reposicion'::text
			ELSE NULL::text
		END AS tipo_costo,
		so.is_big_order AS es_big_order,
		COALESCE(po.name, 'NA') AS PO,
		pol.id  AS linea_po
	FROM
		sale_order so
		LEFT JOIN sale_order_line sol ON sol.order_id = so.id
		LEFT JOIN stock_warehouse sw ON sw.id = so.warehouse_id
		LEFT JOIN crm_team ct ON ct.id = so.team_id
		LEFT JOIN product_pricelist ppl ON ppl.id = so.pricelist_id
		LEFT JOIN division_division dd ON dd.id = so.division_id
		LEFT JOIN product_product pp ON pp.id = sol.product_id
		LEFT JOIN product_template pt ON pt.id = pp.product_tmpl_id
		LEFT JOIN uom_uom uu ON uu.id = pt.uom_id
		LEFT JOIN res_sbu rs ON rs.id = pt.sbu_id
		LEFT JOIN res_partner rp ON rp.id = pt.default_seller_id
		LEFT JOIN res_currency rc ON rc.id = so.currency_id
		LEFT JOIN res_partner rp2 ON rp2.id = so.partner_id
		LEFT JOIN account_payment_term apt ON apt.id = so.payment_term_id
		LEFT JOIN res_partner_industry rpi ON rpi.id = rp2.industry_id
		LEFT JOIN sale_order_lostreasons solr ON solr.id = so.lost_reason_id
		LEFT JOIN res_currency_rate rcr ON rcr."name"::date = so.confirmation_date::date AND rcr.currency_id = 2
		LEFT JOIN product_pricelist_item ppi ON ppi.id = sol.base_pricelist_item_id 
		LEFT JOIN customer_agreement_line cal ON cal.item_id = ppi.id 
		LEFT JOIN customer_agreement ca ON ca.id = cal.agreement_id
		LEFT JOIN users cu ON cu.user_id = so.create_uid
		LEFT JOIN users ue ON ue.user_id = so.external_salesperson_id
		LEFT JOIN users ui ON ui.user_id = so.internal_user_id 
		LEFT JOIN users uc ON uc.user_id = so.user_id
		LEFT JOIN purchase_sale_line_rel pslr ON pslr.sale_line_id = sol.id
		LEFT JOIN purchase_order_line pol ON pol.id = pslr.purchase_line_id
		LEFT JOIN purchase_order po ON po.id = pol.order_id
		WHERE
		so.state IN ('sale', 'done')
		AND pp.default_code NOT LIKE '%MANIOBRA%'
		)
SELECT 
	so.id_so,
	so.id_linea_so,
	so.so,
	so.id_cliente,
	so.cliente,
	so.segmento_cliente,
	so.almacen,
	so.equipo_venta,
	so.sucursal,
	so.fecha_creacion,
	so.fecha_validez,
	so.fecha_orden_cliente,
	so.fecha_recepcion_orden_cliente,
	so.fecha_confirmacion,
	so.fecha_entrega,
	so.politica_entrega,
	so.politica_facturacion,
	so.estado,
	so.estado_final,
	so.proveedor,
	so.ramnoram,
	so.producto,
	so.sbu,
	so.udm,
	so.rotacion_global,
	so.cantidad_pedida,
	so.cantidad_reservada,
	so.cantidad_reservada_transito,
	so.cantidad_entregada,
	so.cantidad_facturada,
	so.qty_pendiente_facturar,
	so.moneda,
	so.precio_unitario,
	so.precio_subtotal,
	so.precio_unitario_usd,
	so.precio_subtotal_usd,
	so.creado_por,
	so.vendedor_externo,
	so.vendedor_interno,
	so.razon_perdida,
	so.tipo_costo,
	so.es_big_order,
	so.po,
	so.linea_po
FROM
	ordenes so 
WHERE 
	--so.fecha_creacion >= '2024-01-01' --(SELECT fecha_inicio_industrial FROM anios_industriales) --modificar fechas de minimo de regsitro en with anios_industriales
	NOT (so.estado = 'Cancelado' AND coalesce(so.id_razon_perdida, 0) IN (6,8,17)) --Omite cotizaciones canceladas y siguientes razones de perdida: ("RECOTIZACION", "COTIZACION DUPLICADA", "CORRECCION DE SO"), consideradas "ERRORES" y alteral los montos reales de cotizacion
	AND so.error_precio = 'ok'
	AND so.qty_pendiente_facturar >0 
	
