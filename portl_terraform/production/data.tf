data "aws_caller_identity" "current" {}


/*
  Security Groups
*/

/* Hydrate 'ecs_cluster' security group */
data "aws_security_group" "ecs_cluster" {
  id = "${module.production_ecs.ecs_cluster_security_group_id}"
}

/* Hydrate 'csky_internal' security group */
data "aws_security_group" "csky_internal" {
  id = "${data.terraform_remote_state.root.vpc_security_groups["csky_internal"]}"
}

/* Hydrate 'web_external' security group */
data "aws_security_group" "web_alb" {
  id = "${data.terraform_remote_state.root.vpc_security_groups["web_alb"]}"
}

/* Hydrate 'web_external' security group */
data "aws_security_group" "web_external" {
  id = "${data.terraform_remote_state.root.vpc_security_groups["web_external"]}"
}

/* Hydrate 'web_protected' security group */
data "aws_security_group" "web_protected" {
  id = "${data.terraform_remote_state.root.vpc_security_groups["web_protected"]}"
}

/* Hydrate 'pfsense_vpn' security group */
data "aws_security_group" "vpn_subnet_access" {
  id = "${data.terraform_remote_state.root.vpn_subnet_access}"
}

/* Hydrate 'zabbix_agent' security group */
data "aws_security_group" "zabbix_agent" {
  id = "${data.terraform_remote_state.root.zabbix_agent_security_group_id}"
}

/*
  Hydrating subnets from terraform_root_state
*/
/* Hydrate 'nat_a' Subnet Group */
data "aws_subnet" "nat_a" {
  id = "${data.terraform_remote_state.root.vpc_external_subnet_ids["nat_a"]}"
}

/* Hydrate 'nat_b' Subnet Group */
data "aws_subnet" "nat_b" {
  id = "${data.terraform_remote_state.root.vpc_external_subnet_ids["nat_b"]}"
}

/* Hydrate 'nat_c' Subnet Group */
data "aws_subnet" "nat_c" {
  id = "${data.terraform_remote_state.root.vpc_external_subnet_ids["nat_c"]}"
}

/* Hydrate 'ecs_subnet_a' Subnet Group */
data "aws_subnet" "ecs_subnet_a" {
  id = "${module.production_ecs.ecs_subnet_a_id}"
}

/* Hydrate 'ecs_subnet_b' Subnet Group */
data "aws_subnet" "ecs_subnet_b" {
  id = "${module.production_ecs.ecs_subnet_b_id}"
}

/* Hydrate 'ecs_subnet_c' Subnet Group */
data "aws_subnet" "ecs_subnet_c" {
  id = "${module.production_ecs.ecs_subnet_c_id}"
}

/* Hydrate 'tools_subnet' Subnet Group */
data "aws_subnet" "tools_subnet" {
  id = "${data.terraform_remote_state.root.tools_subnet_id}"
}


/*
  Route53 Zones
*/

/* Hydrate 'portl.com' Public Route53 Zone */
data "aws_route53_zone" "public" {
  name = "portl.com"
}

/* Hydrate 'portl.com' Private Route53 Zone */
data "aws_route53_zone" "private" {
  name = "portl.com"
  private_zone = true
}

/* Grab production_ecs instance profile sns_topic */
data "aws_iam_instance_profile" "instance_profile" {
  name = "${module.production_ecs.ec2_instance_profile_name}"
}


/* Grab latest ecs_ami */
data "aws_ami" "ecs_ami" {
  most_recent = true
  owners = ["amazon"]

  name_regex = "^amzn-ami-.*.e-amazon-ecs-optimized$"
}


/* Grab pagerduty sns_topic */
data "aws_sns_topic" "pagerduty" {
  name = "${data.terraform_remote_state.root.sns_topic_pagerduty_name}"
}

/*
  IAM
*/
data "aws_iam_user" "ansible" {
  user_name = "ansible"
}

data "aws_iam_user" "jenkins" {
  user_name = "jenkins"
}

data "aws_kms_key" "all" {
  key_id = "${data.terraform_remote_state.root.all_kms_key_id}"
}