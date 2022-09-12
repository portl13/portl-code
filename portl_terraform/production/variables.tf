variable "app_env" {
  default = "production"
}

variable "app_name" {
  default = "portl"
}

variable "aws_region" {
  default = "us-west-2"
}

variable "aws_key_name" {
  default = "portl-management"
}

variable "aws_base_ami_6-11-2018" {
    default = "ami-bbcf8fc3"
}

variable "aws_base_ami" {
  default = "ami-29562251"
}

variable "aws_base_ecs_ami" {
  default = "ami-40ddb938"
}

variable "aws_base_m5" {
  default = "ami-0e3b7b72148c3b43e"
}

variable "base_domain_name" {
  default = "portl.com"
}

variable "certificate_domain_name" {
  default = "api.portl.com"
}

variable "eventbrite_token" {}

variable "influxdb_username" {}

variable "influxdb_password" {}

variable "lunarpages_portl_com_ip" {
  default = "216.97.237.98"
}

variable "subdomain" {
  default = "portl.com"
}

variable "project_name" {
  default = "portl"
}

variable "graylog_server" {
  default = "logs.portl.com"
}

variable "production_mongodb_backup_username" {}
variable "production_mongodb_backup_password" {}
variable "production_mongodb_root_username" {}
variable "production_mongodb_root_password" {}
variable "production_mongodb_cluster_key" {}
variable "production_mongodb_replica_set" {}

variable "production_api_application_token" {}
variable "production_api_mongodb_username" {}
variable "production_api_mongodb_password" {}
variable "production_api_mongodb_uri" {}


/*
  Variables for admin-api & admin-ui
*/

variable "admin-api" {
  default = "admin-api"
}

variable "opencage_rate_limit_per_second" {
  default = "12"
}

variable "opencage_rate_limit_per_day" {
  default = "80000"
}

variable "production_admin_api_mongodb_username" {}
variable "production_admin_api_mongodb_password" {}
variable "production_admin_api_mongodb_uri" {}
variable "production_admin_api_application_token" {}
