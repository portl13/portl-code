resource "aws_waf_ipset" "csky_office" {
  name = "CSkyOffice"

  ip_set_descriptors {
    type = "IPV4"
    value = "23.130.160.0/24"
  }

  ip_set_descriptors {
    type = "IPV4"
    value = "${aws_instance.pfsense.public_ip}/32"
  }
}

resource "aws_waf_rule" "wafrule" {
  depends_on  = ["aws_waf_ipset.csky_office"]
  name        = "allow_csky_office"
  metric_name = "allowCskyOffice"

  predicates {
    data_id = "${aws_waf_ipset.csky_office.id}"
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_web_acl" "web_protected" {
  depends_on  = ["aws_waf_ipset.csky_office", "aws_waf_rule.wafrule"]
  name        = "web_protected"
  metric_name = "webProtected"

  "default_action" {
    type = "BLOCK"
  }

  rules {
    action {
      type = "ALLOW"
    }

    priority = 1
    rule_id  = "${aws_waf_rule.wafrule.id}"
    type     = "REGULAR"
  }
}