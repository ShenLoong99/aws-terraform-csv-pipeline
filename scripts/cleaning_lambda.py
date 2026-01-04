import boto3
import csv
import io
import os
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')

def handler(event, context):
    s3 = boto3.client('s3')
    glue = boto3.client('glue')

    try:
        # Get source bucket and key from event
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        dest_bucket = os.environ['DEST_BUCKET']

        logger.info(f"Starting Lambda processing for file: {key} from bucket: {source_bucket}")
        
        # Download CSV
        response = s3.get_object(Bucket=source_bucket, Key=key)
        content = response['Body'].read().decode('utf-8')
        
        # Basic Cleaning: Remove rows where all columns are empty
        input_data = csv.reader(io.StringIO(content))
        output_buffer = io.StringIO()
        writer = csv.writer(output_buffer)
        
        row_count = 0
        for row in input_data:
            if any(field.strip() for field in row):
                writer.writerow(row)
                row_count += 1

        logger.info(f"Cleaned {row_count} non-empty rows from {key}")
                
        # Upload to Processed Bucket
        dest_key = f"processed_{key}"
        s3.put_object(
            Bucket=dest_bucket,
            Key=f"processed_{key}",
            Body=output_buffer.getvalue()
        )
        
        logger.info(f"Successfully uploaded cleaned file to: s3://{dest_bucket}/{dest_key}")

        # Inside cleaning_lambda.py handler
        glue = boto3.client('glue')
        glue.start_job_run(JobName='csv-transform-job')
        logger.info("Triggered Glue Job: csv-transform-job")

        return {"status": "success", "file": key}
    
    except Exception as e:
        logger.error(f"Error processing file {key}: {str(e)}")
        raise e