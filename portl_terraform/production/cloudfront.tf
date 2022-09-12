resource "aws_cloudfront_origin_access_identity" "production" {
  comment = "${title(var.app_name)} ${var.app_env} CloudFront"
}

resource "aws_cloudfront_distribution" "admin_ui" {
  aliases = ["${aws_acm_certificate.admin-ui.domain_name}"]
  default_root_object = "index.html"
  enabled         = true
  is_ipv6_enabled = true
  web_acl_id = "${data.terraform_remote_state.root.web_protected_waf_acl_id}"

  "origin" {
    domain_name = "${aws_s3_bucket.admin_ui.bucket_domain_name}"
    origin_id = "S3-${aws_s3_bucket.admin_ui.id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.production.cloudfront_access_identity_path}"
    }
  }
  "default_cache_behavior" {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${aws_s3_bucket.admin_ui.id}"

    "forwarded_values" {
      "cookies" {
        forward = "none"
      }
      query_string = false
    }

    viewer_protocol_policy  = "redirect-to-https"
    min_ttl                 = 0
    default_ttl             = 3600
    max_ttl                 = 86400
  }

  "restrictions" {
    "geo_restriction" {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_code = 403
    response_code = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code = 404
    response_code = 200
    response_page_path = "/index.html"
  }

  "viewer_certificate" {
    acm_certificate_arn = "${aws_acm_certificate_validation.admin-ui_validation.certificate_arn}"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
  tags {
    App = "admin_ui"
    Environment = "${var.app_env}"
    Name = "admin_ui"
  }

}

# media s3 bucket

resource "aws_cloudfront_origin_access_identity" "production_media" {
  comment ="${title(var.app_name)} ${var.app_env} CloudFront Media"
}

resource "aws_cloudfront_distribution" "admin_ui_media" {
  aliases = ["${aws_acm_certificate.admin-ui-media.domain_name}"]
  default_root_object = "index.html"
  enabled         = true
  is_ipv6_enabled = true

  "origin" {
    domain_name = "${aws_s3_bucket.admin_ui_media.bucket_domain_name}"
    origin_id = "S3-${aws_s3_bucket.admin_ui_media.id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.production_media.cloudfront_access_identity_path}"
    }
  }
  "default_cache_behavior" {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${aws_s3_bucket.admin_ui_media.id}"

    "forwarded_values" {
      "cookies" {
        forward = "none"
      }
      query_string = false
    }

    viewer_protocol_policy  = "redirect-to-https"
    min_ttl                 = 0
    default_ttl             = 3600
    max_ttl                 = 86400
  }

  "restrictions" {
    "geo_restriction" {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_code = 403
    response_code = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code = 404
    response_code = 200
    response_page_path = "/index.html"
  }

  "viewer_certificate" {
    acm_certificate_arn = "${aws_acm_certificate_validation.admin-ui-media_validation.certificate_arn}"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
  tags {
    App = "admin_ui_media"
    Environment = "production"
    Name = "admin_ui_media"
  }
}
