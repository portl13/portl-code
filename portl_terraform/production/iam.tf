data "aws_iam_policy_document" "portl_task_production" {
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
    env_kms_arn = "${aws_kms_key.production.arn}"
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

//data "template_file" "admin-api_kms_policy" {
//  template = "${file("${path.module}/../templates/kms_policy.json")}"
//
//  vars {
//      kms_arn = "arn:aws:kms:us-west-2:031057183607:key/139ce8f9-a0bf-4051-9a0c-8bae97260a3e"
//  }
//}
//
//data "template_file" "admin-api_ssm_policy" {
//  template = "${file("${path.module}/../templates/ssm_policy.json")}"
//
//  vars {
//    parameter_arn = "arn:aws:ssm:us-west-2:031057183607:parameter/admin-api/production/*"
//  }
//}

resource "aws_iam_policy" "portl_production_kms" {
  name        = "portl_production_kms"
  path        = "/"
  description = "portl_production_kms"

  policy = "${data.template_file.portl_kms_policy.rendered}"
}

resource "aws_iam_policy" "portl_production_ssm" {
  name        = "portl_production_ssm"
  path        = "/"
  description = "portl_production_ssm"

  policy = "${data.template_file.portl_ssm_policy.rendered}"
}

resource "aws_iam_policy" "portl_production_s3" {
  name = "${var.app_name}_${var.app_env}_s3"
  path = "/"
  description = "${var.app_name} ${var.app_env} policy to upload media to s3"

  policy = "${data.template_file.portl_s3_upload_policy.rendered}"
}


//resource "aws_iam_policy" "admin-api_production_kms" {
//  name        = "admin-api_production_kms"
//  path        = "/"
//  description = "admin-api_production_kms"
//
//  policy = "${data.template_file.admin-api_kms_policy.rendered}"
//}
//
//resource "aws_iam_policy" "admin-api_production_ssm" {
//  name        = "admin-api_production_ssm"
//  path        = "/"
//  description = "admin-api_production_ssm"
//
//  policy = "${data.template_file.admin-api_ssm_policy.rendered}"
//}

resource "aws_iam_user" "portl_production" {
  name = "port_${var.app_env}"
  path = "/portl/us/production/"
}

resource "aws_iam_role" "portl_production" {
  name = "portl_production"
  assume_role_policy = "${data.aws_iam_policy_document.portl_task_production.json}"
}

resource "aws_iam_group" "portl_production" {
  name = "portl_production"
  path = "/portl/us/production/"
}

resource "aws_iam_group_membership" "production" {
  name = "${aws_iam_group.portl_production.name}-membership"
  group = "${aws_iam_group.portl_production.name}"
  users = [
    "${aws_iam_user.portl_production.name}",
    "${data.aws_iam_user.jenkins.user_name}",
    "${data.aws_iam_user.ansible.user_name}"
  ]
}

/* Create exclusive management of production_ssm policy to users/groups/roles */
resource "aws_iam_policy_attachment" "production_ssm" {
  name = "portl_production_ssm"
  policy_arn = "${aws_iam_policy.portl_production_ssm.arn}"
  roles = ["${aws_iam_role.portl_production.name}"]
  groups = ["${aws_iam_group.portl_production.name}"]
}

/* Create exclusive management of production_kms policy to users/groups/roles */
resource "aws_iam_policy_attachment" "production_kms" {
  name = "portl_production_kms"
  policy_arn = "${aws_iam_policy.portl_production_kms.arn}"
  roles = ["${aws_iam_role.portl_production.name}"]
  groups = ["${aws_iam_group.portl_production.name}"]
}

resource "aws_iam_policy_attachment" "production_s3" {
  name = "portl_production_s3"
  policy_arn = "${aws_iam_policy.portl_production_s3.arn}"
  roles = ["${aws_iam_role.portl_production.name}"]
  groups = ["${aws_iam_group.portl_production.name}"]
}


resource "aws_iam_role_policy_attachment" "portl_production_ecs" {
  role       = "${aws_iam_role.portl_production.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

//resource "aws_iam_role_policy_attachment" "portl_production_kms" {
//  role       = "${aws_iam_role.portl_production.name}"
//  policy_arn = "${aws_iam_policy.portl_production_kms.arn}"
//}
//
//resource "aws_iam_role_policy_attachment" "portl_production_ssm" {
//  role       = "${aws_iam_role.portl_production.name}"
//  policy_arn = "${aws_iam_policy.portl_production_ssm.arn}"
//}

//resource "aws_iam_role_policy_attachment" "admin-api_production_kms" {
//  role       = "${aws_iam_role.portl_production.name}"
//  policy_arn = "${aws_iam_policy.admin-api_production_kms.arn}"
//}
//
//resource "aws_iam_role_policy_attachment" "admin-api_production_ssm" {
//  role       = "${aws_iam_role.portl_production.name}"
//  policy_arn = "${aws_iam_policy.admin-api_production_ssm.arn}"
//}

/*
  admin-ui deploy iam user
*/

//data "template_file" "admin-ui_policy_deploy" {
//  template = "${file("${path.module}/../templates/admin_ui_deploy_policy.json")}"
//
//  vars {
//    s3_bucket_arn = "${aws_s3_bucket.admin_ui.arn}"
//    cloudfront_distribution_arn = "${aws_cloudfront_distribution.admin_ui.arn}"
//  }
//}
//
//resource "aws_iam_user" "admin-ui_iam_user" {
//  name = "admin-ui_${var.environment_name}"
//}
//
//resource "aws_iam_policy" "admin-ui_deploy_policy" {
//  name = "admin-ui_deploy_${var.environment_name}"
//  policy = "${data.template_file.admin-ui_policy_deploy.rendered}"
//}
//
//resource "aws_iam_user_policy_attachment" "admin-ui_deploy_policy" {
//  policy_arn = "${aws_iam_policy.admin-ui_deploy_policy.arn}"
//  user = "${aws_iam_user.admin-ui_iam_user.id}"
//}
