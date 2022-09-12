/*
  portl kms Key
*/
resource "aws_kms_key" "all" {
  tags {
    Name = "portl_all"
  }
}

resource "aws_kms_alias" "all" {
  name = "alias/portl/all"
  target_key_id = "${aws_kms_key.all.id}"
}