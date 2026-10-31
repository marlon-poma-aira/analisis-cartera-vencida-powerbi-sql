use Cobranza

SELECT *
FROM fact_facturas

SELECT *
FROM dim_asesores

SELECT *
FROM fact_pagos


--Crear View's
-- Dias de atraso
CREATE VIEW vw_dias_atraso AS
SELECT c.cliente, f.nro_factura, DATEDIFF(DAY,f.fecha_vencimiento,'2026-09-30') AS dias_atraso
FROM dim_clientes c
JOIN fact_facturas f ON c.id_cliente=f.id_cliente


-- Saldo por factura
CREATE VIEW vw_saldo_factura AS
	SELECT	
		f.id_factura, 
		f.nro_factura,
		c.id_cliente, 
		c.cliente, 
		ISNULL((f.monto_total - p.monto_pagado),0) AS saldo_factura
FROM fact_facturas f
LEFT JOIN fact_pagos p ON f.id_factura=p.id_factura
JOIN dim_clientes c ON f.id_cliente=c.id_cliente

-- Tramo por antiguedad

CREATE VIEW vw_tramo_antiguedad AS
SELECT c.cliente, f.nro_factura, DATEDIFF(DAY,f.fecha_vencimiento,'2026-09-30') AS dias_atraso, 
CASE 
WHEN DATEDIFF(DAY,f.fecha_vencimiento,'2026-09-30') > 90 THEN '+90 dias'
WHEN DATEDIFF(DAY,f.fecha_vencimiento,'2026-09-30') > 60 THEN '61-90'
WHEN DATEDIFF(DAY,f.fecha_vencimiento,'2026-09-30') > 30 THEN '31-60'
WHEN DATEDIFF(DAY,f.fecha_vencimiento,'2026-09-30') >= 0 THEN '0-31'
ELSE 'Vigente'
END AS tramo_de_antiguedad
FROM fact_facturas f
JOIN dim_clientes c ON f.id_cliente=c.id_cliente

-- Crear una unica tabla con las vistas incluidas
ALTER VIEW vw_cartera AS
SELECT	
		f.id_factura, 
		f.nro_factura,
		c.id_cliente, 
		c.cliente,
		a.id_asesor,
		f.fecha_emision,
        f.fecha_vencimiento,
		f.monto_total,
		ISNULL(p.monto_pagado,0) AS monto_pagado,
		(f.monto_total - ISNULL(p.monto_pagado,0)) AS saldo_factura,
		MAX(p.fecha_pago) AS ultima_fecha_pago,
		CAST('2026-09-30' AS date) AS fecha_corte,
		CASE WHEN fecha_vencimiento < CAST('2026-09-30' AS date) AND (f.monto_total - ISNULL(p.monto_pagado,0)) >0 
		THEN DATEDIFF(DAY,fecha_vencimiento,'2026-09-30') 
		ELSE 0
		END AS dias_atraso
FROM fact_facturas f
LEFT JOIN fact_pagos p ON f.id_factura=p.id_factura
JOIN dim_clientes c ON f.id_cliente=c.id_cliente
JOIN dim_asesores a ON c.id_asesor=a.id_asesor
GROUP BY f.id_factura, 
		f.nro_factura,
		c.id_cliente, 
		c.cliente,
		a.id_asesor,
		f.fecha_emision,
        f.fecha_vencimiento,
		f.monto_total,p.monto_pagado
GO

ALTER VIEW vw_cartera_aging AS
SELECT v.*,
	CASE WHEN v.saldo_factura <= 0 THEN 'Pagada'
		 WHEN v.dias_atraso = 0 THEN 'Vigente'
		 WHEN v.dias_atraso <= 30 THEN '1-30 dias'
         WHEN v.dias_atraso <= 60  THEN '31-60 dias'
         WHEN v.dias_atraso <= 90  THEN '61-90 dias'
		 ELSE '+90 dias' 
	END AS tramo_antiguedad,
	CASE WHEN v.saldo_factura <= 0 THEN 0
		 WHEN v.dias_atraso = 0 THEN 1
		 WHEN v.dias_atraso <= 30 THEN 2
         WHEN v.dias_atraso <= 60  THEN 3
         WHEN v.dias_atraso <= 90  THEN 4
		 ELSE 5
	END AS orden_tramo
FROM vw_cartera v


SELECT *
FROM vw_cartera_aging

SELECT SUM(saldo_factura) FROM vw_cartera_aging