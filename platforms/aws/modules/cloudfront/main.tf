data "aws_cloudfront_cache_policy" "caching_policy" {
  name                          = "Managed-CachingOptimized"
}

data "aws_wafv2_web_acl" "existing_web_acl" {
  provider                     = aws.us-east-1
  name                         = var.existing_web_acl_name
  scope                        = "CLOUDFRONT"  
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                          = "${var.project_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_protocol              = "sigv4"
  signing_behavior              = "always" 
}

resource "aws_cloudfront_distribution" "web" {
  origin {
    domain_name                  = var.s3_bucket_domain_name
    origin_id                    = "S3Origin"
    origin_access_control_id     = aws_cloudfront_origin_access_control.oac.id
    origin_path                  = "/index.html"

  }

  enabled                        = true
  default_root_object            = "index.html"

  default_cache_behavior {
    target_origin_id             = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods              = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods               = ["GET", "HEAD"]

    compress = true
    cache_policy_id              = data.aws_cloudfront_cache_policy.caching_policy.id
  #  min_ttl                      = 0
  #  default_ttl                  = 86400
  #  max_ttl                      = 31536000

# Lambda@Edge function association

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = var.lambda_edge_arn
      include_body = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type           = "none"
  }
}

  # Enable CloudFront logging
  logging_config {
    bucket = "${var.s3_bucket_name}.s3.amazonaws.com"
    prefix = "${var.environment}/cloudfront-logs/"
  }
  web_acl_id                     = data.aws_wafv2_web_acl.existing_web_acl.arn
    viewer_certificate {
      cloudfront_default_certificate = true
    }

  tags = var.default_tags
}
