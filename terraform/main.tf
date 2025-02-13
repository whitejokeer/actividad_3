terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }    
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# -------------------------------------------------------
# Generación de la Key Pair
# -------------------------------------------------------

# Genera una clave privada RSA
resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Crea una Key Pair en AWS utilizando la clave pública generada
resource "aws_key_pair" "generated_key" {
  key_name   = "my-generated-key"
  public_key = tls_private_key.generated.public_key_openssh
}

# Guarda la llave privada generada en un archivo local usando local_sensitive_file
resource "local_sensitive_file" "private_key_file" {
  filename        = "../ansible/terraform_generated_key.pem"
  content         = tls_private_key.generated.private_key_pem
  file_permission = "0600"
}

# -------------------------------------------------------
# Creación del Security Group
# -------------------------------------------------------

resource "aws_security_group" "apollo_sg" {
  name        = "apollo-sg"
  description = "Security group for Apollo Server deployment"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Apollo Server (port 4000)"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound traffic to Kibana dashboard"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------
# Creación de la instancia EC2 con la Key Pair generada
# -------------------------------------------------------

resource "aws_instance" "apollo_instance" {
  ami             = var.custom_ami
  instance_type   = "t3.medium"
  key_name        = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [aws_security_group.apollo_sg.id]

  tags = {
    Name = "ApolloServer"
  }
}
