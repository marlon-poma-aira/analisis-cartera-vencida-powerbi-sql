# Dashboard de Cobranza y Antigüedad de Deuda

**Power BI · SQL Server · Python** — proyecto de portafolio con datos sintéticos.

Dashboard de tres páginas que responde tres preguntas de un área de cobranza: **¿cuánto nos deben y qué tan grave es?**, **¿a quién cobrar primero?** y **¿quién cobra mejor y quién paga a tiempo?**

> Todos los datos son sintéticos: se generaron con un script de Python creado con ayuda de IA y no corresponden a ninguna empresa real.

## Capturas

| Resumen ejecutivo | Riesgo de clientes | Gestión de cobranza |
|---|---|---|
| <img width="892" height="503" alt="image" src="https://github.com/user-attachments/assets/1e22eee8-5b0b-4dfa-875c-0f82d384da32" />| <img width="894" height="501" alt="image" src="https://github.com/user-attachments/assets/b0d67340-e547-4258-a429-e9861652f6ec" />| <img width="889" height="498" alt="image" src="https://github.com/user-attachments/assets/77943111-548b-4fc3-9861-7b7b2a63aa39" />|

## Hallazgos principales (cartera al 30/09/2026)

- **Deuda total de S/ 1,473,485** en 271 facturas pendientes, repartida entre 56 de los 60 clientes.
- **El 75.8% de la deuda está vencida** (S/ 1,116,448).
- **El 64% de la deuda supera los 90 días** (S/ 947,715 en 177 facturas); el atraso máximo es de 971 días.
- **La deuda no está concentrada:** el mayor deudor representa 6.0% y los 5 mayores suman 27.7%. El problema no es a quién cobrar, sino cuánto tiempo se deja envejecer la cartera.
- **DSO de 157 días:** la cobranza es lenta frente a un plazo de crédito de 30 a 60 días.
- **Solo el 36.7% de las facturas se pagó a tiempo**, con un retraso promedio de 11.3 días. El sector Tecnología paga más tarde (25.7 días de promedio).
- **Por asesor:** Diego Cruz tiene la mayor deuda (S/ 327 mil, 68% vencida); María Paredes (93.5%) y Ana Torres (88.1%) tienen la cartera más vencida; Jorge Salas la más sana (40.3%).

### Recomendaciones que se desprenden del análisis

1. Priorizar la gestión de las 177 facturas con más de 90 días, que concentran dos tercios de la deuda.
2. Revisar la política de crédito del sector Tecnología, que paga más tarde que el resto.
3. Revisar la cartera de los asesores con más del 85% vencido.

## Herramientas

| Herramienta | Uso en el proyecto |
|---|---|
| **Python** (pandas, numpy) | Script que genera los datos sintéticos de forma reproducible (semilla fija), creado con ayuda de IA |
| **SQL Server** | Modelo relacional, `LEFT JOIN`, cálculo de saldos y días de atraso, clasificación en tramos con `CASE`, vistas |
| **Power BI** | Modelo en estrella, medidas DAX, tabla de calendario, 3 páginas con segmentadores sincronizados |

## Datos

| Tabla | Contenido | Filas |
|---|---|---|
| `dim_clientes` | Cliente, sector, departamento, asesor, condición de pago | 60 |
| `dim_asesores` | Asesor y correo | 8 |
| `fact_facturas` | Facturas de enero 2024 a septiembre 2026 (con IGV) | 1,619 |
| `fact_pagos` | Pagos totales y parciales | 1,384 |

La **fecha de corte** del análisis es el 30/09/2026.

## Modelo de datos

La vista `vw_cartera` deja **una fila por factura** con su saldo, y `vw_cartera_aging` agrega los tramos de antigüedad.

```sql
-- Saldo: se conservan las facturas sin pagos (LEFT JOIN) y se suman los pagos por factura
saldo_factura = monto_total - ISNULL(total_pagado, 0)

-- Tramos de antigüedad (solo facturas con saldo)
CASE
    WHEN saldo_factura <= 0 THEN 'Pagada'
    WHEN dias_atraso = 0    THEN 'Vigente'
    WHEN dias_atraso <= 30  THEN '1-30 dias'
    WHEN dias_atraso <= 60  THEN '31-60 dias'
    WHEN dias_atraso <= 90  THEN '61-90 dias'
    ELSE '+90 dias'
END AS tramo_antiguedad
```

En Power BI, `vw_cartera_aging` es la tabla central, relacionada con `dim_clientes`, `dim_asesores`, `fact_pagos` y una tabla `dim_calendario`.

## Medidas DAX principales

```dax
Deuda Total = SUM(vw_cartera_aging[saldo_factura])

Deuda Vencida = CALCULATE([Deuda Total], vw_cartera_aging[dias_atraso] > 0)

% Cartera Vencida = DIVIDE([Deuda Vencida], [Deuda Total])

DSO = DIVIDE([Deuda Total], [Facturación 90d]) * 90

% Pago Puntual = DIVIDE([Facturas Pagadas a Tiempo], [Facturas Pagadas])
```

## Estructura del repositorio

```
analisis-cartera-vencida-powerbi-sql/
├── data/                  # CSV generados (dim_clientes, dim_asesores, fact_facturas, fact_pagos)
├── python/
│   └── generar_datos_cobranza.py
├── sql/
│   └── vistas_cobranza.sql   # vw_cartera y vw_cartera_aging
├── powerbi/
│   └── Cobranza.pbix
├── images/                # capturas del dashboard
└── README.md
```

## Cómo reproducirlo

1. Ejecuta `python/generar_datos_cobranza.py` para crear los 4 CSV (requiere `pandas` y `numpy`).
2. En SQL Server, crea la base `Cobranza` e importa los CSV con *Importar archivo plano* (fechas como `date`, montos como `decimal(12,2)`).
3. Ejecuta `sql/vistas_cobranza.sql` para crear las vistas.
4. Abre `powerbi/Cobranza.pbix` y, en *Transformar datos → Configuración de origen de datos*, apunta al nombre de tu servidor.

## Qué demuestra este proyecto

- **SQL:** uniones externas, agregaciones, `CASE`, vistas y validación de cifras contra el origen.
- **Power BI:** modelado en estrella, medidas DAX, diseño de un informe de varias páginas y storytelling con datos.

## Próximos pasos

- Seguridad por fila (RLS) para que cada asesor vea solo su cartera.
- Actualización automática de los datos.

## Autor

**Marlon Poma Aira** — [LinkedIn](https://linkedin.com/in/marlon-poma-aira)
