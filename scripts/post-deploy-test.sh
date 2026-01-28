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
RUN_ID=$(aws glue get-job-runs --job-name "${GLUE_JOB_NAME}" --max-items 1 --query "JobRuns[0].Id" --output text | head -n 1)

# Double-check if the resulting variable is still empty or "None"
if [[ -z "$RUN_ID" || "$RUN_ID" == "None" ]]; then
    echo "❌ Error: Could not find a valid Glue Job run ID. Lambda may still be triggering."
    exit 1
fi

echo "🔍 Monitoring Glue Job Run: $RUN_ID"

# 4. Custom Polling Loop
while true; do
    # Fetch status and again, ensure we only get one clean line
    STATUS=$(aws glue get-job-run --job-name "${GLUE_JOB_NAME}" --run-id "${RUN_ID}" --query "JobRun.JobRunState" --output text | head -n 1)

    if [[ -z "$STATUS" || "$STATUS" == "None" ]]; then
        echo "⏳ Status not yet available, retrying..."
    else
        echo "Current Status: $STATUS"

        if [[ "$STATUS" == *"SUCCEED"* ]]; then
            echo "✅ Glue Job Completed Successfully!"
            break
        elif [[ "$STATUS" == *"FAIL"* ]] || [[ "$STATUS" == *"STOP"* ]] || [[ "$STATUS" == *"TIMEOUT"* ]]; then
            echo "❌ Glue Job Failed with status: $STATUS"
            exit 1
        fi
    fi
    sleep 30
done
