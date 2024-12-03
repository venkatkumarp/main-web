output "s3_bucket_name" {
  value = aws_s3_bucket.website.bucket
}

output "s3_bucket_domain_name" {
  value = aws_s3_bucket.website.bucket_domain_name
}
output "s3_bucket_arn" {
  value = aws_s3_bucket.website.arn
}
