provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "aula_02" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "Aula-02-vpc"
  }
}

resource "aws_subnet" "aula_02" {
  vpc_id                  = aws_vpc.aula_02.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "aula-02-sb"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.aula_02.id

  tags = {
    Name = "aula-02-igw"
  }
}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.aula_02.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "aula-02-rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.aula_02.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow SSH inbound"
  vpc_id      = aws_vpc.aula_02.id

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

  tags = {
    Name = "Aula-02-sg"
  }
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer_key"
  public_key = " "
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Ubuntu / Canonical owner ID
}

resource "aws_instance" "web" {
  count                         = 3
  ami                           = data.aws_ami.ubuntu.id
  instance_type                 = "t2.micro"
  key_name                      = aws_key_pair.deployer_key.key_name
  subnet_id                     = aws_subnet.aula_02.id
  vpc_security_group_ids        = [aws_security_group.allow_web.id]
  associate_public_ip_address   = true
  user_data = <<-EOF
      #!/bin/bash
      sudo apt-get update
      sudo apt-get install -y openjdk-17-jdk apache2
      
      # Habilitar e iniciar o Apache Web Server
      systemctl enable apache2
      systemctl start apache2
      
      # Verificar se o Java foi instalado corretamente
      java -version
      EOF

  tags = {
    Name = "WebServer-${count.index}"
  }
}
