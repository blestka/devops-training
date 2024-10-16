provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "task2_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "task2_vpc"
  }
}

resource "aws_internet_gateway" "task2_igw" {
  vpc_id = aws_vpc.task2_vpc.id
  tags = {
    Name = "task2_igw"
  }
}

resource "aws_subnet" "task2_public_subnet" {
  vpc_id                  = aws_vpc.task2_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "task2_public_subnet"
  }
}

resource "aws_subnet" "task2_private_subnet" {
  vpc_id            = aws_vpc.task2_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"
  tags = {
    Name = "task2_private_subnet"
  }
}

resource "aws_route_table" "task2_public_route_table" {
  vpc_id = aws_vpc.task2_vpc.id
  tags = {
    Name = "task2_public_route_table"
  }
}

resource "aws_route_table_association" "task2_public_route_assoc" {
  subnet_id      = aws_subnet.task2_public_subnet.id
  route_table_id = aws_route_table.task2_public_route_table.id
}

resource "aws_route" "task2_public_route" {
  route_table_id         = aws_route_table.task2_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.task2_igw.id
}

# resource "aws_eip" "task2_nat_eip" {
#   vpc = true
# }
#
# resource "aws_nat_gateway" "task2_nat_gateway" {
#   allocation_id = aws_eip.task2_nat_eip.id
#   subnet_id     = aws_subnet.task2_public_subnet.id
#   tags = {
#     Name = "task2_nat_gateway"
#   }
# }
#
#
# resource "aws_route_table" "task2_private_route_table" {
#   vpc_id = aws_vpc.task2_vpc.id
#   tags = {
#     Name = "task2_private_route_table"
#   }
# }
#
# resource "aws_route_table_association" "task2_private_route_assoc" {
#   subnet_id      = aws_subnet.task2_private_subnet.id
#   route_table_id = aws_route_table.task2_private_route_table.id
# }
#
# resource "aws_route" "task2_private_route" {
#   route_table_id         = aws_route_table.task2_private_route_table.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.task2_nat_gateway.id
# }

resource "aws_security_group" "task2_public_sg" {
  vpc_id = aws_vpc.task2_vpc.id

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

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "task2_public_sg"
  }
}

resource "aws_security_group" "task2_private_sg" {
  vpc_id = aws_vpc.task2_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "task2_private_sg"
  }
}

resource "aws_instance" "task2_ubuntu_instance" {
  ami                         = "ami-0084a47cc718c111a"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.task2_public_subnet.id
  security_groups             = [aws_security_group.task2_public_sg.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  tags = {
    Name = "task2_ubuntu_instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y nginx

              echo '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Hello World</title></head><body><h1>Hello World!</h1><p>OS Version: Ubuntu 24.04.1 LTS</p></body></html>' > /var/www/html/index.html

              systemctl enable nginx
              systemctl start nginx

              # script from official docker manual - https://docs.docker.com/engine/install/ubuntu/
              # Add Docker's official GPG key:
              sudo apt-get update
              sudo apt-get install ca-certificates curl
              sudo install -m 0755 -d /etc/apt/keyrings
              sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              sudo chmod a+r /etc/apt/keyrings/docker.asc

              # Add the repository to Apt sources:
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update

              sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              EOF
}

resource "aws_instance" "task2_amazon_linux_instance" {
  ami                         = "ami-08ec94f928cf25a9d"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.task2_private_subnet.id
  security_groups             = [aws_security_group.task2_private_sg.id]
  associate_public_ip_address = false

  tags = {
    Name = "task2_amazon_linux_instance"
  }
}

