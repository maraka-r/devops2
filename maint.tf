provider "aws" {
  region = "eu-west-3" # Paris
}

# ------------------------
# Security Group
# ------------------------
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Allow HTTP, SSH, Backend"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ limite à ton IP en prod
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
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

# ------------------------
# EC2 Instance
# ------------------------
resource "aws_instance" "app_vm" {
  ami           = "ami-045a8ab02aadf4f88" # Ubuntu 22.04 LTS (Paris eu-west-3)
  instance_type = "t2.micro"             # Free Tier (1 vCPU)
  key_name      = "devops2"              # réutilisation de la clé existante
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "fullstack-app"
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu
  EOF
}

# ------------------------
# Outputs
# ------------------------
output "public_ip" {
  value = aws_instance.app_vm.public_ip
}
