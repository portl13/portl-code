output "all_kms_key_id" {
  value = "${aws_kms_key.all.id}"
}

output "app_lb_security_group_id" {
  value = "${aws_security_group.app_lb.id}"
}

output "ansible_management_security_group_id" {
  value = "${aws_security_group.ansible_management.id}"
}

output "external_route_table_id" {
  value = "${module.aws_vpc.route_table_ids["external"]}"
}

output "internal_route_table_id" {
  value = "${module.aws_vpc.route_table_ids["internal"]}"
}

output "production_subnet_cidr" {
  value = "${var.production_subnet_cidr}"
}

output "route53_public_zone_id" {
  value = "${data.aws_route53_zone.public.zone_id}"
}

output "route53_private_zone_id" {
  value = "${data.aws_route53_zone.private.zone_id}"
}

output "tools_subnet_az" {
  value = "${aws_subnet.tools_subnet.availability_zone}"
}

output "tools_subnet_id" {
  value = "${aws_subnet.tools_subnet.id}"
}

output "tools_subnet_cidr_block" {
  value = "${aws_subnet.tools_subnet.cidr_block}"
}

output "sns_topic_pagerduty_name" {
  value = "${aws_sns_topic.pagerduty.name}"
}

output "vpc_id" {
  value = "${module.aws_vpc.id}"
}

output "vpc_external_subnet_azs" {
  value = "${module.aws_vpc.subnet_azs}"
}

output "vpc_external_subnet_ids" {
  value = "${module.aws_vpc.subnet_ids}"
}

output "vpc_external_subnet_cidrs" {
  value = "${module.aws_vpc.subnet_cidrs}"
}

output "vpc_security_groups" {
  value = "${module.aws_vpc.security_group_ids}"
}

output "zabbix_agent_security_group_id" {
  value = "${aws_security_group.zabbix_agent.id}"
}

output "vpn_subnet_access" {
  value = "${aws_security_group.vpn_subnet_access.id}"
}

output "web_protected_waf_acl_id" {
  value = "${aws_waf_web_acl.web_protected.id}"
}

