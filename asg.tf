# AL2 중 x86 기반의 최신 AMI를 검색
data "aws_ami" "latest-al2" {
    most_recent = true
    filter {
      name = "owner-alias"
      values = ["amazon"]
    }

    filter {
      name = "name"
      values = ["amzn2-ami-hvm-*-x86_64-ebs"]
    }

    owners = ["amazon"]
}

# Launch Template 설정
resource "aws_launch_template" "demo-3tier-launchtemplate" {
  name_prefix = "demo-3tier-launchtemplate-"
  image_id = data.aws_ami.latest-al2.id
  instance_type = "t2.micro"
  metadata_options {
      http_endpoint = "enabled"
      http_tokens = "optional"
    }

  network_interfaces {
    associate_public_ip_address = false 
    security_groups = [aws_security_group.demo-3tier-asg-sg.id]
  }

  user_data = base64encode(<<-EOF
                #!/bin/bash
                wget https://busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-x86_64
                mv busybox-x86_64 busybox
                chmod +x busybox
                export RZAZ=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone-id)
                export IID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
                export LIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
                echo "<h1>This is test page - RegionAz: $RZAZ, Instance ID: $IID, Private IP: $LIP</h1>" > index.html
                nohup ./busybox httpd -f -p 80 &
                EOF
              )

  lifecycle {
    create_before_destroy = true
  }
}

# ASG 생성
resource "aws_autoscaling_group" "demo-3tier-asg" {
  name = "demo-3tier-asg"
  vpc_zone_identifier = [aws_subnet.demo-3tier-private1.id, aws_subnet.demo-3tier-private2.id]
  desired_capacity = 2
  min_size = 2
  max_size = 5
  health_check_type = "ELB"
  target_group_arns = [aws_lb_target_group.demo-3tier-alb-tg.arn]

  launch_template {
    id = aws_launch_template.demo-3tier-launchtemplate.id
    version = "$Latest"
  }

  depends_on = [ aws_lb_target_group.demo-3tier-alb-tg ]

  tag {
    key = "Name"
    value = "demo-3tier-asg"
    propagate_at_launch = true
  }
}

# ALB 생성
resource "aws_lb" "demo-3tier-alb" {
    name = "demo-3tier-alb"
    load_balancer_type = "application"
    subnets = [aws_subnet.demo-3tier-public1.id, aws_subnet.demo-3tier-public2.id]
    security_groups = [aws_security_group.demo-3tier-alb-sg.id]

    tags = {
      Name = "demo-3tier-alb"
    }
}

resource "aws_lb_listener" "demo-3tier-alb-listener-http" {
    load_balancer_arn = aws_lb.demo-3tier-alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code = 404
      }
    }
}

resource "aws_lb_target_group" "demo-3tier-alb-tg" {
    name = "demo-3tier-alb-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.demo-3tier.id

    health_check {
      path = "/"
      protocol = "HTTP"
      matcher = "200-299"
      interval = 5
      timeout = 3
      healthy_threshold = 2 
      unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "demo-3tier-alb-listener-rule1" {
    listener_arn = aws_lb_listener.demo-3tier-alb-listener-http.arn
    priority = 100

    condition {
      path_pattern {
        values = ["*"]
      }
    }

    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.demo-3tier-alb-tg.arn
    }
}

output "demo-3tier-alb-dns" {
  value = aws_lb.demo-3tier-alb.dns_name
  description = "The DNS address of the ALB"
}