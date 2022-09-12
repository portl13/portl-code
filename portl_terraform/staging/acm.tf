resource "aws_acm_certificate" "staging" {
  domain_name = "${var.certificate_domain_name}"
  validation_method = "DNS"
}

resource "aws_route53_record" "staging_validation" {
  name = "${aws_acm_certificate.staging.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.staging.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"
  records = ["${aws_acm_certificate.staging.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "staging_validation" {
  certificate_arn = "${aws_acm_certificate.staging.arn}"
  validation_record_fqdns = ["${aws_route53_record.staging_validation.fqdn}"]
}

/*
  Admin-API & Admin-UI
  Admin UI needs to use aws.east as the provider for cloudfront to utilize the certificate
*/


resource "aws_acm_certificate" "admin-ui_staging" {
  provider = "aws.east"
  domain_name = "admin.${var.subdomain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "admin-ui_staging_validation" {
  provider = "aws.east"
  name = "${aws_acm_certificate.admin-ui_staging.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.admin-ui_staging.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"
  records = ["${aws_acm_certificate.admin-ui_staging.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "admin-ui_staging_validation" {
  provider = "aws.east"
  certificate_arn = "${aws_acm_certificate.admin-ui_staging.arn}"
  validation_record_fqdns = ["${aws_route53_record.admin-ui_staging_validation.fqdn}"]
}

resource "aws_acm_certificate" "admin-api_staging" {
  domain_name = "api.admin.${var.subdomain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "admin-api_staging_validation" {
  name = "${aws_acm_certificate.admin-api_staging.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.admin-api_staging.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"
  records = ["${aws_acm_certificate.admin-api_staging.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "admin-api_staging_validation" {
  certificate_arn = "${aws_acm_certificate.admin-api_staging.arn}"
  validation_record_fqdns = ["${aws_route53_record.admin-api_staging_validation.fqdn}"]
}


resource "aws_acm_certificate" "admin-ui-media_staging" {
  provider = "aws.east"
  domain_name = "media.${var.subdomain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "admin-ui-media_staging_validation" {
  provider = "aws.east"
  name = "${aws_acm_certificate.admin-ui-media_staging.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.admin-ui-media_staging.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"
  records = ["${aws_acm_certificate.admin-ui-media_staging.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "admin-ui-media_staging_validation" {
  provider = "aws.east"
  certificate_arn = "${aws_acm_certificate.admin-ui-media_staging.arn}"
  validation_record_fqdns = ["${aws_route53_record.admin-ui-media_staging_validation.fqdn}"]
}
