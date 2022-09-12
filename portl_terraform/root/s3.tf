/*
  Create Grafana s3 bucket
*/

resource "aws_s3_bucket" "grafana" {
  bucket = "grafana.portl"
  acl = "private"
  region = "${var.aws_region}"
}