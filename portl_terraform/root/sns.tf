/*
  Create PagerDuty SNS Topic
*/
resource "aws_sns_topic" "pagerduty" {
  name = "pagerduty-alerts"
  display_name = "PagerDuty Alerts"
}

resource "aws_sns_topic_subscription" "pagerduty" {
  endpoint = "https://events.pagerduty.com/integration/3f454d110d0944bdb87bff64dabcf83a/enqueue"
  protocol = "https"
  endpoint_auto_confirms = true
  topic_arn = "${aws_sns_topic.pagerduty.arn}"
}