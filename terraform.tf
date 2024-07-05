provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_security_group"
  description = "Allow all inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "chat_ui" {
  ami                    = "ami-04a81a99f5ec58529"  # AMI для Ubuntu Server 24.04
  instance_type          = "t3.micro"
  security_groups        = [aws_security_group.ec2_sg.name]
  key_name               = "chat-ui-key"

  tags = {
    Name = "ChatUI"
  }
}

resource "aws_lb" "chat_lb" {
  name               = "chat-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id]
  subnets            = ["subnet-01becaf2509a20654", "subnet-07accd37f7f3d22d5"]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "chat_tg" {
  name     = "chat-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-087e4bad9b3533d9f"
}

resource "aws_lb_listener" "chat_listener" {
  load_balancer_arn = aws_lb.chat_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chat_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "chat_attachment" {
  target_group_arn = aws_lb_target_group.chat_tg.arn
  target_id        = aws_instance.chat_ui.id
  port             = 80
}

