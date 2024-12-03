output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.web.id
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.web.domain_name 
}

output "origin_access_control_id" {
  description = "The ID of the CloudFront Origin Access Control"
  value       = aws_cloudfront_origin_access_control.oac.id
}


