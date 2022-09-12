resource "aws_ssm_parameter" "mongodb_cluster_key" {
  name = "/${var.app_name}/${var.app_env}/mongodb_cluster_key"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_mongodb_cluster_key}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "mongodb_replica_set" {
  name = "/${var.app_name}/${var.app_env}/mongodb_replica_set"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_mongodb_replica_set}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "api_mongodb_root_username" {
  name = "/${var.app_name}/${var.app_env}/mongodb_root_username"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_mongodb_root_username}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "api_mongodb_root_password" {
  name = "/${var.app_name}/${var.app_env}/mongodb_root_password"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_mongodb_root_password}"
  key_id = "${aws_kms_key.staging.id}"
}

/*
  API Parameters
*/
resource "aws_ssm_parameter" "api_application_token" {
  name = "/${var.app_name}/${var.app_env}/api/application_token"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_api_application_token}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "api_mongodb_username" {
  name = "/${var.app_name}/${var.app_env}/api/mongodb_username"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_api_mongodb_username}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "api_mongodb_password" {
  name = "/${var.app_name}/${var.app_env}/api/mongodb_password"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_api_mongodb_password}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "api_mongodb_uri" {
  name = "/${var.app_name}/${var.app_env}/api/mongodb_uri"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_api_mongodb_uri}"
  key_id = "${aws_kms_key.staging.id}"
}

/*
  ADMIN API Parameters
*/
resource "aws_ssm_parameter" "admin_api_application_token" {
  name = "/${var.app_name}/${var.app_env}/admin-api/application_token"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_admin_api_application_token}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "admin_api_mongodb_username" {
  name = "/${var.app_name}/${var.app_env}/admin-api/mongodb_username"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_admin_api_mongodb_username}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "admin_api_mongodb_password" {
  name = "/${var.app_name}/${var.app_env}/admin-api/mongodb_password"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_admin_api_mongodb_password}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "admin_api_mongodb_uri" {
  name = "/${var.app_name}/${var.app_env}/admin-api/mongodb_uri"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_admin_api_mongodb_uri}"
  key_id = "${aws_kms_key.staging.id}"
}