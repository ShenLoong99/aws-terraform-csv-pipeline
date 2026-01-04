import sys
import logging
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Set up Glue Logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DATABASE', 'TABLE', 'OUTPUT_PATH', 'DATABASE_BUCKET_NAME'])
glueContext = GlueContext(SparkContext.getOrCreate())
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

try:
    logger.info(f"Starting Glue Job: {args['JOB_NAME']}")

    # Load data from Glue Catalog
    datasource = glueContext.create_dynamic_frame.from_options(
        connection_type = "s3",
        connection_options = {"paths": [f"s3://{args['DATABASE_BUCKET_NAME']}/"]},
        format = "csv",
        format_options = {"withHeader": True}
    )

    initial_count = datasource.count()
    logger.info(f"Initial record count from catalog: {initial_count}")

    # Perform simple transformation (e.g., dropping nulls)
    drop_nulls = DropNullFields.apply(frame = datasource)

    final_count = drop_nulls.count()
    logger.info(f"Record count after dropping null fields: {final_count}")

    # Write to S3 in Parquet format
    logger.info(f"Writing transformed data to: {args['OUTPUT_PATH']}")
    glueContext.write_dynamic_frame.from_options(
        frame = drop_nulls,
        connection_type = "s3",
        connection_options = {"path": args['OUTPUT_PATH']},
        format = "csv"
    )

    logger.info("Glue Job completed successfully.")
    job.commit()

except Exception as e:
    logger.error(f"FATAL ERROR in Glue Job: {str(e)}")
    raise e # Re-raise to ensure the Glue Job status is marked as 'Failed'