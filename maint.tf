# ========================================
# Providers
# ========================================
provider "aws" {
  region  = var.region
  profile = "new-account"
}

# ========================================
# AMI Ubuntu
# ========================================
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ========================================
# VPC & Subnets
# ========================================
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_a_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_b_cidr
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "subnet_a_assoc" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet_b_assoc" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.route_table.id
}

# ========================================
# Security Groups
# ========================================
resource "aws_security_group" "alb_sg" {
  name   = "${var.project_name}-alb-sg"
  vpc_id = aws_vpc.main.id

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

resource "aws_security_group" "web_sg" {
  name   = "${var.project_name}-web-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "Frontend depuis ALB"
    from_port       = var.frontend_port
    to_port         = var.frontend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Backend depuis ALB"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "SSH depuis IP admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ========================================
# IAM Role pour EC2 -> accès ECR
# ========================================
resource "aws_iam_role" "ec2_ecr_role" {
  name = "${var.project_name}-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr_policy" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

# ========================================
# User Data pour Docker + déploiement
# ========================================
locals {
  frontend_user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y docker.io awscli
systemctl start docker
systemctl enable docker

aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin 426941767449.dkr.ecr.eu-west-3.amazonaws.com

docker pull 426941767449.dkr.ecr.eu-west-3.amazonaws.com/frontend-app:latest
docker run -d -p 80:80 --name frontend 426941767449.dkr.ecr.eu-west-3.amazonaws.com/frontend-app:latest
EOF

  backend_user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y docker.io awscli
systemctl start docker
systemctl enable docker

aws ecr get-login-password --region eu-west-3 | docker login --username AWS --password-stdin 426941767449.dkr.ecr.eu-west-3.amazonaws.com

docker pull 426941767449.dkr.ecr.eu-west-3.amazonaws.com/backend-app:latest
docker run -d -p 5000:5000 --name backend 426941767449.dkr.ecr.eu-west-3.amazonaws.com/backend-app:latest
EOF
}

# ========================================
# Instances EC2
# ========================================
resource "aws_instance" "frontend" {
  count                  = var.front_vm_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = element([aws_subnet.subnet_a.id, aws_subnet.subnet_b.id], count.index)
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = local.frontend_user_data
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  tags = { Name = "${var.project_name}-frontend-${count.index + 1}" }
}

resource "aws_instance" "backend" {
  count                  = var.back_vm_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = element([aws_subnet.subnet_a.id, aws_subnet.subnet_b.id], count.index)
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = local.backend_user_data
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  tags = { Name = "${var.project_name}-backend-${count.index + 1}" }
}

# ========================================
# Load Balancers
# ========================================
resource "aws_lb" "frontend_lb" {
  name               = "${substr(var.project_name,0,20)}-frlb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}

resource "aws_lb" "backend_lb" {
  name               = "${substr(var.project_name,0,20)}-belb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}

# ========================================
# Target Groups avec Health Checks (ignore_changes)
# ========================================
resource "aws_lb_target_group" "frontend_tg" {
  name     = "AWS-IaC-React-Monito-frtg"
  port     = var.frontend_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    ignore_changes = [name, port, protocol, health_check]
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "AWS-IaC-React-Monito-betg"
  port     = var.backend_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    ignore_changes = [name, port, protocol, health_check]
  }
}

# ========================================
# Listeners (ignore_changes)
# ========================================
resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.frontend_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  lifecycle {
    ignore_changes = [default_action, port, protocol]
  }
}

resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  lifecycle {
    ignore_changes = [default_action, port, protocol]
  }
}

# ========================================
# Attach Instances to TG
# ========================================
resource "aws_lb_target_group_attachment" "frontend_attach" {
  count             = var.front_vm_count
  target_group_arn  = aws_lb_target_group.frontend_tg.arn
  target_id         = aws_instance.frontend[count.index].id
  port              = var.frontend_port

  depends_on = [aws_lb_listener.frontend_listener]
}

resource "aws_lb_target_group_attachment" "backend_attach" {
  count             = var.back_vm_count
  target_group_arn  = aws_lb_target_group.backend_tg.arn
  target_id         = aws_instance.backend[count.index].id
  port              = var.backend_port

  depends_on = [aws_lb_listener.backend_listener]
}
