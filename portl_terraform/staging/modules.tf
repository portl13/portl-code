/*
  Staging ECS Cluster
*/
module "staging_ecs" {
  source = "git::ssh://git@stash.concentricsky.com/tfm/aws_ecs_cluster.git?ref=v0.6.0"

  asg_max_size            = "3"
  asg_min_size            = "3"

  aws_key_name            = "${var.aws_key_name}"
  aws_region              = "${var.aws_region}"
  cluster_name            = "${var.app_name}_${var.app_env}"
  ecs_ami                 = "${var.aws_base_ecs_ami}"
  environment_name        = "staging"
  environment_short_name  = "stage"
  project_name            = "${var.app_name}"
  instance_type           = "c5.large"
  graylog_server          = "${var.graylog_server}"

  route_table_id          = "${data.aws_route_table.internal.id}"
  subnet_cidr             = "${var.subnet_cidr}"

  vpc_id                  = "${data.aws_vpc.default.id}"
}
