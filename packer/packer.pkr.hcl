packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu_custom" {
  ami_name      = "custom-node-nginx-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]  # Propietario oficial de imágenes de Ubuntu
    most_recent = true
  }
  ssh_username = "ubuntu"
}

build {
  sources = [
    "source.amazon-ebs.ubuntu_custom"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nodejs nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "sudo rm -f /home/ubuntu/.ssh/authorized_keys"  # Limpia el authorized_keys
    ]
  }
}
