# ALB 보안그룹 생성
resource "aws_security_group" "demo-3tier-alb-sg" {
  vpc_id = aws_vpc.demo-3tier.id
  name = "demo-3tier-alb-sg"
  description = "Security Group for ALB"
}

# ALB 보안그룹 Inbound rule
resource "aws_security_group_rule" "demo-3tier-alb-sg-inbound" {
  type = "ingress"
  from_port = 0
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.demo-3tier-alb-sg.id
}

# ALB 보안그룹 Outbound rule
resource "aws_security_group_rule" "demo-3tier-alb-sg-outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1" 
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.demo-3tier-alb-sg.id
}

# ASG 보안그룹 생성
resource "aws_security_group" "demo-3tier-asg-sg" {
  vpc_id = aws_vpc.demo-3tier.id
  name = "demo-3tier-asg-sg"
  description = "Security Group for EC2 Auto Scaling Group"

  depends_on = [ 
    aws_security_group.demo-3tier-alb-sg
   ]
}

# ASG 보안그룹 Inbound rule
resource "aws_security_group_rule" "demo-3tier-asg-sg-inbound" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  source_security_group_id = aws_security_group.demo-3tier-alb-sg.id
  security_group_id = aws_security_group.demo-3tier-asg-sg.id

  depends_on = [ 
    aws_security_group.demo-3tier-asg-sg 
    ]
}

# ALB 보안그룹 Outbound rule
resource "aws_security_group_rule" "demo-3tier-asg-sg-outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1" 
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.demo-3tier-asg-sg.id

  depends_on = [ 
    aws_security_group.demo-3tier-asg-sg 
    ]
}

# RDS 보안그룹 생성
resource "aws_security_group" "demo-3tier-rds-sg" {
  vpc_id = aws_vpc.demo-3tier.id
  name = "demo-3tier-rds-sg"
  description = "Security Group for RDS"

  depends_on = [ 
    aws_security_group.demo-3tier-asg-sg
   ]
}

# RDS 보안그룹 Inbound rule
resource "aws_security_group_rule" "demo-3tier-rds-sg-inbound" {
  type = "ingress"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  source_security_group_id = aws_security_group.demo-3tier-asg-sg.id
  security_group_id = aws_security_group.demo-3tier-rds-sg.id

  depends_on = [ 
    aws_security_group.demo-3tier-asg-sg 
    ]
}

# RDS 보안그룹 Outbound rule
resource "aws_security_group_rule" "demo-3tier-rds-sg-outbound" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1" 
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.demo-3tier-rds-sg.id

  depends_on = [ 
    aws_security_group.demo-3tier-asg-sg 
    ]
}
