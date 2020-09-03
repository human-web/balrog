locals {
  region = "us-east-1"
  docker_image = "470602773899.dkr.ecr.us-east-1.amazonaws.com/balrog/balrog"
  key_name = "sam"
  vpc_id = "vpc-2c11904a"
  private_subnets = [ "subnet-2a058116", "subnet-9587f6ce", "subnet-6659712f", "subnet-bfafd492" ]
  vpn_sec_group_id = "sg-03d0a12d9dcc230eb"
  dns_zone_id = "Z1T9VA34W75OR4"
  dns_name_admin = "balrogadmin.ghosterydev.com"
  dns_name_ui = "balrogui.ghosterydev.com"
  db_name = "balrog"
  db_host = "balrog.cfheundkobhl.us-east-1.rds.amazonaws.com"
  db_user = "balrogadmin"
  db_pass = ""
}

provider "aws" {
  region = local.region
}

# shared definitions
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["master-cliqz-ubuntu-18.04-docker-2019*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["141047255820"]
}
