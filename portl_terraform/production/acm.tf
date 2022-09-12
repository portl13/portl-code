resource "aws_acm_certificate" "production" {
  domain_name = "${var.certificate_domain_name}"
  validation_method = "DNS"
}

resource "aws_route53_record" "production_validation" {
  name = "${aws_acm_certificate.production.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.production.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"
  records = ["${aws_acm_certificate.production.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "production_validation" {
  certificate_arn = "${aws_acm_certificate.production.arn}"
  validation_record_fqdns = ["${aws_route53_record.production_validation.fqdn}"]
}

/*
  Admin-API & Admin-UI
  Admin UI needs to use aws.east as the provider for cloudfront to utilize the certificate
*/

resource "aws_acm_certificate" "admin-ui" {
  provider = "aws.east"
  domain_name = "admin.${var.subdomain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "admin-ui_validation" {
  provider = "aws.east"
  name = "${aws_acm_certificate.admin-ui.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.admin-ui.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"
  records = ["${aws_acm_certificate.admin-ui.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "admin-ui_validation" {
  provider = "aws.east"
  certificate_arn = "${aws_acm_certificate.admin-ui.arn}"
  validation_record_fqdns = ["${aws_route53_record.admin-ui_validation.fqdn}"]
}


resource "aws_acm_certificate" "admin-api" {
  domain_name = "api.admin.${var.subdomain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "admin-api_validation" {
  name = "${aws_acm_certificate.admin-api.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.admin-api.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"
  records = ["${aws_acm_certificate.admin-api.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "admin-api_validation" {
  certificate_arn = "${aws_acm_certificate.admin-api.arn}"
  validation_record_fqdns = ["${aws_route53_record.admin-api_validation.fqdn}"]
}

# media s3 bucket acm

resource "aws_acm_certificate" "admin-ui-media" {
  provider = "aws.east"
  domain_name = "media.${var.subdomain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "admin-ui-media_validation" {
  provider = "aws.east"
  name = "${aws_acm_certificate.admin-ui-media.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.admin-ui-media.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"
  records = ["${aws_acm_certificate.admin-ui-media.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "admin-ui-media_validation" {
  provider = "aws.east"
  certificate_arn = "${aws_acm_certificate.admin-ui-media.arn}"
  validation_record_fqdns = ["${aws_route53_record.admin-ui-media_validation.fqdn}"]
}
