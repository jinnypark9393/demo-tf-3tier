# s3 버킷 생성
resource "aws_s3_bucket" "demo-3tier-bucket" {
    bucket = "demo-3tier-bucket"

    tags = {
      Name = "demo-3tier-bucket"
    }
}

# Bucket ownership control 추가
resource "aws_s3_bucket_ownership_controls" "demo-3tier-bucket-oc" {
  bucket = aws_s3_bucket.demo-3tier-bucket.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

# ACL 설정: Private only
resource "aws_s3_bucket_acl" "demo-3tier-bucket-acl" {
  bucket = aws_s3_bucket.demo-3tier-bucket.id
  acl = "private"

  depends_on = [ aws_s3_bucket_ownership_controls.demo-3tier-bucket-oc]
}

# OAC 설정: CloudFront통해서만 접근 허용
resource "aws_cloudfront_origin_access_control" "demo-3tier-cf-oac" {
  name = "demo-3tier-cf-oac"
  description = "Grant CloudFront access to s3 bucket: ${aws_s3_bucket.demo-3tier-bucket.id}"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always" // always, never, no-override
  signing_protocol = "sigv4"
}

locals {
  s3_origin_id = "myS3Origin"
}

# CloudFront distribution 생성
resource "aws_cloudfront_distribution" "demo-3tier-cf" {
  origin {
    domain_name = aws_s3_bucket.demo-3tier-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.demo-3tier-cf-oac.id
    origin_id = local.s3_origin_id
  }
  
  enabled = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# S3 bucket policy 생성
resource "aws_s3_bucket_policy" "demo-3tier-bucket-policy" {
  bucket = aws_s3_bucket.demo-3tier-bucket.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json
}

# S3 bucket policy 파일
data "aws_iam_policy_document" "cloudfront_oac_access" {
    statement {
      principals {
        type = "Service"
        identifiers = ["cloudfront.amazonaws.com"]
      }

      actions = [
        "s3:GetObject"
      ]

      resources = [
        aws_s3_bucket.demo-3tier-bucket.arn,
        "${aws_s3_bucket.demo-3tier-bucket.arn}/*"
      ]

      condition {
        test = "StringEquals"
        variable = "AWS:SourceArn"
        values = [aws_cloudfront_distribution.demo-3tier-cf.arn]
      }
    }
}