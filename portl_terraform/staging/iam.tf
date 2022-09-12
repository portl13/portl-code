data "aws_iam_policy_document" "portl_task_staging" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  },
}

data "template_file" "portl_kms_policy" {
  template = "${file("${path.module}/templates/kms_policy.json")}"

  vars {
    all_kms_arn = "${data.aws_kms_key.all.arn}"
    env_kms_arn = "${aws_kms_key.staging.arn}"
  }
}

data "template_file" "portl_ssm_policy" {
  template = "${file("${path.module}/templates/ssm_policy_public.json")}"

  vars {
    legacy_tree_arn = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.app_name}/${var.app_env}/*",
    all_tree_arn = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.app_name}/${var.aws_region}/all/*",
    environment_tree_arn = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.app_name}/${var.aws_region}/${var.app_env}/*",
  }
}

data "template_file" "portl_s3_upload_policy" {
  template = "${file("${path.module}/templates/s3_upload.json")}"

  vars {
    bucket_arn = "${aws_s3_bucket.admin_ui_media.arn}"
  }
}

resource "aws_iam_policy" "portl_staging_kms" {
  name        = "portl_staging_kms"
  path        = "/"
  description = "portl_staging_kms"

  policy = "${data.template_file.portl_kms_policy.rendered}"
}

resource "aws_iam_policy" "portl_staging_ssm" {
  name        = "portl_staging_ssm"
  path        = "/"
  description = "portl_staging_ssm"

  policy = "${data.template_file.portl_ssm_policy.rendered}"
}

resource "aws_iam_policy" "portl_staging_s3" {
  name = "${var.app_name}_${var.app_env}_s3"
  path = "/"
  description = "${var.app_name} ${var.app_env} policy to upload media to s3"

  policy = "${data.template_file.portl_s3_upload_policy.rendered}"
}

resource "aws_iam_user" "portl_staging" {
  name = "port_${var.app_env}"
  path = "/portl/us/staging/"
}

resource "aws_iam_role" "portl_staging" {
  name = "portl_staging"
  assume_role_policy = "${data.aws_iam_policy_document.portl_task_staging.json}"
}

resource "aws_iam_group" "portl_staging" {
  name = "portl_staging"
  path = "/portl/us/staging/"
}

resource "aws_iam_group_membership" "staging" {
  name = "${aws_iam_group.portl_staging.name}-membership"
  group = "${aws_iam_group.portl_staging.name}"
  users = [
    "${aws_iam_user.portl_staging.name}",
    "${data.aws_iam_user.jenkins.user_name}",
    "${data.aws_iam_user.ansible.user_name}"
  ]
}

/* Create exclusive management of staging_ssm policy to users/groups/roles */
resource "aws_iam_policy_attachment" "staging_ssm" {
  name = "portl_staging_ssm"
  policy_arn = "${aws_iam_policy.portl_staging_ssm.arn}"
  roles = ["${aws_iam_role.portl_staging.name}"]
  groups = ["${aws_iam_group.portl_staging.name}"]
}

/* Create exclusive management of staging_kms policy to users/groups/roles */
resource "aws_iam_policy_attachment" "staging_kms" {
  name = "portl_staging_kms"
  policy_arn = "${aws_iam_policy.portl_staging_kms.arn}"
  roles = ["${aws_iam_role.portl_staging.name}"]
  groups = ["${aws_iam_group.portl_staging.name}"]
}

resource "aws_iam_policy_attachment" "staging_s3" {
  name = "portl_staging_s3"
  policy_arn = "${aws_iam_policy.portl_staging_s3.arn}"
  roles = ["${aws_iam_role.portl_staging.name}"]
  groups = ["${aws_iam_group.portl_staging.name}"]
}

resource "aws_iam_role_policy_attachment" "portl_staging_ecs" {
  role       = "${aws_iam_role.portl_staging.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
