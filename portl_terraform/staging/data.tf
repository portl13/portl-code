data "aws_caller_identity" "current" {}

/*
  Hydrating security_groups from terraform_root_state
*/

/* Hydrate 'ecs_cluster' security group */
data "aws_security_group" "ecs_cluster" {
  id = "${module.staging_ecs.ecs_cluster_security_group_id}"
}

data "aws_security_group" "vpn_subnet_access" {
  id = "${data.terraform_remote_state.root.vpn_subnet_access}"
}

data "aws_security_group" "web_protected" {
  id = "${data.terraform_remote_state.root.vpc_security_groups["web_protected"]}"
}

data "aws_security_group" "csky_internal" {
  id = "${data.terraform_remote_state.root.vpc_security_groups["csky_internal"]}"
}

data "aws_security_group" "web_external" {
  id = "${data.terraform_remote_state.root.vpc_security_groups["web_external"]}"
}

/* Hydrate 'zabbix_agent' security group */
data "aws_security_group" "zabbix_agent" {
  id = "${data.terraform_remote_state.root.zabbix_agent_security_group_id}"
}


/*
  Hydrating subnets from terraform_root_state
*/
data "aws_vpc" "default" {
  id = "${data.terraform_remote_state.root.vpc_id}"
}

data "aws_subnet" "nat_a" {
  id = "${data.terraform_remote_state.root.vpc_external_subnet_ids["nat_a"]}"
}
data "aws_subnet" "nat_b" {
  id = "${data.terraform_remote_state.root.vpc_external_subnet_ids["nat_b"]}"
}
data "aws_subnet" "nat_c" {
  id = "${data.terraform_remote_state.root.vpc_external_subnet_ids["nat_c"]}"
}

data "aws_subnet" "ecs_subnet_a" {
  id = "${module.staging_ecs.ecs_subnet_a_id}"
}

data "aws_subnet" "ecs_subnet_b" {
  id = "${module.staging_ecs.ecs_subnet_b_id}"
}

data "aws_subnet" "ecs_subnet_c" {
  id = "${module.staging_ecs.ecs_subnet_c_id}"
}

data "aws_subnet" "tools_subnet" {
  id = "${data.terraform_remote_state.root.tools_subnet_id}"
}

data "aws_route_table" "internal" {
  route_table_id = "${data.terraform_remote_state.root.internal_route_table_id}"
}

data "aws_route53_zone" "private" {
  name = "portl.com"
  private_zone = true
}

/*
 Below is a hack to get auto scaling working before the ECS module can be split out into the terraform environments
 directly
*/
data "aws_security_group" "ecs_container" {
  id = "sg-a64f5bd8"
}

data "aws_iam_instance_profile" "ecs_staging" {
  name = "portl_staging_instance_profile"
}


/* Grab production_ecs instance profile sns_topic */
data "aws_iam_instance_profile" "instance_profile" {
  name = "${module.staging_ecs.ec2_instance_profile_name}"
}

/* Grab latest ecs_ami */
data "aws_ami" "ecs_ami" {
  most_recent = true
  owners = ["amazon"]

  name_regex = "^amzn-ami-.*.e-amazon-ecs-optimized$"
}

/*
  IAM
*/
data "aws_iam_user" "jenkins" {
  user_name = "jenkins"
}

data "aws_iam_user" "ansible" {
  user_name = "ansible"
}

data "aws_kms_key" "all" {
  key_id = "${data.terraform_remote_state.root.all_kms_key_id}"
}