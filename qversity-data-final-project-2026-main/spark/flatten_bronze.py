import logging
import os

from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col,
    current_timestamp,
    explode,
    from_json,
    get_json_object,
    row_number,
)
from pyspark.sql.types import (
    ArrayType,
    BooleanType,
    DoubleType,
    FloatType,
    IntegerType,
    StringType,
    StructField,
    StructType,
)
from pyspark.sql.window import Window

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

POSTGRES_HOST = os.getenv("POSTGRES_HOST", "postgres")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_DB = os.getenv("POSTGRES_DB", "qversity")
POSTGRES_USER = os.getenv("POSTGRES_USER", "qversity-admin")
POSTGRES_PASS = os.getenv("POSTGRES_PASSWORD", "qversity-admin")

JDBC_URL = f"jdbc:postgresql://{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"
JDBC_DRIVER = "/opt/spark/jars/postgresql-42.7.3.jar"

JDBC_PROPS = {
    "user": POSTGRES_USER,
    "password": POSTGRES_PASS,
    "driver": "org.postgresql.Driver",
}


def create_spark_session():
    return (
        SparkSession.builder.appName("Qversity - Bronze to Silver Flattening")
        .config("spark.jars", JDBC_DRIVER)
        .config("spark.sql.shuffle.partitions", "8")
        .config("spark.driver.memory", "2g")
        .getOrCreate()
    )


CUSTOMER_SCHEMA = StructType(
    [
        StructField("customer_id", StringType()),
        StructField("first_name", StringType()),
        StructField("last_name", StringType()),
        StructField("email", StringType()),
        StructField("phone_number", StringType()),
        StructField("date_of_birth", StringType()),
        StructField("gender", StringType()),
        StructField("nationality", StringType()),
        StructField("city", StringType()),
        StructField("country", StringType()),
        StructField("address", StringType()),
        StructField("lat", DoubleType()),
        StructField("lon", DoubleType()),
        StructField("registration_date", StringType()),
        StructField("kyc_status", StringType()),
        StructField("risk_score", DoubleType()),
        StructField("customer_segment", StringType()),
        StructField("relationship_manager", StringType()),
        StructField("status", StringType()),
        StructField("accounts", StringType()),
        StructField("transactions", StringType()),
        StructField("loans", StringType()),
        StructField("credit_info", StringType()),
        StructField("digital_engagement", StringType()),
    ]
)

ACCOUNT_SCHEMA = ArrayType(
    StructType(
        [
            StructField("account_id", StringType()),
            StructField("account_type", StringType()),
            StructField("currency", StringType()),
            StructField("balance", DoubleType()),
            StructField("credit_limit", DoubleType()),
            StructField("interest_rate", DoubleType()),
            StructField("opened_date", StringType()),
            StructField("status", StringType()),
            StructField("branch_code", StringType()),
        ]
    )
)

TRANSACTION_SCHEMA = ArrayType(
    StructType(
        [
            StructField("transaction_id", StringType()),
            StructField("account_id", StringType()),
            StructField("date", StringType()),
            StructField("amount", DoubleType()),
            StructField("currency", StringType()),
            StructField("type", StringType()),
            StructField("category", StringType()),
            StructField("merchant", StringType()),
            StructField("channel", StringType()),
            StructField("status", StringType()),
            StructField("description", StringType()),
        ]
    )
)

LOAN_SCHEMA = ArrayType(
    StructType(
        [
            StructField("loan_id", StringType()),
            StructField("type", StringType()),
            StructField("currency", StringType()),
            StructField("principal", DoubleType()),
            StructField("outstanding_balance", DoubleType()),
            StructField("interest_rate", DoubleType()),
            StructField("term_months", IntegerType()),
            StructField("monthly_payment", DoubleType()),
            StructField("start_date", StringType()),
            StructField("end_date", StringType()),
            StructField("status", StringType()),
            StructField("days_past_due", IntegerType()),
            StructField("collateral_type", StringType()),
        ]
    )
)

CREDIT_INFO_SCHEMA = StructType(
    [
        StructField("credit_score", IntegerType()),
        StructField("currency", StringType()),
        StructField("utilization_pct", DoubleType()),
        StructField("total_limit", DoubleType()),
        StructField("total_used", DoubleType()),
        StructField("num_credit_accounts", IntegerType()),
        StructField("oldest_account_age_months", IntegerType()),
        StructField("late_payments_12m", IntegerType()),
        StructField("inquiries_6m", IntegerType()),
        StructField("bankruptcy_flag", BooleanType()),
    ]
)

DIGITAL_ENGAGEMENT_SCHEMA = StructType(
    [
        StructField("mobile_app_registered", BooleanType()),
        StructField("web_banking_registered", BooleanType()),
        StructField("last_login_date", StringType()),
        StructField("avg_monthly_logins", IntegerType()),
        StructField("preferred_channel", StringType()),
        StructField("push_notifications", BooleanType()),
        StructField("paperless_statements", BooleanType()),
    ]
)


def deduplicate(df, partition_col, order_col="load_timestamp"):
    window = Window.partitionBy(partition_col).orderBy(col(order_col).desc())
    return (
        df.withColumn("row_num", row_number().over(window))
        .filter(col("row_num") == 1)
        .drop("row_num")
    )


def read_bronze(spark):
    """
    Reads bronze.raw_fintech_data via JDBC.
    The 'data' column comes as STRING from PostgreSQL JSONB,
    so we parse it with from_json using the customer schema.
    """
    log.info("Reading from bronze.raw_fintech_data...")
    raw_df = spark.read.jdbc(
        url=JDBC_URL, table="bronze.raw_fintech_data", properties=JDBC_PROPS
    )
    log.info(f"Bronze records loaded: {raw_df.count()}")

    df = raw_df.withColumn(
        "json", from_json(col("data").cast("string"), CUSTOMER_SCHEMA)
    )
    log.info("Bronze JSON parsed successfully.")
    return df


def write_to_silver(df, table_name):
    full_table = f"silver.{table_name}"
    count = df.count()
    log.info(f"Writing {count} rows to {full_table}...")
    df.write.jdbc(
        url=JDBC_URL, table=full_table, mode="overwrite", properties=JDBC_PROPS
    )
    log.info(f"Done: {full_table} ({count} rows)")


def flatten_customers(df):
    log.info("Flattening customers...")
    result = df.select(
        col("id").alias("bronze_id"),
        col("load_timestamp"),
        col("json.customer_id"),
        col("json.first_name"),
        col("json.last_name"),
        col("json.email"),
        col("json.phone_number"),
        col("json.date_of_birth"),
        col("json.gender"),
        col("json.nationality"),
        col("json.city"),
        col("json.country"),
        col("json.address"),
        col("json.lat"),
        col("json.lon"),
        col("json.registration_date"),
        col("json.kyc_status"),
        col("json.risk_score"),
        col("json.customer_segment"),
        col("json.relationship_manager"),
        col("json.status"),
    )
    result = deduplicate(result, "customer_id")
    log.info(f"Customers after dedup: {result.count()}")
    return result


def flatten_accounts(df):
    log.info("Flattening accounts...")
    result = df.select(
        col("load_timestamp"),
        col("json.customer_id"),
        from_json(col("json.accounts"), ACCOUNT_SCHEMA).alias("accounts"),
    )
    result = result.withColumn("account", explode(col("accounts"))).drop(
        "accounts"
    )
    result = result.select(
        col("customer_id"),
        col("load_timestamp"),
        col("account.account_id"),
        col("account.account_type"),
        col("account.currency"),
        col("account.balance"),
        col("account.credit_limit"),
        col("account.interest_rate"),
        col("account.opened_date"),
        col("account.status"),
        col("account.branch_code"),
    )
    result = deduplicate(result, "account_id")
    log.info(f"Accounts after dedup: {result.count()}")
    return result


def flatten_transactions(df):
    log.info("Flattening transactions...")
    result = df.select(
        col("load_timestamp"),
        col("json.customer_id"),
        from_json(col("json.transactions"), TRANSACTION_SCHEMA).alias(
            "transactions"
        ),
    )
    result = result.withColumn(
        "transaction", explode(col("transactions"))
    ).drop("transactions")
    result = result.select(
        col("customer_id"),
        col("load_timestamp"),
        col("transaction.transaction_id"),
        col("transaction.account_id"),
        col("transaction.date"),
        col("transaction.amount"),
        col("transaction.currency"),
        col("transaction.type"),
        col("transaction.category"),
        col("transaction.merchant"),
        col("transaction.channel"),
        col("transaction.status"),
        col("transaction.description"),
    )
    result = deduplicate(result, "transaction_id")
    log.info(f"Transactions after dedup: {result.count()}")
    return result


def flatten_loans(df):
    log.info("Flattening loans...")
    result = df.select(
        col("load_timestamp"),
        col("json.customer_id"),
        from_json(col("json.loans"), LOAN_SCHEMA).alias("loans"),
    )
    result = result.withColumn("loan", explode(col("loans"))).drop("loans")
    result = result.select(
        col("customer_id"),
        col("load_timestamp"),
        col("loan.loan_id"),
        col("loan.type"),
        col("loan.currency"),
        col("loan.principal"),
        col("loan.outstanding_balance"),
        col("loan.interest_rate"),
        col("loan.term_months"),
        col("loan.monthly_payment"),
        col("loan.start_date"),
        col("loan.end_date"),
        col("loan.status"),
        col("loan.days_past_due"),
        col("loan.collateral_type"),
    )
    result = deduplicate(result, "loan_id")
    log.info(f"Loans after dedup: {result.count()}")
    return result


def flatten_credit_info(df):
    log.info("Flattening credit_info...")
    result = df.select(
        col("load_timestamp"),
        col("json.customer_id"),
        from_json(col("json.credit_info"), CREDIT_INFO_SCHEMA).alias(
            "credit_info"
        ),
    )
    result = result.select(
        col("customer_id"),
        col("load_timestamp"),
        col("credit_info.credit_score"),
        col("credit_info.currency"),
        col("credit_info.utilization_pct"),
        col("credit_info.total_limit"),
        col("credit_info.total_used"),
        col("credit_info.num_credit_accounts"),
        col("credit_info.oldest_account_age_months"),
        col("credit_info.late_payments_12m"),
        col("credit_info.inquiries_6m"),
        col("credit_info.bankruptcy_flag"),
    )
    result = deduplicate(result, "customer_id")
    log.info(f"Credit info after dedup: {result.count()}")
    return result


def flatten_digital_engagement(df):
    log.info("Flattening digital_engagement...")
    result = df.select(
        col("load_timestamp"),
        col("json.customer_id"),
        from_json(
            col("json.digital_engagement"), DIGITAL_ENGAGEMENT_SCHEMA
        ).alias("digital_engagement"),
    )
    result = result.select(
        col("customer_id"),
        col("load_timestamp"),
        col("digital_engagement.mobile_app_registered"),
        col("digital_engagement.web_banking_registered"),
        col("digital_engagement.last_login_date"),
        col("digital_engagement.avg_monthly_logins"),
        col("digital_engagement.preferred_channel"),
        col("digital_engagement.push_notifications"),
        col("digital_engagement.paperless_statements"),
    )
    result = deduplicate(result, "customer_id")
    log.info(f"Digital engagement after dedup: {result.count()}")
    return result


def main():
    log.info("=== STARTING PYSPARK SILVER FLATTENING JOB ===")
    spark = create_spark_session()
    df = read_bronze(spark)

    write_to_silver(flatten_customers(df), "stg_customers")
    write_to_silver(flatten_accounts(df), "stg_accounts")
    write_to_silver(flatten_transactions(df), "stg_transactions")
    write_to_silver(flatten_loans(df), "stg_loans")
    write_to_silver(flatten_credit_info(df), "stg_credit_info")
    write_to_silver(flatten_digital_engagement(df), "stg_digital_engagement")

    log.info("=== PYSPARK SILVER FLATTENING JOB COMPLETE ===")
    spark.stop()


if __name__ == "__main__":
    main()
