/*
  General Parameters
*/
resource "aws_ssm_parameter" "aws_ecs_cluster" {
  name = "/${var.app_name}/${var.app_env}/aws_ecs_cluster"
  overwrite = true
  type = "String"
  value = "${module.staging_ecs.ecs_cluster_name}"
}

resource "aws_ssm_parameter" "aws_ecs_service_role" {
  name = "/${var.app_name}/${var.app_env}/aws_ecs_service_role"
  overwrite = true
  type = "String"
  value = "${module.staging_ecs.ecs_service_role_arn}"
}

resource "aws_ssm_parameter" "aws_kms_key_id" {
  name = "/${var.app_name}/${var.app_env}/aws_kms_key_id"
  overwrite = true
  type = "String"
  value = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "aws_task_role_arn" {
  name = "/${var.app_name}/${var.app_env}/aws_task_role_arn"
  overwrite = true
  type = "String"
  value = "${aws_iam_role.portl_staging.arn}"
}

resource "aws_ssm_parameter" "mongodb_hosts" {
  name = "/${var.app_name}/${var.app_env}/mongodb_hosts"
  overwrite = true
  type = "StringList"
  value = "${aws_route53_record.mongo1.name},${aws_route53_record.mongo2.name},${aws_route53_record.mongo3.name}"
}

/*
  API Parameters
*/

resource "aws_ssm_parameter" "api_aws_target_group_arn" {
  name = "/${var.app_name}/${var.app_env}/api/aws_target_group_arn"
  overwrite = true
  type = "String"
  value = "${aws_alb_target_group.staging.arn}"
}

resource "aws_ssm_parameter" "api_aws_ecs_cluster" {
  name = "/${var.app_name}/${var.app_env}/api/aws_ecs_cluster"
  overwrite = true
  type = "String"
  value = "${module.staging_ecs.ecs_cluster_name}"
}

resource "aws_ssm_parameter" "api_docker_image_name" {
  name = "/${var.app_name}/${var.app_env}/api/docker_image_name"
  overwrite = true
  type = "String"
  value = "portl-api"
}

resource "aws_ssm_parameter" "api_docker_memory" {
  name = "/${var.app_name}/${var.app_env}/api/docker_memory"
  overwrite = true
  type = "String"
  value = "3072"
}

resource "aws_ssm_parameter" "api_docker_desired_count" {
  name = "/${var.app_name}/${var.app_env}/api/docker_desired_count"
  overwrite = true
  type = "String"
  value = "1"
}

/*
  Admin API Parameters
*/
resource "aws_ssm_parameter" "admin_api_aws_target_group_arn" {
  name = "/${var.app_name}/${var.app_env}/admin-api/aws_target_group_arn"
  overwrite = true
  type = "String"
  value = "${aws_alb_target_group.admin-api-staging.arn}"
}

resource "aws_ssm_parameter" "admin_api_aws_ecs_cluster" {
  name = "/${var.app_name}/${var.app_env}/admin-api/aws_ecs_cluster"
  overwrite = true
  type = "String"
  value = "${aws_ecs_cluster.admin_api.name}"
}

resource "aws_ssm_parameter" "admin_api_aws_cloudfront_distribution_id" {
  name = "/${var.app_name}/${var.app_env}/admin-api/aws_cloudfront_distribution_id"
  overwrite = true
  type = "String"
  value = "${aws_cloudfront_distribution.admin_ui.id}"
}

resource "aws_ssm_parameter" "admin_api_aws_s3_bucket" {
  name = "/${var.app_name}/${var.app_env}/admin-api/aws_s3_bucket"
  overwrite = true
  type = "String"
  value = "${aws_s3_bucket.admin_ui.bucket}"
}

resource "aws_ssm_parameter" "admin_api_docker_image_name" {
  name = "/${var.app_name}/${var.app_env}/admin-api/docker_image_name"
  overwrite = true
  type = "String"
  value = "admin-api"
}
