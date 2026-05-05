# Bronze Layer — ¿Qué es y como lo logramos?
 
## La idea simple
 
Imaginá que trabajás en una empresa fintech grande y todos los días llegan miles de registros de clientes desde distintos sistemas. Esos datos llegan en formato JSON — un formato muy común pero muy desordenado, donde toda la información de un cliente (sus cuentas, sus transacciones, sus préstamos) viene apilada en un solo bloque de texto.
 
El problema es que así no podés hacer nada útil con esos datos. No podés buscar fácilmente, no podés cruzar información, no podés hacer reportes.
 
**La Bronze Layer es el primer paso para resolver eso.**
 
---
 
## ¿Qué hace?
 
La Bronze Layer tiene un único trabajo: **guardar los datos tal como llegan, sin tocar nada**.
 
Es como una bodega donde guardás las cajas tal como te las entregaron, sin abrir ni mover nada. El objetivo es tener siempre disponible el dato original, por si algo sale mal más adelante.
 
En nuestro caso:
- Los datos vienen de un archivo JSON en **AWS S3** (un servicio de almacenamiento en la nube de Amazon)
- Los guardamos en **PostgreSQL** (nuestra base de datos)
- Cada registro de cliente queda guardado como una fila en la tabla `bronze.raw_fintech_data`
---
 
## ¿Cómo funciona el proceso?
 
El proceso tiene 4 pasos y lo coordina **Apache Airflow**, que es como el director de orquesta del pipeline:
 
```
1. Airflow se despierta y ejecuta el DAG
        │
        ▼
2. Descarga el archivo JSON desde S3
   (https://qversity-raw-public-data.s3.amazonaws.com/fintech_banking_dataset.json)
        │
        ▼
3. Parsea el JSON y separa los 5100 registros de clientes
        │
        ▼
4. Inserta cada registro como una fila en bronze.raw_fintech_data
```
 
---
 
## ¿Qué es Airflow y por qué lo usamos?
 
Airflow es una herramienta que nos permite **programar y monitorear tareas automáticamente**. En vez de correr un script manualmente cada vez, Airflow lo hace solo, en orden, y nos avisa si algo falla.
 
En nuestro pipeline, Airflow tiene un "DAG" (que es básicamente un flujo de trabajo) llamado `qversity_fintech_pipeline` con 5 tareas en cadena:
 
```
ingest_bronze → spark_flatten → dbt_run_silver → dbt_run_gold → dbt_test
```
 
La Bronze Layer es la primera tarea: `ingest_bronze`.
 
---
 
## ¿Cómo se ve el dato en Bronze?
 
Antes de procesarlo, cada cliente se ve así en la base de datos — un bloque JSON con toda su información adentro:
 
```json
{
  "customer_id": "CUST-0000001",
  "first_name": "María",
  "last_name": "García",
  "country": "UY",
  "risk_score": 42.5,
  "accounts": [
    { "account_id": "ACC-001", "type": "savings", "balance": 15000 },
    { "account_id": "ACC-002", "type": "credit_card", "balance": 3200 }
  ],
  "transactions": [
    { "transaction_id": "TXN-001", "amount": 500, "type": "deposit" },
    ...
  ],
  "loans": [...],
  "credit_info": { "credit_score": 720, "utilization_pct": 0.35 },
  "digital_engagement": { "mobile_app_registered": true, "avg_monthly_logins": 12 }
}
```
 
Todo eso queda guardado en **una sola fila** en la tabla Bronze. Es como guardar la caja sin abrir.
 
---
 
## ¿Por qué guardamos todo sin transformar?
 
Tres razones importantes:
 
**1. Trazabilidad** — Si algo sale mal en las capas siguientes (Silver o Gold), siempre podemos volver al dato original y reprocesar desde cero sin tener que ir a buscar el archivo a S3 de nuevo.
 
**2. Auditoría** — En el mundo financiero es muy importante poder demostrar de dónde vino cada dato. El campo `source_url` guarda exactamente de qué URL se descargó cada registro.
 
**3. Flexibilidad** — Si en el futuro necesitamos extraer un campo que hoy no estamos usando, el dato ya está guardado en Bronze. No perdemos nada.
 
---
 
## Resultado
 
Al terminar la Bronze Layer, tenemos:
 
| Métrica | Valor |
|---------|-------|
| Registros cargados | **5.100 clientes** |
| Formato | JSONB en PostgreSQL |
| Origen | AWS S3 público |
| Duplicados | 0 — la tabla se trunca antes de cada carga para garantizar idempotencia |

Aclaracion:

Elegimos truncar porque el dataset es estático. En un caso de uso real con datos que cambian diariamente, usaríamos un enfoque de append con deduplicación por customer_id y load_timestamp.
---