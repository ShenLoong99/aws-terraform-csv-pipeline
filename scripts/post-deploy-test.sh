#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

echo "-------------------------------------------------------"
echo "🚀 Starting Post-Deployment Integration Test"
echo "Target Bucket: ${RAW_BUCKET}"
echo "Glue Job: ${GLUE_JOB_NAME}"
echo "-------------------------------------------------------"

# 1. Upload sample data to trigger the pipeline
echo "📦 Uploading sample data to S3..."
aws s3 cp ./csv/customers-100.csv s3://${RAW_BUCKET}/test_data.csv

# 2. Wait a few seconds for Lambda to trigger the Glue Job
echo "⏳ Waiting for Lambda to trigger Glue Job..."
sleep 15

# 3. Get the latest Run ID for the Glue Job
# We need the Run ID to use the 'wait' command effectively
RUN_ID=$(aws glue get-job-runs --job-name ${GLUE_JOB_NAME} --max-items 1 --query "JobRuns[0].Id" --output text)

if [ "$RUN_ID" == "None" ] || [ -z "$RUN_ID" ]; then
    echo "❌ Error: Could not find a recent Glue Job run. Lambda trigger might have failed."
    exit 1
fi

echo "🔍 Monitoring Glue Job Run: $RUN_ID"

# 4. Wait for Glue Job to finish
# This command polls AWS until the job is complete
aws glue wait job-run-complete --job-name ${GLUE_JOB_NAME} --run-id ${RUN_ID}

# 5. Final Status Check
JOB_STATUS=$(aws glue get-job-run --job-name ${GLUE_JOB_NAME} --run-id ${RUN_ID} --query "JobRun.JobRunState" --output text)

if [ "$JOB_STATUS" == "SUCCEEDED" ]; then
    echo "✅ Integration Test Passed: Glue Job finished successfully."
    exit 0
else
    echo "❌ Integration Test Failed: Glue Job status is $JOB_STATUS."
    exit 1
fi
