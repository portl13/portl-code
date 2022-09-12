resource "aws_s3_bucket" "live_stream" {
  bucket = "portl-live-streams"
  acl = "private"
  region = "${var.aws_region}"

  versioning = {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "live_stream" {
  bucket   = "${aws_s3_bucket.live_stream.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

/* Build MEDIA S3 Bucket read policy template */
data "template_file" "s3_write" {
  template = "${file("${path.module}/templates/iam_s3_write_policy.json")}"
  vars {
    bucket_arn = "${aws_s3_bucket.live_stream.arn}"
  }
}

/* Create MEDIA S3 read policy from template */
resource "aws_iam_policy" "s3_write" {
  name        = "portl_livestream_s3_write"
  path        = "/"
  description = "portl_livestream_s3_write"

  policy = "${data.template_file.s3_write.rendered}"
}


/* Create App User */
resource "aws_iam_user" "livestream" {
  name = "livestream"
  path = "/"
}

/* Create App Group */
resource "aws_iam_group" "livestream" {
  name = "livestream"
  path = "/"
}

resource "aws_iam_group_membership" "livestream" {
  group = "${aws_iam_group.livestream.name}"
  name = "livestream"
  users = ["${aws_iam_user.livestream.name}"]
}

/* Attach kms policy to users/roles */
resource "aws_iam_policy_attachment" "s3" {
  name       = "livestream_s3_write"
  policy_arn = "${aws_iam_policy.s3_write.arn}"

  groups = ["${aws_iam_group.livestream.name}"]
}