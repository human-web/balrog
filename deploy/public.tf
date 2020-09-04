
# Security group for public ec2 instance - internal access to port 9010
resource "aws_security_group" "balrog-public" {
  name = "balrog-public"
  ingress {
    from_port = 9010
    to_port = 9010
    protocol = "tcp"
    security_groups = [ aws_security_group.balrog-public-lb.id, local.vpn_sec_group_id ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  vpc_id = local.vpc_id
}

# Userdata script for public ec2 instance - starts balrog public
data "template_file" "balrog-public-userdata-script" {
  template = file("${path.module}/userdata-public.sh.tmpl")
  vars = {
    docker_image = local.docker_image
    db_host = local.db_host
    db_name = local.db_name
    db_user = local.db_user
    db_pass = local.db_pass
  }
}

resource "aws_launch_configuration" "balrogpublic-launch-config" {
  name_prefix = "balrog-public"
  image_id = data.aws_ami.ubuntu.id

  security_groups = [ aws_security_group.balrog-public.id, local.vpn_sec_group_id ]
  instance_type = "t3a.nano"
  user_data = data.template_file.balrog-public-userdata-script.rendered
  iam_instance_profile = aws_iam_instance_profile.balrog.arn
  associate_public_ip_address = false

  key_name = local.key_name
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "balrog-public-autoscaling-group" {
  name = "balrog-public"
  launch_configuration = aws_launch_configuration.balrogpublic-launch-config.id
  min_size = 1
  max_size = 4
  desired_capacity = 1
  vpc_zone_identifier = local.private_subnets

  target_group_arns = [ aws_lb_target_group.balrog-public.id ]

  tag {
    key = "Name"
    value = "balrog-public"
    propagate_at_launch = "true"
  }

  tag {
    key = "Owner"
    value = "sam@cliqz.com"
    propagate_at_launch = "true"
  }

  tag {
    key = "Project"
    value = "desktop-browser"
    propagate_at_launch = "true"
  }
}

# ELB
resource "aws_security_group" "balrog-public-lb" {
  name = "balrog-public-lb"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "balrog-public-lb" {
  name            = "balrog-public"
  subnets         = local.public_subnets
  security_groups = ["${aws_security_group.balrog-public-lb.id}"]
  internal        = false
  idle_timeout    = 60
}

resource "aws_lb_target_group" "balrog-public" {
  name     = "balrog-public"
  port     = "9010"
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/update/"
    port                = 9010
  }
}

resource "aws_lb_listener" "balrog-public-https" {
  load_balancer_arn = aws_lb.balrog-public-lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:470602773899:certificate/cff359d7-9c7c-40f8-ab93-458a0335b624"

  default_action {
    target_group_arn = aws_lb_target_group.balrog-public.arn
    type             = "forward"
  }
}

# DNS
resource "aws_route53_record" "update-ghosterybrowser-com" {
  zone_id = "Z2N6ATIWASS8WR"
  name    = "update.ghosterybrowser.com"
  type    = "A"

  alias {
    name = aws_lb.balrog-public-lb.dns_name
    zone_id = aws_lb.balrog-public-lb.zone_id
    evaluate_target_health = true
  }
}
