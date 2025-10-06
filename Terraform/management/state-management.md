#### Code example
```sh
terraform {
  backend "s3" {
    bucket = "demo-tfstate-backends"
    key    = "demo.tfstate"
    region = "ap-southeast-2"
  }
}

resource "aws_iam_user" "dev" {
  name = "demo-user-01"
}

resource "aws_security_group" "prod" {
  name        = "demo-firewalls"
}
```

#### List the Resources Managed through Terraform

```bash
terraform state lish
```

#### Show Attributes of Resource

```bash
terraform state show aws_security_group.prod
```

#### Pull the State file From Remote Backend

```sh
terraform state pull
```
#### Terraform State RM

Extra code used as part of this example

```sh
resource "aws_vpc_security_group_ingress_rule" "example" {
  security_group_id = aws_security_group.prod.id

  cidr_ipv4   = "10.0.0.0/8"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "example2" {
  security_group_id = aws_security_group.prod.id

  cidr_ipv4   = "10.0.0.0/8"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}
```
```sh
terraform state rm aws_security_group.prod
terraform state rm aws_vpc_security_group_ingress_rule.example
terraform state rm aws_vpc_security_group_ingress_rule.example2
```

#### Moving Resource Address
```sh
terraform state mv aws_iam_user.dev aws_iam_user.prod
```

#### Replace Provider
```sh
terraform state replace-provider hashicorp/aws kplabs.in/internal/aws
```