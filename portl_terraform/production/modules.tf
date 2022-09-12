/* Production ECS Cluster */
module "production_ecs" {
  source = "git::ssh://git@stash.concentricsky.com/tfm/aws_ecs_cluster.git?ref=v0.6.0"

  asg_min_size           = 3
  asg_max_size           = 3

  aws_key_name           = "${var.aws_key_name}"
  aws_region             = "${var.aws_region}"
  cluster_name           = "${var.project_name}_production"
  ecs_ami                = "ami-00d4f478"
  environment_name       = "production"
  environment_short_name = "prod"
  project_name           = "${var.project_name}"
  graylog_server         = "${var.graylog_server}"
  instance_type          = "c5.large"

  route_table_id    = "${data.terraform_remote_state.root.internal_route_table_id}"
  subnet_cidr       = "${data.terraform_remote_state.root.production_subnet_cidr}"

  vpc_id            = "${data.terraform_remote_state.root.vpc_id}"
}
