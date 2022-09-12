resource "aws_sns_topic" "pagerduty_staging" {
  name = "pagerduty_staging"
}

resource "aws_sns_topic_subscription" "pagerduty" {
  endpoint = "https://events.pagerduty.com/integration/3f454d110d0944bdb87bff64dabcf83a/enqueue"
  endpoint_auto_confirms = true
  protocol = "https"
  topic_arn = "${aws_sns_topic.pagerduty_staging.arn}"
}