
resource "aws_security_group" "balrog-admin" {
  name = "balrog-admin"
  ingress {
    from_port = 7070
    to_port = 7070
    protocol = "tcp"
    security_groups = [ aws_security_group.balrog-admin-lb.id, local.vpn_sec_group_id ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  vpc_id = local.vpc_id
}

data "template_file" "balrog-admin-userdata-script" {
  template = file("${path.module}/userdata-admin.sh.tmpl")
  vars = {
    docker_image = local.docker_image
    docker_image_agent = local.docker_image_agent
    db_host = local.db_host
    db_name = local.db_name
    db_user = local.db_user
    db_pass = local.db_pass
  }
}

resource "aws_launch_configuration" "balrogadmin-launch-config" {
  name_prefix = "balrod-admin"
  image_id = data.aws_ami.ubuntu.id

  security_groups = [ aws_security_group.balrog-admin.id, local.vpn_sec_group_id ]
  instance_type = "t3a.micro"
  user_data = data.template_file.balrog-admin-userdata-script.rendered
  iam_instance_profile = aws_iam_instance_profile.balrog.arn
  associate_public_ip_address = false
  spot_price = 0.008

  key_name = local.key_name
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "balrog-admin-autoscaling-group" {
  name = "balrog-admin"
  launch_configuration = aws_launch_configuration.balrogadmin-launch-config.id
  min_size = 1
  max_size = 1
  vpc_zone_identifier = local.private_subnets

  target_group_arns = [ aws_lb_target_group.balrog-admin.id ]

  tag {
    key = "Name"
    value = "balrog-admin"
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
resource "aws_security_group" "balrog-admin-lb" {
  name = "balrog-admin-lb"
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
    security_groups = [ local.vpn_sec_group_id ]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [ local.vpn_sec_group_id ]
  }
}

resource "aws_lb" "balrog-admin-lb" {
  name            = "balrog-admin"
  subnets         = local.private_subnets
  security_groups = ["${aws_security_group.balrog-admin-lb.id}"]
  internal        = true
  idle_timeout    = 60
}

resource "aws_lb_target_group" "balrog-admin" {
  name     = "balrog-admin"
  port     = "7070"
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/api/__heartbeat__"
    port                = 7070
  }
}

resource "aws_lb_listener" "balrog-admin-http" {
  load_balancer_arn = aws_lb.balrog-admin-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.balrog-admin.arn
    type             = "forward"
  }
}


# DNS
resource "aws_route53_record" "balrogadmin-ghosterydev-com" {
  zone_id = local.dns_zone_id
  name    = local.dns_name_admin
  type    = "A"

  alias {
    name = aws_lb.balrog-admin-lb.dns_name
    zone_id = aws_lb.balrog-admin-lb.zone_id
    evaluate_target_health = true
  }
}
