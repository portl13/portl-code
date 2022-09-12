variable "app_name" {
    default = "portl"
}

variable "aws_key_name" {
    default = "portl-management"
}

variable "aws_region" {
    default = "us-west-2"
}

variable "aws_base_ami" {
    default = "ami-29562251"
}

variable "aws_base_m5" {
    default = "ami-0e3b7b72148c3b43e"
}

variable "aws_base_ami_6-11-2018" {
    default = "ami-bbcf8fc3"
}

variable "bandsintown_token" {}

variable "base_domain_name" {
    default = "portl.com"
}

variable "eventbrite_token" {}

variable "influxdb_username" {}

variable "influxdb_password" {}

variable "ipsec_vpn_endpoint" {
    default = "204.98.74.254"
}

variable "meetup_token" {}

variable "production_subnet_cidr" {
    default = "172.22.162.0/24"
}

variable "project_name" {
  default = "portl"
}

variable "route53_zone_name" {
    default = "portl.com"
}

variable "review_subnet_cidr" {
    default = "172.22.160.0/24"
}

variable "opencage_token" {}

variable "songkick_token" {}

variable "ticketmaster_token" {}

variable "tools_subnet_cidr" {
    default = "172.22.190.0/24"
}

variable "slack_api_token" {}

variable "vpc_cidr" {
    default = "172.22.160.0/19"
}

variable "pfsense_ami" {
    default = "ami-07b6c47f"
}

variable "pfsense_subnet_cidr" {
    default = "172.22.189.224/27"
}

