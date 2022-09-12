terraform {
  required_version = "~> 0.11.7"

  backend "s3" {
    bucket = "portl-tfstate"
    dynamodb_table = "portl-tfstate-locks"
    encrypt = true
    key = "root/terraform.tfstate"
    region = "us-west-2"
    profile = "portl"
  }
}

provider "aws" {
  profile = "portl"
  region = "${var.aws_region}"
  version = "~> 1.60.0"
}

provider "aws" {
  alias = "east"
  profile = "portl"
  region = "us-east-1"
  version = "~> 1.60.0"
}
