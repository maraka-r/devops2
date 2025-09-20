# ==========================
# Région AWS et profil
# ==========================
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "426941767449"
}

# ==========================
# Clé SSH et sécurité
# ==========================
variable "ssh_private_key_path" {
  description = "C:/Users/laoua/.ssh/devops2.pem"

  type        = string
}

variable "ssh_key_name" {
  description = "Nom de la clé SSH pour EC2"
  type        = string
  default     = "devops2"
}

variable "ssh_allowed_cidr" {
  description = "CIDR autorisé pour SSH"
  type        = string
  default     = "0.0.0.0/0"
}

# ==========================
# Type et nombre d'instances
# ==========================
variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "front_vm_count" {
  description = "Nombre d'instances EC2 pour le frontend"
  type        = number
  default     = 2
}

variable "back_vm_count" {
  description = "Nombre d'instances EC2 pour le backend"
  type        = number
  default     = 2
}

# ==========================
# VPC et Subnets
# ==========================
variable "vpc_cidr" {
  description = "CIDR pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_a_cidr" {
  description = "CIDR pour le subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_b_cidr" {
  description = "CIDR pour le subnet B"
  type        = string
  default     = "10.0.2.0/24"
}

# ==========================
# Nom du projet pour tags
# ==========================
variable "project_name" {
  description = "Nom du projet pour les tags AWS"
  type        = string
  default     = "AWS-IaC-React-Monitoring"
}

# ==========================
# Repositories ECR
# ==========================
variable "ecr_region" {
  description = "Région AWS du repository ECR"
  type        = string
  default     = "eu-west-3"
}
variable "frontend_repo" {
  description = "Nom du repository ECR pour le frontend"
  type        = string
  default     = "test-repo-frontend"
}

variable "backend_repo" {
  description = "Nom du repository ECR pour le backend"
  type        = string
  default     = "test-repo-backend"
}


# ========================================
# Ports
# ========================================

variable "frontend_port" {
  description = "Port d'écoute pour le frontend"
  type        = number
  default     = 80
}

variable "backend_port" {
  description = "Port d'écoute pour le backend"
  type        = number
  default     = 80
}






