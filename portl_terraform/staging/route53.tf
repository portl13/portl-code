resource "aws_route53_record" "mongo1" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "mongo1.${var.base_domain_name}"
  type    = "A"
  ttl     = "300"

  records = [
    "${aws_instance.mongo1m5.private_ip}",
  ]
}

resource "aws_route53_record" "mongo2" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "mongo2.${var.base_domain_name}"
  type    = "A"
  ttl     = "300"

  records = [
    "${aws_instance.mongo2m5.private_ip}",
  ]
}

resource "aws_route53_record" "mongo3" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "mongo3.${var.base_domain_name}"
  type    = "A"
  ttl     = "300"

  records = [
    "${aws_instance.mongo3m5.private_ip}",
  ]
}

//resource "aws_route53_record" "mongo3_m5" {
//  zone_id = "${data.aws_route53_zone.private.zone_id}"
//  name    = "mongo3-m5.${var.base_domain_name}"
//  type    = "A"
//  ttl     = "300"
//
//  records = [
//    "${aws_instance.mongo3_m5.private_ip}",
//  ]
//}
//
//resource "aws_route53_record" "mongo4" {
//  zone_id = "${data.aws_route53_zone.private.zone_id}"
//  name    = "mongo4.${var.base_domain_name}"
//  type    = "A"
//  ttl     = "300"
//
//  records = [
//    "${aws_instance.mongo3_m5.private_ip}",
//  ]
//}
//
//resource "aws_route53_record" "mongo5" {
//  zone_id = "${data.aws_route53_zone.private.zone_id}"
//  name    = "mongo5.${var.base_domain_name}"
//  type    = "A"
//  ttl     = "300"
//
//  records = [
//    "${aws_instance.mongo5.private_ip}",
//  ]
//}
//
//resource "aws_route53_record" "mongo6" {
//  zone_id = "${data.aws_route53_zone.private.zone_id}"
//  name    = "mongo6.${var.base_domain_name}"
//  type    = "A"
//  ttl     = "300"
//
//  records = [
//    "${aws_instance.mongo6.private_ip}",
//  ]
//}
//
resource "aws_route53_record" "api_staging_portl_com_private" {
  name = "${var.certificate_domain_name}"
  type = "A"
  zone_id = "${data.aws_route53_zone.private.zone_id}"

  alias {
    name = "${aws_lb.staging.dns_name}"
    evaluate_target_health = false
    zone_id = "${aws_lb.staging.zone_id}"
  }
}

resource "aws_route53_record" "api_staging_portl_com_public" {
  name = "${var.certificate_domain_name}"
  type = "A"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"

  alias {
    name = "${aws_lb.staging.dns_name}"
    evaluate_target_health = false
    zone_id = "${aws_lb.staging.zone_id}"
  }
}


/*
  Admin-api records
*/

resource "aws_route53_record" "admin-api_staging_portl_com_public" {
  name = "api.admin.staging.portl.com"
  type = "A"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"

  alias {
    name = "${aws_lb.admin-api-staging.dns_name}"
    evaluate_target_health = false
    zone_id = "${aws_lb.admin-api-staging.zone_id}"
  }
}

resource "aws_route53_record" "admin-api_staging_portl_com_private" {
  name = "api.admin.staging.portl.com"
  type = "A"
  zone_id = "${data.aws_route53_zone.private.zone_id}"

  alias {
    name = "${aws_lb.admin-api-staging.dns_name}"
    evaluate_target_health = false
    zone_id = "${aws_lb.admin-api-staging.zone_id}"
  }
}

/*
  Admin-ui records
*/

resource "aws_route53_record" "admin-ui_staging_portl_com_private" {
  name = "admin.staging.portl.com"
  type = "A"
  zone_id = "${data.aws_route53_zone.private.zone_id}"

  alias {
    name = "${aws_cloudfront_distribution.admin_ui.domain_name}"
    evaluate_target_health = false
    zone_id = "${aws_cloudfront_distribution.admin_ui.hosted_zone_id}"
  }
}

resource "aws_route53_record" "admin-ui_staging_portl_com_public" {
  name = "admin.staging.portl.com"
  type = "A"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"

  alias {
    name = "${aws_cloudfront_distribution.admin_ui.domain_name}"
    evaluate_target_health = false
    zone_id = "${aws_cloudfront_distribution.admin_ui.hosted_zone_id}"
  }
}

resource "aws_route53_record" "jump_box" {
  name = "jump.${var.subdomain}"
  type = "A"
  ttl  = 300
  records = ["${aws_instance.task.private_ip}"]
  zone_id = "${data.aws_route53_zone.private.zone_id}"
}

/* Create task node */
resource "aws_route53_record" "task_private" {
  name = "task.${var.subdomain}"
  type = "A"
  ttl  = 300
  records = ["${aws_instance.task.private_ip}"]
  zone_id = "${data.aws_route53_zone.private.zone_id}"
}
 resource "aws_route53_record" "admin-ui-media_staging_portl_com_public" {
  name = "media.${var.base_domain_name}"
  type = "A"
  zone_id = "${data.terraform_remote_state.root.route53_public_zone_id}"

  alias {
    name = "${aws_cloudfront_distribution.admin_ui_media.domain_name}"
    evaluate_target_health = false
    zone_id = "${aws_cloudfront_distribution.admin_ui_media.hosted_zone_id}"
  }
}

 resource "aws_route53_record" "admin-ui-media_staging_portl_com_private" {
  name = "media.${var.base_domain_name}"
  type = "A"
  zone_id = "${data.terraform_remote_state.root.route53_private_zone_id}"

  alias {
    name = "${aws_cloudfront_distribution.admin_ui_media.domain_name}"
    evaluate_target_health = false
    zone_id = "${aws_cloudfront_distribution.admin_ui_media.hosted_zone_id}"
  }
}
