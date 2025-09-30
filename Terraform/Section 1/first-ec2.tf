provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_instance" "myec2" {
  ami           = "ami-0059ed5a3aacdfe15"
  instance_type = "t3.micro"
}
