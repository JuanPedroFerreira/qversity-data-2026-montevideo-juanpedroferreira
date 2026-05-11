# Bronze Layer
 
**La Bronze Layer es el primer paso para resolver el problema.**
 
---
 
## ¿Qué hace?
 
La Bronze Layer tiene un único trabajo: **guardar los datos tal como llegan, sin tocar nada**.
 
Es como una bodega donde guardás las cajas tal como te las entregaron, sin abrir ni mover nada. El objetivo es tener siempre disponible el dato original, por si algo sale mal más adelante.
 
En este caso:
- Los datos vienen de un archivo JSON en **AWS S3** (un servicio de almacenamiento en la nube de Amazon)
- Los voy a guardar en **PostgreSQL** (como base de datos)
- Cada registro de cliente queda guardado como una fila en la tabla `bronze.raw_fintech_data`
---
 
## ¿Cómo funciona el proceso?
 
El proceso tiene 4 pasos y lo va a coordinar **Apache Airflow**, que va a ser el director de orquesta del pipeline:
 
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

## Breve explicacion de los archivos de Bronze
 
### `scripts/init_schemas.sql`
 
Se ejecuta automáticamente cuando Docker levanta PostgreSQL por primera vez. Hace dos cosas:
 
- Crea los 3 schemas de la arquitectura medallion: `bronze`, `silver` y `gold`
- Crea la tabla `bronze.raw_fintech_data` con sus columnas (`id`, `data`, `source_url`, `load_timestamp`) y dos índices para mejorar la performance cuando PySpark lee Bronze: un índice GIN sobre el JSONB completo y un índice específico sobre `customer_id`
Si la tabla ya existe, no hace nada, por el `IF NOT EXISTS`.
 
---
 
### `scripts/load_bronze.py`
 
Es el script que Airflow ejecuta en la tarea `ingest_bronze`. Tiene 4 responsabilidades:
 
**Descargar el dataset** Intenta S3 primero. Si S3 falla, cae al archivo local en `data/raw/`. Esto hace el pipeline robusto ante problemas de conectividad.
 
**Truncar la tabla** Borra todos los registros anteriores y reinicia el contador de IDs antes de insertar. Garantiza idempotencia.
 
**Insertar en batches de 500** Insertar de a 1 haría 5.100 roundtrips a la base de datos. Con batches de 500 hacemos solo 11 inserts eficientes.
 
**Validar** Verifica que haya al menos 1.000 registros cargados. Si algo salió mal en la descarga, el pipeline falla acá con un error claro en vez de continuar con datos corruptos.
 
## Airflow
 
Airflow es una herramienta que  permite **programar y monitorear tareas automáticamente**. En vez de correr un script manualmente cada vez, Airflow lo hace solo, en orden, y avisa si algo falla.
 
En este pipeline, Airflow tiene un "DAG" (que es básicamente un flujo de trabajo) llamado `qversity_fintech_pipeline` con 5 tareas en cadena:
 
```
ingest_bronze → spark_flatten → dbt_run_silver → dbt_run_gold → dbt_test
```
 
## ¿Cómo se ve el dato en Bronze?
 
Antes de procesarlo, cada cliente se ve así en la base de datos, un bloque JSON con toda su información adentro:
 
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
 
## ¿Por qué se guarda todo sin transformar?
 
Tres razones importantes:
 
**1. Trazabilidad** — Si algo sale mal en las capas siguientes (Silver o Gold), siempre podemos volver al dato original y reprocesar desde cero sin tener que ir a buscar el archivo a S3 de nuevo.
 
**2. Auditoría** — En el mundo financiero es muy importante poder demostrar de dónde vino cada dato. El campo `source_url` guarda exactamente de qué URL se descargó cada registro.
 
**3. Flexibilidad** — Si en el futuro necesitamos extraer un campo que hoy no estamos usando, el dato ya está guardado en Bronze. No perdemos nada.
 
---
 
## Resultado
 
Al terminar la Bronze Layer, se ven:
 
| Métrica | Valor |
|---------|-------|
| Registros cargados | **5.100 clientes** |
| Formato | JSONB en PostgreSQL |
| Origen | AWS S3 público |
| Duplicados | 0 — la tabla se trunca antes de cada carga para garantizar idempotencia |

Aclaracion:

Se elije truncar porque el dataset es estático. En un caso de uso real con datos que cambian diariamente, usaríamos un enfoque de append con deduplicación por customer_id y load_timestamp.
---