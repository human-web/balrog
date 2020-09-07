
resource "aws_s3_bucket" "repo-ghosterybrowser-com" {
  bucket = "repo.ghosterybrowser.com"
  acl    = "private"

  tags = {
    Owner = "sam@cliqz.com"
    Project = "desktop-browser"
  }
}

resource "aws_cloudfront_distribution" "repo-ghosterybrowser-com" {
  origin {
    domain_name = aws_s3_bucket.repo-ghosterybrowser-com.bucket_regional_domain_name
    origin_id   = "repo-ghosterybrowser-com"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["repo.ghosterybrowser.com"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "repo-ghosterybrowser-com"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Owner = "sam@cliqz.com"
    Project = "desktop-browser"
  }

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:470602773899:certificate/cff359d7-9c7c-40f8-ab93-458a0335b624"
    ssl_support_method = "sni-only"
  }
}

resource "aws_route53_record" "repo-ghosterybrowser-com" {
  zone_id = "Z2N6ATIWASS8WR"
  name    = "repo.ghosterybrowser.com"
  type    = "A"

  alias {
    name = aws_cloudfront_distribution.repo-ghosterybrowser-com.domain_name
    zone_id = aws_cloudfront_distribution.repo-ghosterybrowser-com.hosted_zone_id
    evaluate_target_health = true
  }
}