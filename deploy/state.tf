terraform {
  required_version = ">= 0.12.0"

  backend "s3" {
    bucket = "ghostery-deployments"
    key = "balrog/tf-state/tf.state"
    region = "us-east-1"
  }
}