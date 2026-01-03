import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DATABASE', 'TABLE', 'OUTPUT_PATH'])
glueContext = GlueContext(SparkContext.getOrCreate())
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Load data from Glue Catalog
datasource = glueContext.create_dynamic_frame.from_catalog(
    database = args['DATABASE'], 
    table_name = args['TABLE']
)

# Perform simple transformation (e.g., dropping nulls)
drop_nulls = DropNullFields.apply(frame = datasource)

# Write to S3 in Parquet format
glueContext.write_dynamic_frame.from_options(
    frame = drop_nulls,
    connection_type = "s3",
    connection_options = {"path": args['OUTPUT_PATH']},
    format = "parquet"
)

job.commit()