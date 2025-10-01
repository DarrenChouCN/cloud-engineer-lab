# cross resource attribute references
provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_eip" "lb" {
  domain = "vpc"
}

output "public-ip" {
  # value = aws_eip.lb.public_ip
  value = "https://${aws_eip.lb.public_ip}:8080"
}

resource "aws_security_group" "example" {
  name = "attribute-sg"
}

resource "aws_vpc_security_group_ingress_rule" "example" {
  security_group_id = aws_security_group.example.id
  ip_protocol       = "tcp"

  from_port = 443
  to_port   = 443

  cidr_ipv4 = "${aws_eip.lb.public_ip}/32"
}
