#!/bin/bash
set -e

echo "-------------------------------------------------------"
echo "🚀 Starting Post-Deployment Integration Test"
echo "Target Bucket: ${RAW_BUCKET}"
echo "Glue Job: ${GLUE_JOB_NAME}"
echo "-------------------------------------------------------"

# Upload sample data
echo "📦 Uploading sample data to S3..."
aws s3 cp ./csv/customers-100.csv s3://${RAW_BUCKET}/test_data.csv

# Wait for Lambda to trigger Glue Job
echo "⏳ Waiting for Lambda to trigger Glue Job..."
sleep 20

# Get the latest Run ID
RUN_ID=$(aws glue get-job-runs --job-name ${GLUE_JOB_NAME} --max-items 1 --query "JobRuns[0].Id" --output text)

if [ "$RUN_ID" == "None" ] || [ -z "$RUN_ID" ]; then
    echo "❌ Error: No Glue Job run found."
    exit 1
fi

echo "🔍 Monitoring Glue Job Run: $RUN_ID"

# Custom Polling Loop (Fix for 'wait' error)
while true; do
    # Get current status
    STATUS=$(aws glue get-job-run --job-name ${GLUE_JOB_NAME} --run-id ${RUN_ID} --query "JobRun.JobRunState" --output text)

    echo "Current Status: $STATUS"

    if [ "$STATUS" == "SUCCEEDED" ]; then
        echo "✅ Glue Job Completed Successfully!"
        break
    elif [ "$STATUS" == "FAILED" ] || [ "$STATUS" == "STOPPED" ] || [ "$STATUS" == "TIMEOUT" ]; then
        echo "❌ Glue Job Failed with status: $STATUS"
        exit 1
    fi

    # Wait before checking again
    sleep 30
done
