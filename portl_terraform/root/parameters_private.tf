resource "aws_ssm_parameter" "bandsintown_token" {
  name = "/${var.app_name}/${var.aws_region}/all/private/bandsintown_token"
  overwrite = true
  type = "SecureString"
  value = "${var.bandsintown_token}"
  key_id = "${aws_kms_key.all.id}"
}

resource "aws_ssm_parameter" "eventbrite_token" {
  name = "/${var.app_name}/${var.aws_region}/all/private/eventbrite_token"
  overwrite = true
  type = "SecureString"
  value = "${var.eventbrite_token}"
  key_id = "${aws_kms_key.all.id}"
}

resource "aws_ssm_parameter" "meetup_token" {
  name = "/${var.app_name}/${var.aws_region}/all/private/meetup_token"
  overwrite = true
  type = "SecureString"
  value = "${var.meetup_token}"
  key_id = "${aws_kms_key.all.id}"
}

resource "aws_ssm_parameter" "opencage_token" {
  name = "/${var.app_name}/${var.aws_region}/all/private/opencage_token"
  overwrite = true
  type = "SecureString"
  value = "${var.opencage_token}"
  key_id = "${aws_kms_key.all.id}"
}

resource "aws_ssm_parameter" "songkick_token" {
  name = "/${var.app_name}/${var.aws_region}/all/private/songkick_token"
  overwrite = true
  type = "SecureString"
  value = "${var.songkick_token}"
  key_id = "${aws_kms_key.all.id}"
}

resource "aws_ssm_parameter" "ticketmaster_token" {
  name = "/${var.app_name}/${var.aws_region}/all/private/ticketmaster_token"
  overwrite = true
  type = "SecureString"
  value = "${var.ticketmaster_token}"
  key_id = "${aws_kms_key.all.id}"
}

resource "aws_ssm_parameter" "influxdb_username" {
  name = "/${var.app_name}/${var.aws_region}/all/private/influxdb_username"
  overwrite = true
  type = "SecureString"
  value = "${var.influxdb_username}"
  key_id = "${aws_kms_key.all.id}"
}

resource "aws_ssm_parameter" "influxdb_password" {
  name = "/${var.app_name}/${var.aws_region}/all/private/influxdb_password"
  overwrite = true
  type = "SecureString"
  value = "${var.influxdb_password}"
  key_id = "${aws_kms_key.all.id}"
}


resource "aws_ssm_parameter" "slack_api_token" {
  name = "/${var.app_name}/${var.aws_region}/all/private/slack_api_token"
  overwrite = true
  type = "SecureString"
  value = "${var.slack_api_token}"
  key_id = "${aws_kms_key.all.id}"
}
