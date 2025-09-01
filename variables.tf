
# Région AWS
variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

# Type d'instance
variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

# Clé SSH pour EC2
variable "ssh_key_name" {
  description = "Clé SSH utilisée pour se connecter"
  type        = string
  default     = "devops2"
}

# CIDR autorisé pour SSH
variable "ssh_allowed_cidr" {
  description = "CIDR autorisé pour SSH"
  type        = string
  default     = "0.0.0.0/0"
}

# Nombre d'instances EC2 backend
variable "back_vm_count" {
  description = "Nombre d'instances EC2 pour le backend"
  type        = number
  default     = 2
}

# Nombre d'instances EC2 frontend
variable "front_vm_count" {
  description = "Nombre d'instances EC2 pour le frontend"
  type        = number
  default     = 2
}

# VPC CIDR
variable "vpc_cidr" {
  description = "CIDR pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnets CIDR
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

# Nom du projet pour les tags AWS
variable "project_name" {
  description = "Nom du projet pour les tags AWS"
  type        = string
  default     = "AWS-IaC-React-Monitoring"
}
