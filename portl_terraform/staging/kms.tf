/* portl_staging kms Key */
resource "aws_kms_key" "staging" {
  tags {
    Name = "${var.app_name}_${var.app_env}"
  }
}

resource "aws_kms_alias" "portl_staging" {
  name = "alias/${var.app_name}/${var.app_env}"
  target_key_id = "${aws_kms_key.staging.id}"
}