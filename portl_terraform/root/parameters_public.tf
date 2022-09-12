resource "aws_ssm_parameter" "aws_deployment_minimum_healthy_percent" {
  name = "/${var.app_name}/${var.aws_region}/all/public/aws_deployment_minimum_healthy_percent"
  overwrite = true
  type = "String"
  value = "0"
}

resource "aws_ssm_parameter" "aws_deployment_maximum_healthy_percent" {
  name = "/${var.app_name}/${var.aws_region}/all/public/aws_deployment_maximum_healthy_percent"
  overwrite = true
  type = "String"
  value = "100"
}

resource "aws_ssm_parameter" "container_port" {
  name = "/${var.app_name}/${var.aws_region}/all/public/container_port"
  overwrite = true
  type = "String"
  value = "9000"
}

resource "aws_ssm_parameter" "docker_cpu" {
  name = "/${var.app_name}/${var.aws_region}/all/public/docker_cpu"
  overwrite = true
  type = "String"
  value = "2048"
}

resource "aws_ssm_parameter" "docker_memory" {
  name = "/${var.app_name}/${var.aws_region}/all/public/docker_memory"
  overwrite = true
  type = "String"
  value = "3072"
}

resource "aws_ssm_parameter" "docker_desired_count" {
  name = "/${var.app_name}/${var.aws_region}/all/public/docker_desired_count"
  overwrite = true
  type = "String"
  value = "1"
}

resource "aws_ssm_parameter" "docker_entrypoint" {
  name = "/${var.app_name}/${var.aws_region}/all/public/docker_entrypoint"
  overwrite = true
  type = "String"
  value = "[\"/root/docker_entrypoint.sh\"]"
}

resource "aws_ssm_parameter" "docker_image_name" {
  name = "/${var.app_name}/${var.aws_region}/all/public/docker_image_name"
  overwrite = true
  type = "String"
  value = "portl-api"
}

resource "aws_ssm_parameter" "docker_registry_url" {
  name = "/${var.app_name}/${var.aws_region}/all/public/docker_registry_url"
  overwrite = true
  type = "String"
  value = "031057183607.dkr.ecr.us-west-2.amazonaws.com"
}

resource "aws_ssm_parameter" "log_server" {
  name = "/${var.app_name}/${var.aws_region}/all/public/log_server"
  overwrite = true
  type = "String"
  value = "${aws_route53_record.logs.name}"
}

resource "aws_ssm_parameter" "log_server_ip" {
  name = "/${var.app_name}/${var.aws_region}/all/public/log_server_ip"
  overwrite = true
  type = "String"
  value = "${aws_instance.logs.private_ip}"
}

resource "aws_ssm_parameter" "influxdb_host" {
  name = "/${var.app_name}/${var.aws_region}/all/public/influxdb_host"
  overwrite = true
  type = "String"
  value = "${aws_route53_record.influx.name}"
}
