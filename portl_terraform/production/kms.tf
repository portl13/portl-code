//resource "aws_kms_key" "admin_api_key" {
//  tags {
//    Name = "portl_admin_api_prod"
//  }
//}
//
//resource "aws_kms_alias" "admin_api_key" {
//  name = "alias/admin_api_prod"
//  target_key_id = "${aws_kms_key.admin_api_key.id}"
//}
//

/* portl_production kms Key */
resource "aws_kms_key" "production" {
  tags {
    Name = "${var.app_name}_${var.app_env}"
  }
}

resource "aws_kms_alias" "portl_production" {
  name = "alias/${var.app_name}/${var.app_env}"
  target_key_id = "${aws_kms_key.production.id}"
}