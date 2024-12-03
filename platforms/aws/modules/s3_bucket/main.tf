resource "aws_s3_bucket" "website" {
  bucket = "${var.project_name}-static"
  acl    = "private"

  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = var.default_tags
}
resource "aws_s3_bucket_ownership_controls" "ownership_control" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

/*resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${var.aws_account_id}:distribution/${var.cloudfront_distribution_id}"  # Use the passed variable here
          }
        }
      }
    ]
  })
}*/

/*resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow CloudFront to get objects via HTTPS
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${var.aws_account_id}:distribution/${var.cloudfront_distribution_id}"
          }
        }
      },
      # Allow CloudFront to write logs to the bucket
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.website.arn}/cloudfront-logs/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${var.aws_account_id}:distribution/${var.cloudfront_distribution_id}"
          }
        }
      },
      # Deny all requests that are not HTTPS
      {
        Sid       = "HTTPSOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}*/


resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow CloudFront to get objects via HTTPS
      {
        Sid    = "AllowCloudFrontGetObject"
        Effect = var.permission_for_logs
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:*"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${var.aws_account_id}:distribution/${var.cloudfront_distribution_id}"
          }
        }
      },
      # Allow CloudFront to write logs to the bucket
      {
        Sid    = "AllowCloudFrontPutLogs"
        Effect = var.permission_for_logs
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:*"
        Resource = "${aws_s3_bucket.website.arn}/cloudfront-logs/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${var.aws_account_id}:distribution/${var.cloudfront_distribution_id}"
          }
        }
      },
      # Deny all requests that are not HTTPS
      {
        Sid       = "DenyNonHTTPSAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

}


