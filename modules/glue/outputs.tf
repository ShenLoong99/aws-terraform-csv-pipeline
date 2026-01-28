output "glue_job_name" {
  description = "Name of the glue job"
  value       = aws_glue_job.transform_job.name
}
