# Capa Gold
 
## ¿Qué hace esta capa?
 
La capa Gold toma los datos limpios y normalizados de Silver y los transforma en tablas analíticas listas para responder las 24 preguntas de negocio del proyecto. Cada modelo Gold tiene un grain claramente definido y métricas calculadas con lógica de negocio explícita.
 
---
 
## Arquitectura — 8 modelos Gold
 
| Modelo | Grain | Preguntas |
|--------|-------|-----------|
| `gold_customers` | Una fila por cliente | Q9, Q10, Q11, Q12, Q13, Q14 |
| `gold_transactions` | Una fila por transacción | Q15, Q16, Q17, Q18, Q19 |
| `gold_revenue` | Una fila por segmento + canal + país | Q1, Q3 |
| `gold_risk` | Una fila por cliente-préstamo | Q4, Q5, Q6, Q7, Q8, Q9 |
| `gold_engagement` | Una fila por cliente | Q20, Q21 |
| `gold_accounts` | Una fila por cuenta | Q2, Q22 |
| `gold_loans` | Una fila por préstamo | Q8, Q23 |
| `gold_products` | Una fila por cliente | Q24 |
 
---
 
## Definiciones de negocio
 
Antes de explicar cada pregunta, documentamos las definiciones que usamos en todos los modelos:
 
**Revenue** — transacciones completadas (`status = 'completed'`) de tipo `payment` o `fee`. No incluimos depósitos ni transferencias porque no representan ingreso para la institución.
 
**Delinquent** — un préstamo es delinquente cuando `status IN ('delinquent', 'default')` OR `days_past_due > 0`. La condición OR cubre casos donde el status aún no fue actualizado pero ya hay días de mora.
 
**Interest income** — `outstanding_balance * interest_rate / 100` aplicado solo a préstamos con `status = 'current'`. Los préstamos `delinquent`, `default` y `paid_off` no generan interés computable.
 
**Transacción internacional** — cuando la moneda de la transacción no coincide con la moneda local del país del cliente: CO→COP, UY→UYU, AR→ARS, MX→MXN, CL→CLP, PE→PEN, BR→BRL. USD y EUR siempre son internacionales para todos los países.
 
**Conversión a USD** — tipos de cambio aproximados a mayo 2026: ARS=0.001, BRL=0.18, CLP=0.001, COP=0.00024, MXN=0.05, PEN=0.27, UYU=0.025, EUR=1.08. Los montos en USD se mantienen con factor 1.0. Esta conversión es aproximada — en producción usaríamos una tabla de tipos de cambio actualizada diariamente.
 
**Age buckets** — 18-25, 26-35, 36-45, 46-55, 56-65, 65+
 
**Risk buckets** — low (0-25), medium (26-50), high (51-75), critical (76-100)
 
**Credit score buckets** — poor (300-579), fair (580-669), good (670-739), very_good (740-799), exceptional (800-850). Rango según especificación del PDF.
 
**DPD buckets** — current (0 días), 1-30 días, 31-60 días, 61-90 días, 90+ días
 
---
 
## Nota sobre préstamos paid_off
 
El dataset incluye préstamos con status `paid_off`. Confirmamos que estos préstamos tienen `outstanding_balance` distinto de NULL pero representan deuda ya cancelada. Por este motivo el cálculo de `interest_income_usd` excluye explícitamente los préstamos `paid_off` — solo los préstamos `current` generan interés computable. Los préstamos `delinquent` y `default` tampoco generan interés ya que no están cumpliendo con sus pagos.
 
---
 
## Las 24 preguntas de negocio
 
### Revenue & Profitability
 
**Q1 — ¿Cuál es el revenue promedio por cliente por segmento?**
 
Modelo: `gold_revenue`
 
Calculamos el revenue como la suma de montos de transacciones completadas de tipo `payment` y `fee`, agrupadas por segmento. Dividimos por la cantidad de clientes únicos en ese segmento para obtener el promedio.
 
Resultado: SME lidera en revenue promedio por cliente, seguido de private_banking, retail y premium. La diferencia entre segmentos es pequeña (~10%) lo que sugiere que la actividad transaccional es similar entre segmentos.
 
Supuesto: usamos transacciones completadas de tipo payment/fee como proxy de revenue. En producción, revenue incluiría también comisiones, spreads y productos financieros.
 
---
 
**Q2 — ¿Cuáles son los balances totales de cuentas por país?**
 
Modelo: `gold_accounts` (campo `balance_usd`)
 
Los balances se convierten a USD para comparabilidad entre países. Sin conversión, CO domina por el volumen de COP que tiene mucho menos valor que USD.
 
Resultado: Perú lidera con $642M, seguido de Uruguay ($608M), México ($600M), Colombia ($592M), Argentina ($594M), Brasil ($583M) y Chile ($541M). Total: $4.161M USD.
 
Supuesto: los balances en moneda local se convierten a USD con tipos de cambio aproximados a mayo 2026. La comparación entre países es indicativa, no exacta.
 
Nota de diseño: el campo `total_balance_usd` fue removido de `gold_revenue` porque su grain (segmento + canal + país) causaba multiplicación del balance al agregar por país en PowerBI. Para consultas de balance por país se debe usar `gold_accounts` directamente.
 
---
 
**Q3 — ¿Cuál es el revenue por canal de transacción?**
 
Modelo: `gold_revenue`
 
Revenue agrupado por canal (mobile, web, atm, branch, pos). La distribución entre canales es bastante pareja — branch y pos lideran con ~$36M cada uno, seguidos de mobile, web y atm con ~$33-34M.
 
---
 
**Q4 — ¿Cuál es el interest income por tipo de préstamo?**
 
Modelo: `gold_loans` (campo `interest_income_usd`) y `gold_risk`
 
`interest_income_usd = outstanding_balance_usd * interest_rate / 100` para préstamos con status `current` únicamente. Los préstamos `paid_off`, `delinquent` y `default` tienen `interest_income_usd = 0`.
 
Total interest income: $44M USD anuales estimados sobre el portafolio actual de préstamos corrientes.
 
Consideración: para ver el desglose por tipo de préstamo en el dashboard, se puede filtrar el gráfico "Loan Portfolio by Type" por tipo y la tarjeta KPI se actualiza automáticamente.
 
---
 
### Risk & Credit
 
**Q5 — ¿Cuál es la tasa de delinquency por segmento?**
 
Modelo: `gold_risk`
 
Calculamos el porcentaje de registros con `is_delinquent = true` sobre el total, agrupado por segmento de cliente.
 
Resultado: private_banking tiene la tasa más alta (43.15%), sme la más baja (41.96%). La diferencia entre segmentos es pequeña — la delinquency es alta en todos los segmentos (~42%).
 
Consideración: el grain de `gold_risk` es cliente-préstamo (un cliente con 3 préstamos aparece 3 veces). Esto significa que la tasa refleja la proporción de préstamos delinquentes, no de clientes delinquentes.
 
---
 
**Q6 — ¿Cuál es la distribución de credit scores?**
 
Modelo: `gold_risk`
 
Agrupamos por bucket de credit score. Resultado: distribución perfectamente uniforme del 20% en cada bucket (poor, fair, good, very_good, exceptional). Esto refleja el diseño sintético del dataset — en un dataset real esperaríamos mayor concentración en los buckets medios (fair y good).
 
---
 
**Q7 — ¿Hay relación entre utilización de crédito y delinquency?**
 
Modelo: `gold_risk`
 
Agrupamos por `utilization_bucket` y calculamos la tasa de delinquency. Resultado: a mayor utilización, menor tasa de delinquency (very_high: ~43% vs moderate: ~45%).
 
Interpretación: los clientes con alta utilización están financieramente activos y mantienen sus pagos. Los clientes con utilización moderada pueden tener más préstamos en mora relativa. Esta relación contraintuitiva es válida en contextos fintech LATAM donde los clientes más activos crediticiamente tienden a ser más disciplinados en sus pagos.
 
---
 
**Q8 — ¿Cuál es la distribución de days past due por tipo de préstamo?**
 
Modelo: `gold_loans` (campo `dpd_bucket`)
 
Agrupamos por loan_type y dpd_bucket. El 50.48% de los préstamos están al día (current). El 24.66% tiene entre 31 y 60 días de mora — este grupo es la prioridad de cobranzas. Hay 1.890 préstamos con más de 90 días de mora.
 
---
 
**Q9 — ¿Cómo se segmentan los clientes por risk score?**
 
Modelos: `gold_customers` y `gold_risk`
 
Usamos los buckets definidos: low (0-25), medium (26-50), high (51-75), critical (76-100). El risk score viene directamente del dataset — no lo calculamos, lo reportamos con los buckets para facilitar la visualización en PowerBI.
 
---
 
### Customer Demographics
 
**Q10 — ¿Cuántos clientes hay por país y ciudad?**
 
Modelo: `gold_customers`
 
Conteo directo de clientes por país y ciudad. Las ciudades fueron normalizadas en Silver — 33 errores tipográficos corregidos. Brasil y Perú lideran con 737 clientes cada uno, Chile tiene la menor cantidad con 666.
 
---
 
**Q11 — ¿Cuál es la distribución de edades por segmento?**
 
Modelo: `gold_customers`
 
La edad se calcula en Gold con `date_part('year', age(current_date, date_of_birth))` — no la almacenamos en Silver porque es un campo derivado que cambia con el tiempo. Los age buckets permiten visualización rápida en PowerBI. El grupo 56-65 es el más numeroso, 18-25 el más pequeño.
 
---
 
**Q12 — ¿Cuál es la tendencia de adquisición de clientes en el tiempo?**
 
Modelo: `gold_customers` (campo `registration_month`)
 
Agrupamos por `registration_month` (formato YYYY-MM) para ver la evolución mensual de nuevos clientes. La adquisición es estable entre 60 y 85 clientes nuevos por mes desde 2020.
 
---
 
**Q13 — ¿Cuál es la distribución de status de clientes?**
 
Modelo: `gold_customers`
 
Conteo directo por status (active, inactive, suspended, closed). Distribución bastante balanceada: suspended (25.86%), active (25.76%), inactive (24.34%), closed (24.04%).
 
---
 
**Q14 — ¿Cuál es la distribución de KYC status?**
 
Modelo: `gold_customers`
 
Conteo por kyc_status (verified, pending, expired, rejected). Pending lidera ligeramente (~1.250 clientes) — señal de alerta de compliance que requiere atención.
 
---
 
### Transaction Patterns
 
**Q15 — ¿Cuáles son las categorías de transacción más comunes por volumen y valor?**
 
Modelo: `gold_transactions`
 
Agrupamos por `category` contando transacciones y sumando `amount_usd`. Dining lidera en volumen (~6M transacciones), seguido de healthcare y utilities. Las 15 categorías tienen distribución relativamente balanceada.
 
Consideración: hay categorías con espacios extra (` investment`, `salary  `) que fueron limpiadas en Silver con TRIM(). Los nulls disfrazados ('n/a', 'null', '') fueron convertidos a NULL real.
 
---
 
**Q16 — ¿Cuál es el volumen de transacciones por día de la semana?**
 
Modelo: `gold_transactions` (campos `day_of_week` y `day_name`)
 
`day_name` usa `trim(to_char(transaction_date, 'Day'))` para eliminar los espacios que PostgreSQL agrega por defecto al formatear días.
 
Resultado: miércoles lidera (12,827 transacciones), jueves es el más bajo (11,692).
 
---
 
**Q17 — ¿Cuál es el ticket promedio por canal?**
 
Modelo: `gold_transactions`
 
`AVG(amount_usd)` agrupado por canal. Todos los canales muestran tickets similares (~$24.000-$25.000 USD). La diferencia entre canales es mínima, lo que indica que el canal elegido no influye en el monto de la transacción.
 
---
 
**Q18 — ¿Cuál es la tasa de transacciones fallidas?**
 
Modelo: `gold_transactions` (campo `is_failed`)
 
`is_failed = (status = 'failed')`. De 85.067 transacciones totales, 21.247 fallaron (~25%). La tasa de fallo es consistente entre canales — no hay un canal que falle significativamente más que otros.
 
---
 
**Q19 — ¿Cuáles son los patrones de transferencias internacionales?**
 
Modelo: `gold_transactions` (campos `is_international` y `local_currency`)
 
Una transacción es internacional cuando su `currency` no coincide con la moneda local del país del cliente. De 85.067 transacciones totales, 46.094 son internacionales (54%) y 38.973 son domésticas (46%). USD domina las transacciones internacionales en todos los países.
 
Supuesto: definimos la moneda local por país (CO→COP, UY→UYU, AR→ARS, MX→MXN, CL→CLP, PE→PEN, BR→BRL). EUR siempre es internacional para todos los países del dataset.
 
---
 
### Digital Engagement
 
**Q20 — ¿Cuál es la tasa de adopción de mobile app por segmento?**
 
Modelo: `gold_engagement`
 
`COUNT(CASE WHEN mobile_app_registered THEN 1 END) / COUNT(*)` agrupado por segmento. SME tiene la adopción más alta (49.92%), retail la más baja (47.58%). Las diferencias son pequeñas — adopción digital muy pareja entre segmentos. El total general es 49% — más de la mitad de los clientes aún no usa la app móvil.
 
---
 
**Q21 — ¿Cuál es la preferencia digital vs presencial por grupo de edad?**
 
Modelo: `gold_engagement` (campo `channel_preference`)
 
Clasificamos: digital = mobile o web, physical = branch o atm, other = canales no clasificados como phone y pos. Los grupos más jóvenes (18-25) muestran mayor preferencia por canales digitales, mientras que los grupos mayores (56-65, 65+) tienen proporcionalmente mayor uso de canales físicos. Este resultado es consistente con el comportamiento esperado — los jóvenes adoptan más rápidamente los canales digitales.
 
La categoría "other" existe porque canales como `phone` y `pos` no encajan claramente en digital ni físico tradicional — los agrupamos en una tercera categoría para no distorsionar la comparación digital vs físico.
 
---
 
### Product Analysis
 
**Q22 — ¿Cuáles son los tipos de cuenta más populares?**
 
Modelo: `gold_accounts`
 
Conteo por `account_type`. Distribución bastante pareja: credit_card (4,461), savings (4,421), checking (4,380), investment (4,267). Ningún tipo de cuenta domina — los clientes diversifican sus productos bancarios.
 
---
 
**Q23 — ¿Cuál es la composición del portfolio de préstamos?**
 
Modelo: `gold_loans`
 
Outstanding balance agrupado por `loan_type` y `status`, con conversión a USD. Auto lidera con $142M, seguido de personal ($135M), educación ($130M), negocios ($128M) e hipoteca ($120M). Total pendiente: $679M USD.
 
Los préstamos `paid_off` tienen `outstanding_balance_usd` = su valor original pero `interest_income_usd` = 0 — representan deuda ya cancelada que no genera nuevos intereses.
 
Supuesto: los 219 préstamos con `outstanding_balance` NULL en Silver son préstamos sin información de saldo disponible. Se mantienen como NULL en Gold — no se imputan.
 
---
 
**Q24 — ¿Cuál es el promedio de productos por cliente por segmento?**
 
Modelo: `gold_products`
 
Productos = cuentas + préstamos por cliente. Calculamos con CTEs separados para evitar multiplicar filas con JOINs. Resultado: ~5 productos por cliente en todos los segmentos — distribución muy consistente entre retail, SME, premium y private_banking.
 
Supuesto: definimos productos como cuentas bancarias + préstamos. No incluimos otros productos financieros que no estén en el dataset.
 
---
 
## Tests de Gold
 
107 tests en total (Silver + Gold), todos pasando:
 
- **Unicidad** — PKs en todos los modelos Gold
- **Not-null** — campos críticos en todos los modelos
- **Accepted values** — todos los campos categóricos y buckets
- **Integridad referencial** — Silver mantiene las relaciones dim_*/fct_*
Nota: `balance_usd` en `gold_accounts` y `outstanding_balance_usd` en `gold_loans` no tienen test not_null porque hay 486 y 219 nulls respectivamente — son balances que vinieron como NULL desde el dataset original y se mantienen como NULL por decisión de no imputar.
 
---
 
## Deuda técnica
 
**Tipos de cambio estáticos** — los factores de conversión a USD son aproximados a mayo 2026. En producción usaríamos una tabla de tipos de cambio actualizada diariamente con una fuente oficial (Banco Central, Open Exchange Rates, etc.).
 
**Gold lee de Silver directamente** — los modelos Gold usan `silver.dim_*` y `silver.fct_*` directamente en vez de `{{ ref() }}`. Esto funciona pero rompe el linaje de dbt. En producción moveríamos Silver a modelos dbt y usaríamos `{{ ref('dim_customers') }}` para que dbt construya el DAG de dependencias correctamente.
 
**Grain de gold_risk** — el grain es cliente-préstamo, no cliente. Un cliente sin préstamos aparece una vez con campos de préstamo NULL. Un cliente con 3 préstamos aparece 3 veces. Esto hay que tenerlo en cuenta al construir gráficos en PowerBI — filtrar por préstamo o agregar correctamente.
 
**Balance en gold_revenue removido** — el campo `total_balance_usd` fue removido de `gold_revenue` porque su grain (segmento + canal + país) causaba multiplicación del balance al agregar por país en PowerBI. Q2 se responde via `gold_accounts` directamente, que tiene grain correcto de una fila por cuenta.