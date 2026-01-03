import boto3
import csv
import io
import os

s3 = boto3.client('s3')

def handler(event, context):
    # Get source bucket and key from event
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    dest_bucket = os.environ['DEST_BUCKET']
    
    # Download CSV
    response = s3.get_object(Bucket=source_bucket, Key=key)
    content = response['Body'].read().decode('utf-8')
    
    # Basic Cleaning: Remove rows where all columns are empty
    input_data = csv.reader(io.StringIO(content))
    output_buffer = io.StringIO()
    writer = csv.writer(output_buffer)
    
    for row in input_data:
        if any(field.strip() for field in row):
            writer.writerow(row)
            
    # Upload to Processed Bucket
    s3.put_object(
        Bucket=dest_bucket,
        Key=f"processed_{key}",
        Body=output_buffer.getvalue()
    )
    
    return {"status": "success", "file": key}