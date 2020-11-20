locals {
  region = "us-east-1"
  docker_image = "470602773899.dkr.ecr.us-east-1.amazonaws.com/balrog/balrog"
  docker_image_agent = "470602773899.dkr.ecr.us-east-1.amazonaws.com/balrog/agent"
  key_name = "sam"
  vpc_id = "vpc-2c11904a"
  private_subnets = [ "subnet-2a058116", "subnet-9587f6ce", "subnet-6659712f", "subnet-bfafd492" ]
  public_subnets = [ "subnet-4004807c", "subnet-51587018", "subnet-8a84f5d1", "subnet-bda8d390" ]
  vpn_sec_group_id = "sg-03d0a12d9dcc230eb"
  dns_zone_id = "Z1T9VA34W75OR4"
  dns_name_admin = "balrogadmin.ghosterydev.com"
  dns_name_ui = "balrogui.ghosterydev.com"
  db_name = "balrog"
  db_host = "balrog.cfheundkobhl.us-east-1.rds.amazonaws.com"
  db_user = "balrogadmin"
  db_pass = ""
}

variable "balrog_db_pass" {
  type        = string
  description = "Password the balrog DB admin user"
}


provider "aws" {
  region = local.region
}

# shared definitions
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ghostery-ubuntu-20-04-based-ghostery-search-serp-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["470602773899"]
}

resource "aws_iam_instance_profile" "balrog" {
  name = "balrog"
  role = aws_iam_role.balrog.name
}

resource "aws_iam_role" "balrog" {
  name = "balrog"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "telemetry-scheduler-ecr_access" {
  role       = aws_iam_role.balrog.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}