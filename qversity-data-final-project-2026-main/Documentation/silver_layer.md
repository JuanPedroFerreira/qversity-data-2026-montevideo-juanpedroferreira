# Capa Silver — Qué construí y por qué

## El problema que tenía que resolver

Después de la capa Bronze, tenía 5.100 registros JSON crudos en PostgreSQL. Antes de poder responder cualquier pregunta de negocio necesitaba:

1. **Explotar** todos esos arrays anidados en tablas relacionales separadas
2. **Limpiar** los datos — corregir errores tipográficos, normalizar idiomas, manejar nulls
3. **Validar** la calidad con tests automáticos

La capa Silver está dividida en dos fases: **PySpark** para el aplanado, y **dbt** para la limpieza y los tests.

---

## Fase 1 — PySpark: Aplanado y Deduplicación

### ¿Por qué PySpark?

Podría haber hecho esto con SQL directamente en PostgreSQL usando `jsonb_array_elements`, pero PySpark está hecho para este tipo de trabajo — maneja estructuras anidadas de forma nativa con `explode()` y `from_json()`, y escala bien. El proyecto también lo requiere explícitamente para este rol.

### Tablas staging que crea PySpark

El script `spark/flatten_bronze.py` lee de `bronze.raw_fintech_data` via JDBC y crea 6 tablas staging en el schema `silver`. Estas tablas son un paso intermedio — los datos ya están en formato relacional pero todavía sin limpiar ni normalizar:

| Tabla | Registros | Origen | Descripción |
|-------|-----------|--------|-------------|
| `stg_customers` | 5.000 | Campos planos del JSON | Un cliente por fila |
| `stg_accounts` | 17.374 | Array `accounts[]` | 2-5 cuentas por cliente |
| `stg_transactions` | 87.990 | Array `transactions[]` | 5-30 transacciones por cliente |
| `stg_loans` | 7.353 | Array `loans[]` | 0-3 préstamos por cliente |
| `stg_credit_info` | 5.000 | Objeto `credit_info{}` | Un registro por cliente |
| `stg_digital_engagement` | 5.000 | Objeto `digital_engagement{}` | Un registro por cliente |

El prefijo `stg_` indica que son tablas de staging — datos sin procesar, listos para ser consumidos por dbt en el siguiente paso.

### Cómo funciona la deduplicación

Un registro es duplicado si comparte la misma clave primaria (`customer_id`, `account_id`, `transaction_id` o `loan_id`). Usé `ROW_NUMBER()` con una ventana particionada por la clave primaria y ordenada por `load_timestamp DESC` — quedándome solo con el registro más reciente. Esto eliminó 100 registros duplicados de clientes (5.100 → 5.000).

---

## Fase 2 — EDA: Lo que encontré en los datos

Antes de limpiar, corrí queries exploratorias directas contra las tablas staging en DBeaver para entender los problemas de calidad. Dejé constancia de todas las consultas y hallazgos en los archivos `dbt/analyses/`. Los hallazgos principales fueron:

### Idiomas mezclados
El dataset tenía valores en español e inglés sin consistencia:
- Estado del cliente: `activo`, `inactivo`, `cerrado`, `suspendido` mezclado con `active`, `inactive`, `closed`, `suspended`
- Tipos de transacción: `deposito`, `retiro`, `pago`, `reembolso`, `comision` mezclado con equivalentes en inglés
- Estado de cuenta: `activo`, `cerrado`, `congelado` mezclado con valores en inglés
- Segmentos: `minorista`, `pyme`, `banca_privada` mezclado con `retail`, `sme`, `private_banking`

### Formatos de fecha — 4 formatos distintos en la misma columna
- `YYYY-MM-DD` (el más común)
- `DD/MM/YYYY`
- `YYYYMMDD`
- `MM-DD-YYYY`

### Nulls disfrazados como texto
En múltiples columnas, los valores nulos estaban guardados como: `'n/a'`, `'NA'`, `'null'`, `'Null'`, `'NULL'`, `''` (cadena vacía)

### Errores tipográficos en nombres de ciudades
33 ciudades tenían errores: `Cusc` → `Cusco`, `Lma` → `Lima`, `Santiag` → `Santiago`, `Sao Paulp` → `Sao Paulo`, etc.

### Formatos de teléfono — 3 formatos distintos
- `+56 4737213290` (con espacios)
- `(+51) 8476691953` (con paréntesis)
- `2594972204` (sin prefijo de país)
- `+51-214-8591079` (con guiones)

### Otros hallazgos
- `utilization_pct` tenía dos formatos: `0.35` (decimal) y `35` (porcentaje como entero) — normalicé todo a 0-1
- 2.052 emails tenían formato inválido — los marqué con `is_valid_email` en vez de descartarlos
- 492 credit scores estaban fuera del rango válido 300-850 — los filtré en Silver
- Los campos `credit_info.currency` y `loans.currency` fueron agregados en el dataset actualizado

---

## Fase 3 — dbt: Limpieza y Normalización

### Modelos que construí

Reemplacé las tablas staging con 6 tablas limpias de dimensiones y hechos:

**Dimensiones:**
- `dim_customers` — atributos del cliente normalizados y validados
- `dim_accounts` — detalles de cuentas por cliente
- `dim_credit_info` — datos de scoring crediticio y utilización
- `dim_digital_engagement` — métricas de adopción digital

**Hechos:**
- `fct_transactions` — todos los registros de transacciones
- `fct_loans` — datos del portfolio de préstamos

### Decisiones de limpieza clave

**Normalización de fechas** — Creé un macro `parse_date` que detecta el formato automáticamente:
```sql
{% macro parse_date(field) %}
    case
        when {{ field }} ~ '^\d{4}-\d{2}-\d{2}$' then {{ field }}::date
        when {{ field }} ~ '^\d{2}/\d{2}/\d{4}$' then to_date({{ field }}, 'DD/MM/YYYY')
        when {{ field }} ~ '^\d{8}$'              then to_date({{ field }}, 'YYYYMMDD')
        when {{ field }} ~ '^\d{2}-\d{2}-\d{4}$' then to_date({{ field }}, 'MM-DD-YYYY')
        else null
    end
{% endmacro %}
```

**Normalización de idioma** — Sentencias CASE traducen valores en español a inglés en todos los modelos.

**Normalización de nulls** — `'n/a'`, `'na'`, `'null'`, `''` convertidos a NULL real usando `TRIM() + LOWER() + CASE`.

**Corrección de errores tipográficos en ciudades** — 33 errores conocidos corregidos con CASE hardcodeado.

**Normalización de teléfonos** — eliminé paréntesis, espacios y guiones; agregué prefijo de país para números que no lo tenían basándome en el campo `country` del cliente.

**Validación de emails** — en vez de descartar 2.052 emails inválidos, agregué un flag booleano `is_valid_email` para filtrado posterior.

**Normalización de utilización** — detecté dos formatos (0.35 vs 35) y normalicé todo a decimal 0-1.

### Supuestos de calidad de datos

- **Balances nulos** (504 en cuentas, 215-219 en préstamos) — se mantienen como NULL. No se aplicó imputación.
- **240 clientes registrados menores de 18 años** — se mantienen en Silver, documentado.
- **821 tipos de colateral nulos** — convertidos desde nulls disfrazados, se mantienen como NULL.
- **Canal `phone` no estaba en el PDF** — lo encontré en los datos reales, lo agregué a los valores aceptados en `schema.yml`.
- **Estrategia de truncado** — la tabla Bronze se trunca antes de cada carga para garantizar idempotencia.

---

## Fase 4 — Tests de dbt

Implementé 39 tests automáticos que cubren:

**Unicidad** — claves primarias en los 6 modelos

**Not-null** — campos críticos (customer_id, email, country, amount, etc.)

**Valores aceptados** — todos los campos categóricos (status, segmentos, canales, tipos de préstamo, etc.)

**Integridad referencial** — todas las facts y dimensiones referencian `dim_customers`:
- `dim_accounts.customer_id` → `dim_customers`
- `fct_transactions.customer_id` → `dim_customers`
- `fct_transactions.account_id` → `dim_accounts`
- `fct_loans.customer_id` → `dim_customers`
- `dim_credit_info.customer_id` → `dim_customers`
- `dim_digital_engagement.customer_id` → `dim_customers`

**Test custom** — `test_credit_score_range.sql` valida que todos los scores estén entre 300-850.

**Resultado: 39/39 tests pasando.**

---

## Deuda técnica

### Corrección de ciudades — hardcodeo vs solución robusta

Actualmente corrijo los errores tipográficos en nombres de ciudades con un CASE hardcodeado:
```sql
when 'Lma' then 'Lima'
when 'Cusc' then 'Cusco'
```

El problema es que si en el futuro llegan datos con una ciudad nueva mal escrita (`Carcas` en vez de `Caracas`), el pipeline no la va a corregir — va a pasar tal cual.

En producción, la solución correcta sería usar una librería de similitud de strings (como `fuzzywuzzy` en Python o la extensión `pg_trgm` en PostgreSQL) que compara cada ciudad con una tabla de referencia y elige la más similar. Esto permitiría corregir errores nunca vistos antes sin intervención manual.

Por limitaciones de tiempo, dejé el hardcodeo como solución suficiente para este dataset estático..

---

## Qué deja listo para Gold

Con Silver completo, cada modelo Gold puede hacer JOINs directamente contra tablas limpias, normalizadas y validadas. Sin adivinar formatos de fecha, sin valores en español mezclados con inglés, sin nulls disfrazados. Los datos están listos para responder las 24 preguntas de negocio.