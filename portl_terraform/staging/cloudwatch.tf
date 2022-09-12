#resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
#  alarm_name                = "${var.app_name}_${var.app_env}_cpu_utilization_high"
#  comparison_operator       = "GreaterThanThreshold"
#  evaluation_periods        = "2"
#  metric_name               = "CPUUtilization"
#  namespace                 = "AWS/ECS"
#  period                    = "60"
#  statistic                 = "Average"
#  threshold                 = "75"
#  alarm_description         = "This metric monitors ECS CPUUtilization"
#  insufficient_data_actions = []
#  alarm_actions = [
#    "${aws_sns_topic.pagerduty_staging.arn}",
#    "${aws_autoscaling_policy.add_capacity.arn}"
#  ]
#  ok_actions = [
#    "${aws_sns_topic.pagerduty_staging.arn}",
#    "${aws_autoscaling_policy.reduce_capacity.arn}",
#  ]
#
#  dimensions {
#    ClusterName = "${module.staging_ecs.ecs_cluster_name}"
#  }
#}
