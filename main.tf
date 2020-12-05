terraform {
  backend "s3" {}
}

provider "aws" {
  region = "eu-west-2"
}

provider "cloudflare" {
  email      = var.cloudflare_email
  api_key    = var.cloudflare_apikey
  account_id = var.cloudflare_account_id
}

resource "aws_key_pair" "keys" {
  key_name   = "${var.instance_name}_keys"
  public_key = file(var.public_key_path)
}

resource "aws_eip" "eip" {
  instance = aws_instance.host.id
}

resource "aws_instance" "host" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.keys.key_name
  security_groups = [aws_security_group.host_sec_group.name]

  tags = {
    Name = var.instance_name
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_vol_size
  }

  # wait for the instance to come up
  # to run the playbook against it
  provisioner "remote-exec" {
    inline = ["echo ping"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.host.public_ip
      private_key = file(var.private_key_path)
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# provision the instance with the ansible playbook
resource "null_resource" "reprovisioner" {
  # run every time the playbook changes
  triggers = {
    policy_sha1 = sha1(file("ansible/main.yml"))
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${aws_eip.eip.public_ip}, ./ansible/main.yml --key-file ${var.private_key_path}"
  }
}

resource "aws_security_group" "host_sec_group" {
  name        = "${var.instance_name}_sec"
  description = "Security group for ${var.instance_name} host"

  # web from anywhere
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

  # ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_CIDR]
  }

  # kubectl
  ingress {
    from_port   = var.engine == "microk8s"? 16443 : 6443
    to_port     = var.engine == "microk8s"? 16443 : 6443
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_CIDR]
  }

  # vpn from anywhere
  ingress {
    from_port   = 31304
    to_port     = 31304
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "cloudflare_record" "dns_record" {
  zone_id = var.cloudflare_zone
  name    = var.domain_name
  value   = aws_eip.eip.public_ip
  type    = "A"
  ttl     = 1
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

  owners = ["099720109477"] # Canonical
}
