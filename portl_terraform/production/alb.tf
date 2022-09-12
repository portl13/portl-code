/*
  Create Prod ALB
*/
resource "aws_lb" "production" {
  name = "${var.project_name}-${var.app_env}"
  internal = false
  security_groups = ["${data.aws_security_group.web_external.id}"]
  subnets = [
    "${data.aws_subnet.nat_a.id}",
    "${data.aws_subnet.nat_b.id}",
    "${data.aws_subnet.nat_c.id}"
  ]

  tags = {
    Environment = "${var.app_env}"
  }
}

resource "aws_alb_target_group" "production" {
  name = "${var.project_name}-${var.app_env}"
  port = 9000
  protocol = "HTTP"
  vpc_id = "${data.terraform_remote_state.root.vpc_id}"

  deregistration_delay = 30

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 15
    timeout = 5
    matcher = "200"
    path = "/status/dbHealth"
  }
}

resource "aws_lb_listener" "http_80" {
  load_balancer_arn = "${aws_lb.production.arn}"
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_443" {
  load_balancer_arn = "${aws_lb.production.arn}"
  port = 443
  protocol = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${aws_acm_certificate_validation.production_validation.certificate_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.production.arn}"
    type = "forward"
  }
}


/*
  Admin-api Prod ALB
*/

resource "aws_lb" "admin-api" {
  name = "${var.project_name}-admin-api-${var.app_env}"
  internal = true
  security_groups = [
    "${data.aws_security_group.web_protected.id}",
    "${data.aws_security_group.vpn_subnet_access.id}",
    "${data.aws_security_group.csky_internal.id}"
  ]
  subnets = [
    "${data.aws_subnet.nat_a.id}",
    "${data.aws_subnet.nat_b.id}",
    "${data.aws_subnet.nat_c.id}"
  ]

  tags = {
    Environment = "${var.app_env}"
    App = "Admin-api"
  }
}

resource "aws_alb_target_group" "admin-api" {
  name = "${var.project_name}-admin-api-${var.app_env}"
  port = 9000
  protocol = "HTTP"
  vpc_id = "${data.terraform_remote_state.root.vpc_id}"

  deregistration_delay = 30

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 15
    timeout = 5
    matcher = "200"
    path = "/status/dbHealth"
  }
}

resource "aws_lb_listener" "admin-api-http_80" {
  load_balancer_arn = "${aws_lb.admin-api.arn}"
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "admin-api-https_443" {
  load_balancer_arn = "${aws_lb.admin-api.arn}"
  port = 443
  protocol = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${aws_acm_certificate_validation.admin-api_validation.certificate_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.admin-api.arn}"
    type = "forward"
  }
}
