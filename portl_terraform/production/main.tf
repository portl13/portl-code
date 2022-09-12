terraform {
  required_version = "~> 0.11.7"

  backend "s3" {
    bucket = "portl-tfstate"
    dynamodb_table = "portl-tfstate-locks"
    encrypt = true
    key = "production/terraform.tfstate"
    profile = "portl"
    region = "us-west-2"
  }
}

provider "aws" {
  profile = "portl"
  region = "us-west-2"
  version = "~> 1.60.0"
}

provider "aws" {
  alias = "east"
  profile = "portl"
  region = "us-east-1"
  version = "~> 1.60.0"
}

/*
  Load Root State
*/
data "terraform_remote_state" "root" {
  backend = "s3"
  config {
    bucket = "portl-tfstate"
    key = "root/terraform.tfstate"
    region = "us-west-2"
    profile = "portl"
    encrypt = true
  }
}
