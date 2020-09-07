# Balrog Deployment

The balrog deployment consists of the following components:

 * Admin endpoint - API for modifying releases and rules.
 * Public endpoint - Public API.
 * WebUI - Static react app for interacting with the admin API.
 * Balrog agent - Process for executing scheduled changes by calling the admin API.
 * Auth endpoint - The Auth0 service.

This is deployed by terraform which generates the following:
 * An EC2 instance and ELB for the admin endpoint, available at http://balrogadmin.ghosterydev.com/.
 * The Balrog agent is also started on the admin EC2 instance.
 * An EC2 autoscaling group and ELB for the public endpoint, available at https://update.ghosterybrowser.com/.
 * An S3 bucket set up as an S3 website, hosting the WebUI, available at http://balrog-ui.ghosterydev.com.s3-website-us-east-1.amazonaws.com/.

Not defined in terraform is:
 1. The Mysql database, manually deployed as an RDS instance which can be accessed from with the VPC.
 2. Auth0 configuration. We have an account with the endpoint at `https://ghostery-balrog.eu.auth0.com`
 3. Docker ECR registries: `balrog/balrog` and `balrog/agent`.
 4. Build and push of docker images used by the admin and public EC2 instances, which is done in CI in `Jenkinsfile`.

## CI Build

The CI build, defined in `Jenkinsfile`, does the following:
 * Builds static assets for the WebUI, configured to connect to the admin API, and use our Auth0 account. This is uploaded to the S3 bucket from which the UI is served.
 * Builds the main balrog server image. This is built from the `Dockerfile` in this repo root, and pushed to ECR. Admin and public instances pull the latest version of this image when they launch.
 * Builds the balrog agent image. This is built from `agent/Dockerfile`, with M2M credentials for Auth0 built into the image. This means that these credentials don't need to be put in the server configuration. The admin server will pull the latest version of this image on startup.

## How to deploy

 1. Run Jenkins CI to ensure the latest version docker images are uploaded.
 2. Run `terraform apply` to set up all AWS infrastructure.