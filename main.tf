provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "edge_stream" {
  name        = "edge-stream-sg"
  description = "Allow Custom TCP and SSH access"

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "edge-stream"
  }
    }

resource "aws_instance" "edge_stream_2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  key_name = "EdgeStream"

  root_block_device  {
    volume_type = "gp3"
    volume_size = 30
  }

  vpc_security_group_ids = [aws_security_group.edge_stream.id]

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # Add Docker's official GPG key:
    apt-get update -y
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
      | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Optional: let ubuntu user use docker without sudo (if default AMI user is 'ubuntu')
    if id ubuntu >/dev/null 2>&1; then
      usermod -aG docker ubuntu
    fi
  EOF

  

  tags = {
    Name = "edge-stream"
  }
  
}
