data "aws_route53_zone" "public" {
  name = "${var.base_domain_name}"
}

data "aws_route53_zone" "private" {
  name = "${var.base_domain_name}"
  private_zone = true
}

resource "aws_route53_record" "management" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "management.${var.base_domain_name}"
  type    = "A"
  ttl     = "300"

  records = [
    "${aws_instance.management.private_ip}",
  ]
}

resource "aws_route53_record" "jenkins" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "jenkins.${var.base_domain_name}"
  type    = "A"

  alias {
    name = "${aws_route53_record.management.name}"
    evaluate_target_health = false
    zone_id = "${data.aws_route53_zone.private.zone_id}"
  }
}

resource "aws_route53_record" "haversack" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "haversack.${var.base_domain_name}"
  type    = "A"

  alias {
    name = "${aws_route53_record.management.name}"
    evaluate_target_health = false
    zone_id = "${data.aws_route53_zone.private.zone_id}"
  }
}

resource "aws_route53_record" "zabbix" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "zabbix.${var.base_domain_name}"
  type    = "A"

  alias {
    name = "${aws_route53_record.management.name}"
    evaluate_target_health = false
    zone_id = "${data.aws_route53_zone.private.zone_id}"
  }
}


resource "aws_route53_record" "nexus" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "nexus.${var.base_domain_name}"
  type    = "A"
  ttl     = "300"

  records = [
    "${aws_instance.nexus.private_ip}",
  ]
}

resource "aws_route53_record" "logs" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "logs.${var.base_domain_name}"
  type    = "A"
  ttl     = "300"

  records = [
    "${aws_instance.logs.private_ip}",
  ]
}

resource "aws_route53_record" "mongo_agent" {
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "mongo-agent.${var.base_domain_name}"
  type    = "A"
  ttl     = "300"

  records = [
    "${aws_instance.mongo_agent.private_ip}",
  ]
}

resource "aws_route53_record" "grafana" {
  name    = "grafana.${var.base_domain_name}"
  type    = "A"
  ttl     = "300"
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  records = [
    "${aws_instance.grafana.private_ip}"
  ]
}

resource "aws_route53_record" "influx" {
  name    = "influxdb.${var.base_domain_name}"
  type    = "A"
  ttl     = "300"
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  records = [
    "${aws_instance.influx.private_ip}"
  ]
}

resource "aws_route53_record" "vpn" {
  name    = "vpn.${var.base_domain_name}"
  type    = "A"
  ttl     = "300"
  zone_id = "${data.aws_route53_zone.public.zone_id}"
  records = [
    "${aws_instance.pfsense.public_ip}"
  ]
}

resource "aws_route53_record" "vpn-web-interface" {
  name    = "vpn.${var.base_domain_name}"
  type    = "A"
  ttl     = "300"
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  records = [
    "${aws_instance.pfsense.private_ip}"
  ]
}
