variable "app_env" {
  default = "staging"
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

variable "aws_ecs_autoscale_ami" {
  default = "ami-f189d189"
}

variable "base_domain_name" {
  default = "staging.portl.com"
}

variable "certificate_domain_name" {
  default = "api.staging.portl.com"
}

variable "subdomain" {
  default = "staging.portl.com"
}

variable "subnet_cidr" {
  default = "172.22.161.0/24"
}

variable "staging_mongodb_backup_username" {}
variable "staging_mongodb_backup_password" {}
variable "staging_mongodb_root_username" {}
variable "staging_mongodb_root_password" {}
variable "staging_mongodb_cluster_key" {}
variable "staging_mongodb_replica_set" {}

variable "staging_api_application_token" {}
variable "staging_api_mongodb_username" {}
variable "staging_api_mongodb_password" {}
variable "staging_api_mongodb_uri" {}


/*
  Variables for admin-api & admin-ui
*/

variable "admin-api" {
  default = "admin-api"
}

variable "graylog_server" {
  default = "logs.portl.com"
}

variable "opencage_rate_limit_per_second" {
  default = "3"
}

variable "opencage_rate_limit_per_day" {
  default = "20000"
}

variable "staging_admin_api_mongodb_uri" {}
variable "staging_admin_api_mongodb_username" {}
variable "staging_admin_api_mongodb_password" {}
variable "staging_admin_api_application_token" {}
