provider "aws" {
  region = "ap-southeast-2"
}

# local-exec provisioner
resource "aws_instance" "myec2" {
  ami           = "ami-0c462b53550d4fca8"
  instance_type = "t3.micro"

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> server_ip.txt"
    # tells Terraform to ignore the provisioner’s error (don’t taint the resource) 
    # and keep applying the rest of the plan
    on_failure = continue
  }
}

# remote-exec provisioner
/*
resource "aws_instance" "myec2" {
  ami                    = "ami-0c462b53550d4fca8"
  instance_type          = "t3.micro"
  key_name               = "terraform-key"
  vpc_security_group_ids = ["sg-0edf854d7112cfbf4"]

  connection {
    type        = "ssh"
    user        = "ec2-user"

    # -- DO NOT include .pem file into project, this is a sample -- 
    private_key = file("./terraform-key.pem")
    host        = self.public_ip
  }


  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install nginx",
      "sudo systemctl start nginx",
    ]
  }
}
*/
