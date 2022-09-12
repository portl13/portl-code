/*
  Data Sources
*/
data "aws_iam_user" "iposs" {
  user_name = "iposs@concentricsky.com"
}
data "aws_iam_user" "anugent" {
  user_name = "anugent"
}
# This allows retrieving the AWS account ID
data "aws_caller_identity" "current" {}



/*
  Create Ansible User
*/
resource "aws_iam_user" "ansible" {
  name = "ansible"
}

resource "aws_iam_user_policy_attachment" "ansible_ec2_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  user = "${aws_iam_user.ansible.name}"
}

resource "aws_iam_user_policy_attachment" "ansible_ecs_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  user = "${aws_iam_user.ansible.name}"
}

resource "aws_iam_user_policy_attachment" "ansible_s3_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  user = "${aws_iam_user.ansible.name}"
}

resource "aws_iam_user_policy_attachment" "ansible_route53_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  user = "${aws_iam_user.ansible.name}"
}

resource "aws_iam_user_policy_attachment" "ansible_cloudfront_access" {
  policy_arn = "arn:aws:iam::aws:policy/CloudFrontFullAccess"
  user = "${aws_iam_user.ansible.name}"
}

resource "aws_iam_policy" "ansible_pass_role" {
  name        = "ansible_pass_role"
  path        = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": [
            "iam:GetRole",
            "iam:PassRole"
        ],
        "Resource": [
          "arn:aws:iam::031057183607:role/portl_staging_role",
          "arn:aws:iam::031057183607:role/portl_production_role"
        ]
    }
}
EOF
}

resource "aws_iam_user_policy_attachment" "ansible_pass_role" {
  policy_arn = "${aws_iam_policy.ansible_pass_role.arn}"
  user = "${aws_iam_user.ansible.name}"
}

/*
  Create Jenkins User
*/
resource "aws_iam_user" "jenkins" {
  name = "jenkins"
}

resource "aws_iam_policy" "ecr_read_policy" {
  name        = "ecr_read_policy"
  path        = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "ecr:GetAuthorizationToken",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetRepositoryPolicy",
                "ecr:InitiateLayerUpload"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}



resource "aws_iam_user_policy_attachment" "jenkins_ecr" {
  policy_arn = "${aws_iam_policy.ecr_read_policy.arn}"
  user = "${aws_iam_user.jenkins.name}"
}

resource "aws_iam_policy" "manage_own_accesskey" {
  name        = "manage_own_accesskey"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:*AccessKey*",
        "iam:*SSHPublicKey*"
      ],
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
    }
  ]
}
EOF

}

/*
  Create Grafana user & IAM policy
  Create s3 bucket policy
*/

resource "aws_iam_user" "grafana" {
  name = "grafana"
}

resource "aws_iam_policy" "grafana_cloudwatch" {
  name        = "grafana_cloudwatch"
  path        = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowReadingMetricsFromCloudWatch",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowReadingTagsFromEC2",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "grafana_s3" {
  name        = "grafana_s3"
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["${aws_s3_bucket.grafana.arn}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["${aws_s3_bucket.grafana.arn}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "grafana_cloudwatch" {
  policy_arn = "${aws_iam_policy.grafana_cloudwatch.arn}"
  user = "${aws_iam_user.grafana.name}"
}
resource "aws_iam_user_policy_attachment" "grafana_s3" {
  policy_arn = "${aws_iam_policy.grafana_s3.arn}"
  user = "${aws_iam_user.grafana.name}"
}
/*
  Attach policy to austin's user
*/
resource "aws_iam_user_policy_attachment" "iposs_ecr_read" {
  policy_arn = "${aws_iam_policy.ecr_read_policy.arn}"
  user       = "${data.aws_iam_user.iposs.user_name}"
}

resource "aws_iam_user_policy_attachment" "iposs_manage_own_accesskey" {
  policy_arn = "${aws_iam_policy.manage_own_accesskey.arn}"
  user       = "${data.aws_iam_user.iposs.user_name}"
}
resource "aws_iam_user_policy_attachment" "iposs_readonly_access" {
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  user       = "${data.aws_iam_user.iposs.user_name}"
}

/*
  Create and attach policies to Asia's user
*/

resource "aws_iam_user_policy_attachment" "anugent_ecr_read" {
  policy_arn = "${aws_iam_policy.ecr_read_policy.arn}"
  user       = "${data.aws_iam_user.anugent.user_name}"
}

resource "aws_iam_user_policy_attachment" "anugent_manage_own_accesskey" {
  policy_arn = "${aws_iam_policy.manage_own_accesskey.arn}"
  user       = "${data.aws_iam_user.anugent.user_name}"
}
resource "aws_iam_user_policy_attachment" "anugent_readonly_access" {
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  user       = "${data.aws_iam_user.anugent.user_name}"
}
