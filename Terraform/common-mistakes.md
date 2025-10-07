Every region has a different AMI ID, if you want to create a Terraform code that works for all the region and can deal with different AMI IDs based on regions? What is the best approach? **Make use of Data Source**

Alice is writing a module, and within the module, there are multiple places where she has defined the same set of Terraform expression. Whenever there is modification required in the expression, Alice has to go through multiple places in the code and modify everywhere. Use **Local Values** to deal with this.

Based on the following Terraform code, what is the name of IAM User that will be created? **`dev-loadbalancer and stage-loadbalanacer`**

```
variable "elb_names" {
  type = list
  default = ["dev-loadbalancer", "stage-loadbalanacer","prod-loadbalancer"]
}

resource "aws_iam_user" "lb" {
  name = var.elb_names[count.index]
  count = 2
  path = "/system/"
}
```

State locking **happens automatically** on all operations that could write state.

In which directory is the `terraform.tfstate` file created? **`terraform.tfstate.d`**

Matthew has referred to a child module that has the following code. Can Matthew override the instance_type from t2.micro to t2.large from the ROOT module directly? Because the `instance_type` is defined within the child module, and **you cannot directly override it from the ROOT module** without using a variable.

```
resource "aws_instance" "myec2" {
   ami = "ami-082b5a644766e0e6f"
   instance_type = "t2.micro
}
```

James has decided to not use the `terraform.tfvars` file, instead, he wants to store all data into `custom.tfvars` file? How can he deal with this use-case while running terraform plan? **`terraform plan -var-file="custom.tfvars"`**

Based on a new requirement, John has to create a new security group (firewall), and 60 different ports need to be whitelisted in this firewall. John wants to avoid **writing 60 different ingress blocks** and maintain (add/remove) whenever a new IP address needs to be added or removed in the subsequent updates. Use **`dynamic`** block.

**`dynamic`** block allows constructing a set of **nested configuration blocks**.

Alice has added a simple variable definition in Terraform code. Alice also has defined the following environment variable: `TF_kpnumber=6`, `TF_VAR_kpnumber=9`. There is also a `terraform.tfvars file` with the following contents `kpnumber = 7`
When you run the following apply command, what is the value assigned to the number variable? `terraform apply -var kpnumber=4`

```
variable "kpnumber" {
  default = 3
}
```

**Command-line `terraform apply -var kpnumber=4` has the highest precedence.**

Due to some issues, the state file is in a locked state, and users are not able to perform terraform apply operations further. What actions can be taken to overcome this? **Use the `terraform force-unlock`**

Following are the output values defined in Child and Root Module, On a terraform apply, which output values will be displayed? **Output values of Root Module**

```
# Child Module
output "child_module" {
  value = "This is Child Module"
}

# Root Module:
output "root_module" {
  value = "This is ROOT Module"
}
```

Alice has started to make use of **Terraform Cloud Workspace** and has linked a Git Repository to it. Whenever a new code change is committed to the version control repository, **Terraform will automatically run the terraform plan operation.**
