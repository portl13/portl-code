resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name                = "${var.app_name}l_${var.app_env}_cpu_utilization_high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "75"
  alarm_description         = "This metric monitors ECS CPUUtilization"
  insufficient_data_actions = []
  alarm_actions = [
    "${aws_sns_topic.pagerduty_production.arn}",
    "${aws_autoscaling_policy.add_capacity.arn}"
  ]
  ok_actions = [
    "${aws_sns_topic.pagerduty_production.arn}",
    "${aws_autoscaling_policy.reduce_capacity.arn}",
  ]

  dimensions {
    ClusterName = "${module.production_ecs.ecs_cluster_name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name                = "${var.app_name}l_${var.app_env}_alb_5xx_errors"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "HTTPCode_ELB_5XX_Count"
  namespace                 = "AWS/ApplicationELB"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = ".75"
  alarm_description         = "Alerts pagerduty when 500 errors are above 1% of total request traffic"
  insufficient_data_actions = []
  alarm_actions = [
    "${aws_sns_topic.pagerduty_production.arn}",
    "${aws_autoscaling_policy.add_capacity.arn}"
  ]
  ok_actions = [
    "${aws_sns_topic.pagerduty_production.arn}",
    "${aws_autoscaling_policy.reduce_capacity.arn}",
  ]

}
