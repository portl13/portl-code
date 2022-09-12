resource "aws_ssm_parameter" "mongodb_cluster_key_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/private/mongodb_cluster_key"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_mongodb_cluster_key}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "mongodb_replica_set_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/private/mongodb_replica_set"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_mongodb_replica_set}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "mongodb_root_username_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/private/mongodb_root_username"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_mongodb_root_username}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "mongodb_root_password_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/private/mongodb_root_password"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_mongodb_root_password}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "replica_set_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/private/replica_set"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_mongodb_replica_set}"
  key_id = "${aws_kms_key.staging.id}"
}

/*
  API Parameters
*/
resource "aws_ssm_parameter" "api_application_token_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/api/private/application_token"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_api_application_token}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "api_mongodb_username_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/api/private/mongodb_username"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_api_mongodb_username}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "api_mongodb_password_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/api/private/mongodb_password"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_api_mongodb_password}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "api_mongodb_uri_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/api/private/mongodb_uri"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_api_mongodb_uri}"
  key_id = "${aws_kms_key.staging.id}"
}

/*
  ADMIN API Parameters
*/
resource "aws_ssm_parameter" "admin_api_application_token_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/private/application_token"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_admin_api_application_token}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "admin_api_mongodb_username_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/private/mongodb_username"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_admin_api_mongodb_username}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "admin_api_mongodb_password_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/private/mongodb_password"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_admin_api_mongodb_password}"
  key_id = "${aws_kms_key.staging.id}"
}

resource "aws_ssm_parameter" "admin_api_mongodb_uri_private" {
  name = "/${var.app_name}/${var.aws_region}/${var.app_env}/admin-api/private/mongodb_uri"
  overwrite = true
  type = "SecureString"
  value = "${var.staging_admin_api_mongodb_uri}"
  key_id = "${aws_kms_key.staging.id}"
}