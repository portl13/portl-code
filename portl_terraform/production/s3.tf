data "template_file" "admin_ui_s3_policy" {
  template = "${file("${path.module}/../templates/originID_CF_S3_policy.json")}"

  vars {
    admin_ui_s3_arn   = "${aws_s3_bucket.admin_ui.arn}"
    CF_access_identity_arn = "${aws_cloudfront_origin_access_identity.production.iam_arn}"
  }
}

resource "aws_s3_bucket_policy" "admin_ui_s3_cf_policy" {
  bucket = "${aws_s3_bucket.admin_ui.id}"
  policy = "${data.template_file.admin_ui_s3_policy.rendered}"
}

resource "aws_s3_bucket" "admin_ui" {
  bucket = "admin.portl.com"
  acl = "private"
  region = "${var.aws_region}"

  tags {
    Name = "Admin UI Bucket"
    Env = "Prod"
  }
}

# Media bucket

data "template_file" "admin_ui_s3_media_policy" {
  template = "${file("${path.module}/../templates/originID_CF_S3_policy.json")}"

  vars {
    admin_ui_s3_arn = "${aws_s3_bucket.admin_ui_media.arn}"
    CF_access_identity_arn = "${aws_cloudfront_origin_access_identity.production_media.iam_arn}"
  }
}

resource "aws_s3_bucket_policy" "admin_ui_media_policy" {
  bucket = "${aws_s3_bucket.admin_ui_media.id}"
  policy = "${data.template_file.admin_ui_s3_media_policy.rendered}"
}

resource "aws_s3_bucket" "admin_ui_media" {
  bucket = "media-${var.app_env}-portl"
  acl = "private"
  region = "${var.aws_region}"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = ["https://${aws_route53_record.admin-ui_cf_portl_private.fqdn}"]
  }

  server_side_encryption_configuration {
    "rule" {
      "apply_server_side_encryption_by_default" {
        sse_algorithm = "AES256"
      }
    }
  }
}
