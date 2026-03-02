resource "aws_s3_bucket" "dev_bucket" {
  bucket = var.bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "dev_bucket_public_access_block" {
  bucket = aws_s3_bucket.dev_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "dev_bucket_access_control" {
  name                              = "dev-bucket-access-control"
  description                       = "Policy for dev bucket access control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "allow_cloudfront_access" {
  bucket = aws_s3_bucket.dev_bucket.id
  depends_on = [ aws_s3_bucket_public_access_block.dev_bucket_public_access_block ]

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "${aws_s3_bucket.dev_bucket.arn}/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceArn": "${aws_cloudfront_distribution.dev_s3_distribution.arn}"
        }
      }
    }
  ]
})
}



data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["123456789012"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.dev_bucket.arn,
      "${aws_s3_bucket.dev_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_object" "object" {

  for_each = fileset("${path.module}/www", "**/*")
  bucket = aws_s3_bucket.dev_bucket.id
  key    = each.value
  source = "${path.module}/www/${each.value}"

  etag = filemd5("${path.module}/www/${each.value}")

  content_type = lookup({
    "html" = "text/html"
    "css" = "text/css"
    "js" = "text/javascript"
    "png" = "image/png"
    "jpg" = "image/jpeg"
    "gif" = "image/gif"
    "svg" = "image/svg+xml"
    "json" = "application/json"
    "txt" = "text/plain"
    "ico" = "image/x-icon"
    "woff" = "application/font-woff"
    "woff2" = "application/font-woff2"
    "ttf" = "application/font-ttf"
    "eot" = "application/vnd.ms-fontobject"
    }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

resource "aws_cloudfront_distribution" "dev_s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.dev_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.dev_bucket_access_control.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.environment} distribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "NG"]
    }
  }

  tags = local.common_tags

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}