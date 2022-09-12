/*
  General Parameters
*/
resource "aws_ssm_parameter" "aws_ecs_cluster_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/public/aws_ecs_cluster"
  overwrite = true
  type = "String"
  value = "${module.staging_ecs.ecs_cluster_name}"
}

resource "aws_ssm_parameter" "aws_ecs_service_role_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/public/aws_ecs_service_role"
  overwrite = true
  type = "String"
  value = "${module.staging_ecs.ecs_service_role_arn}"
}

resource "aws_ssm_parameter" "aws_kms_key_id_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/public/aws_kms_key_id"
  overwrite = true
  type = "String"
  value = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "aws_task_role_arn_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/public/aws_task_role_arn"
  overwrite = true
  type = "String"
  value = "${aws_iam_role.portl_staging.arn}"
}

resource "aws_ssm_parameter" "mongodb_hosts_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/public/mongodb_hosts"
  overwrite = true
  type = "StringList"
  value = "${aws_route53_record.mongo1.name},${aws_route53_record.mongo2.name},${aws_route53_record.mongo3.name}"
}

/*
  API Parameters
*/

resource "aws_ssm_parameter" "api_aws_target_group_arn_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/api/public/aws_target_group_arn"
  overwrite = true
  type = "String"
  value = "${aws_alb_target_group.staging.arn}"
}

resource "aws_ssm_parameter" "aws_deployment_minimum_healthy_percent" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/api/public/aws_deployment_minimum_healthy_percent"
  overwrite = true
  type = "String"
  value = "50"
}

resource "aws_ssm_parameter" "api_aws_ecs_cluster_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/api/public/aws_ecs_cluster"
  overwrite = true
  type = "String"
  value = "${module.staging_ecs.ecs_cluster_name}"
}

resource "aws_ssm_parameter" "api_aws_service_name" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/api/public/aws_service_name"
  overwrite = true
  type = "String"
  value = "portl-api_${var.app_env}"
}

resource "aws_ssm_parameter" "api_docker_memory_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/api/public/docker_memory"
  overwrite = true
  type = "String"
  value = "3072"
}

resource "aws_ssm_parameter" "api_docker_family" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/api/public/docker_family"
  overwrite = true
  type = "String"
  value = "portl-api_staging"
}

/*
  Admin API Parameters
*/
resource "aws_ssm_parameter" "admin_api_aws_aws_cloudfront_distribution_id" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/aws_cloudfront_distribution_id"
  overwrite = true
  type = "String"
  value = "${aws_cloudfront_distribution.admin_ui.id}"
}

resource "aws_ssm_parameter" "admin_api_aws_target_group_arn_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/aws_target_group_arn"
  overwrite = true
  type = "String"
  value = "${aws_alb_target_group.admin-api-staging.arn}"
}

resource "aws_ssm_parameter" "admin_api_aws_ecs_cluster_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/aws_ecs_cluster"
  overwrite = true
  type = "String"
  value = "${aws_ecs_cluster.admin_api.name}"
}

resource "aws_ssm_parameter" "admin_api_aws_service_name" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/aws_service_name"
  overwrite = true
  type = "String"
  value = "admin-api_${var.app_env}"
}

resource "aws_ssm_parameter" "admin_api_aws_cloudfront_distribution_id_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/aws_cloudfront_distribution_id"
  overwrite = true
  type = "String"
  value = "${aws_cloudfront_distribution.admin_ui.id}"
}

resource "aws_ssm_parameter" "admin_api_aws_s3_bucket_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/aws_s3_bucket"
  overwrite = true
  type = "String"
  value = "${aws_s3_bucket.admin_ui.bucket}"
}

resource "aws_ssm_parameter" "admin_api_docker_image_name_public" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/docker_image_name"
  overwrite = true
  type = "String"
  value = "admin-api"
}
resource "aws_ssm_parameter" "admin_api_docker_family" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/docker_family"
  overwrite = true
  type = "String"
  value = "portl-admin-api_staging"
}

resource "aws_ssm_parameter" "admin_api_media_s3_bucket" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/s3_media_bucket"
  overwrite = true
  type = "String"
  value = "${aws_s3_bucket.admin_ui_media.id}"
}

resource "aws_ssm_parameter" "admin_api_opencage_rate_limit_per_day" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/opencage_rate_limit_per_day"
  overwrite = true
  type = "String"
  value = "${var.opencage_rate_limit_per_day}"
}

resource "aws_ssm_parameter" "admin_api_opencage_rate_limit_per_second" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/opencage_rate_limit_per_second"
  overwrite = true
  type = "String"
  value = "${var.opencage_rate_limit_per_second}"
}

resource "aws_ssm_parameter" "admin_ui_s3_region" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/s3_region"
  overwrite = true
  type = "String"
  value = "${var.aws_region}"
}

resource "aws_ssm_parameter" "admin_ui_cloudfront_base_url" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/public/cloudfront_base_url"
  overwrite = true
  type = "String"
  value = "https://${aws_cloudfront_distribution.admin_ui_media.aliases[0]}"
}
