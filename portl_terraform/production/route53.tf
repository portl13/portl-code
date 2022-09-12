resource "aws_route53_record" "mongo1" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "mongo1.prod.${var.base_domain_name}"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.mongo1_m5.private_ip}",
  ]
}

resource "aws_route53_record" "mongo2" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "mongo2.prod.${var.base_domain_name}"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.mongo2_m5.private_ip}",
  ]
}

resource "aws_route53_record" "mongo3" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "mongo3.prod.${var.base_domain_name}"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.mongo3_m5.private_ip}",
  ]
}

resource "aws_route53_record" "mongo1_m5" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "mongo1.m5.prod.${var.base_domain_name}"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.mongo1_m5.private_ip}",
  ]
}

resource "aws_route53_record" "mongo2_m5" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "mongo2.m5.prod.${var.base_domain_name}"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.mongo2_m5.private_ip}",
  ]
}

resource "aws_route53_record" "mongo3_m5" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "mongo3.m5.prod.${var.base_domain_name}"
  type    = "A"
  ttl     = "30"

  records = [
    "${aws_instance.mongo3_m5.private_ip}",
  ]
}

resource "aws_route53_record" "api_portl_com_private" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name = "${var.certificate_domain_name}"
  type = "A"

  alias {
    name = "${aws_lb.production.dns_name}"
    evaluate_target_health = false
    zone_id = "${aws_lb.production.zone_id}"
  }
}

resource "aws_route53_record" "api_portl_com_public" {
  zone_id = "${data.aws_route53_zone.public.zone_id}"
  name = "${var.certificate_domain_name}"
  type = "A"

  alias {
    name = "${aws_lb.production.dns_name}"
    evaluate_target_health = false
    zone_id = "${aws_lb.production.zone_id}"
  }
}

resource "aws_route53_record" "portl_com_public" {
  zone_id = "${data.aws_route53_zone.public.zone_id}"
  name = "portl.com"
  type = "A"
  ttl = 300

  records = ["${var.lunarpages_portl_com_ip}"]
}

resource "aws_route53_record" "portl_com_private" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name = "portl.com"
  type = "A"
  ttl = 300

  records = ["${var.lunarpages_portl_com_ip}"]
}

/*
  Admin-api records
*/

resource "aws_route53_record" "admin-api_portl_com_public" {
  name = "api.admin.${var.subdomain}"
  type = "A"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"

  alias {
    name = "${aws_lb.admin-api.dns_name}"
    evaluate_target_health = false
    zone_id = "${aws_lb.admin-api.zone_id}"
  }
}

resource "aws_route53_record" "admin-api_portl_com_private" {
  name = "api.admin.${var.subdomain}"
  type = "A"
  zone_id = "${data.terraform_remote_state.root.route53_private_zone_id}"

  alias {
    name = "${aws_lb.admin-api.dns_name}"
    evaluate_target_health = false
    zone_id = "${aws_lb.admin-api.zone_id}"
  }
}

/*
  Admin-ui records
*/

/*
resource "aws_route53_record" "admin-ui_portl_com_private" {
  name = "admin.${var.subdomain}"
  type = "CNAME"
  zone_id = "${data.aws_route53_zone.private.zone_id}"

  ttl = "300"
  records = ["${aws_s3_bucket.admin_ui.website_domain}"]
}
*/

resource "aws_route53_record" "admin-ui_cf_portl_private" {
  name = "admin.${var.subdomain}"
  type = "A"
  zone_id = "${data.aws_route53_zone.private.zone_id}"

  alias {
    name = "${aws_cloudfront_distribution.admin_ui.domain_name}"
    evaluate_target_health = false
    zone_id = "${aws_cloudfront_distribution.admin_ui.hosted_zone_id}"
  }

}

resource "aws_route53_record" "jump_box" {
  name = "jump.${var.base_domain_name}"
  type = "A"
  ttl  = 300
  records = ["${aws_instance.task.private_ip}"]
  zone_id = "${data.terraform_remote_state.root.route53_private_zone_id}"
}

resource "aws_route53_record" "task_private" {
  name = "task.prod.${var.base_domain_name}"
  type = "A"
  ttl  = 300
  records = ["${aws_instance.task.private_ip}"]
  zone_id = "${data.terraform_remote_state.root.route53_private_zone_id}"
}


resource "aws_route53_record" "admin-ui-media_portl_com_public" {
  name = "media.${var.base_domain_name}"
  type = "A"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"

  alias {
    name = "${aws_cloudfront_distribution.admin_ui_media.domain_name}"
    evaluate_target_health = false
    zone_id = "${aws_cloudfront_distribution.admin_ui_media.hosted_zone_id}"
  }
}

resource "aws_route53_record" "admin-ui-media_portl_com_private" {
  name = "media.${var.base_domain_name}"
  type = "A"
  zone_id = "${data.terraform_remote_state.root.route53_private_zone_id}"

  alias {
    name = "${aws_cloudfront_distribution.admin_ui_media.domain_name}"
    evaluate_target_health = false
    zone_id = "${aws_cloudfront_distribution.admin_ui_media.hosted_zone_id}"
  }
}