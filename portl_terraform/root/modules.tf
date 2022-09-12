/*
  Create VPC
*/
module "aws_vpc" {
  source = "git::ssh://git@stash.concentricsky.com/tfm/aws_vpc.git"

  aws_region = "${var.aws_region}"

  vpc_name   = "portl_${var.aws_region}_tf"
  vpc_cidr   = "${var.vpc_cidr}"
}

/*
  Create a ECR Respositories
*/
module "ecr_portl_api" {
  source = "git::ssh://git@stash.concentricsky.com/tfm/aws_ecr"
  repository_name = "portl-api"
}

module "ecr_admin_api" {
  source = "git::ssh://git@stash.concentricsky.com/tfm/aws_ecr"
  repository_name = "admin-api"
}

module "ecr_base" {
  source = "git::ssh://git@stash.concentricsky.com/tfm/aws_ecr"
  repository_name = "base"
}

module "ecr_oracle_java" {
  source = "git::ssh://git@stash.concentricsky.com/tfm/aws_ecr"
  repository_name = "oracle_java"
}
