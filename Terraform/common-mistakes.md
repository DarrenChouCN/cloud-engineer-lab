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

```
variable "myvar" {
  type = string
}
```

Both 2 and "2" are accepted, **Terraform automatically converts number and bool values to strings when needed.**

```
resource "aws_iam_user" "lb" {
  name = var.elb_names[count.index]
  count = 50
  path = "/system/"
}
```

Use `aws_iam_user.lb[*].arn` to create resource.

The `terraform taint` command marks a resource to be recreated, but it does not terminate it immediately. Instead, the resource will remain intact until the next `terraform apply` operation is executed, at which point it will be recreated based on the configuration.

Developers in Medium Corp are facing a few issues while writing complex expressions that involve interpolation. **They have to run the terraform plan every time and check whether there are errors, and also verify the terraform apply to print value as a temporary output for the purpose of debugging.** What can be achieved to avoid this?
Using the terraform console command allows you to interactively evaluate expressions and interpolations without needing to run a full plan or apply, making it a powerful tool for debugging.

There are a total of 3 workspaces available in a Terraform project. `workspacea, workspaceb, workspacec.` Matthew wants to create an additional workspace named testing. Which command will create a new workspace? **`terraform workspace new testing`**

Matthew wants to set a Terraform variable using the environment variables. What is the right format of environment variable name that needs to be defined? **`TF_VAR_name`**

James has set the following environment variable: `TF_LOG_PATH=./terraform-debug.log` However, even after running multiple Terraform operations, the logs are not stored in the `terraform-debug.log` file. What is the issue? **Set the TF_LOG environment variable**

You want to contribute to the Terraform project. There are certain bugs that are reported in Terraform binary, and you want to add a fix to it so that it is fixed in the newer Terraform version. Which language you will need to write the fix? **GO** (Terraform developed by Go language)

**Which Terraform files should be ignored by Git when committing code to a repository?** 1. Files named exactly terraform.tfvars or terraform.tfvars.json. 2.terraform.tfstate 3. Any files with names ending in .auto.tfvars or .auto.tfvars.json.

Following is the sample terraform code:

```
output "db_password" {
  value       = aws_db_instance.db.password
  description = "RDS Password"
  sensitive   = true
}
```

Will the value associated with aws_db_instance.db.password be present within the terraform state file? **Ture**, it's terraform state file, not `terraform apply`

Matthew intends to reference a VPC module from Git repository. There is a requirement to use a specific branch instead of the default branch. What is the way to achieve this?

```
module "vpc" {
  # end with "ref= v2.0.0"
  source = "git::https://kplabs.example.com/vpc.git?ref=v2.0.0"
}
```

**Matthew has created a new VPC module and he wants to publish the module to the Terraform registry. What are the requirements to publish the module to the Public Registry?** 1. Module repositories must use this three-part name format, terraform-provider-name 2. elease tag names must be a semantic version, which can optionally be prefixed with a v 3. The module must be on GitHub and must be a public repo.

Matthew has configured AWS provider within his terraform code. Where will be the associated plugins for that provider be stored? **`./terraform/providers`**

For the Remote Exec Provisioners, which among the following are the supported connection types? **WinRM and ssh**

**EC2 instance will be configured with an application and application requires connectivity to Database before it can start.** Hence Database instance should be created first before EC2. What is the way to achieve this? Specify an explicit dependency using the depends_on attribute.

Enterprise Corp has a requirement to capture the highest verbosity of Logs. **Which of the following environment variables need to be set to achieve this use case?** **TF_LOG = TRACE**

The instance-id associated with manually created EC2 is `i-234567`. How can the import process happen? **`terraform import aws_instance.myec2 i-234567`**

In Terraform, **child modules do not have visibility into variables defined in their parent modules** unless those variables are explicitly passed to them.

After your first terraform apply using the "local" backend, **is it possible to migrate your Terraform state to a different backend (such as S3 or Terraform Cloud)?** Possible to migrate

Suppose your team pushes new commits or merges a pull request to the main branch of the connected Git repository. Will this automatically trigger a speculative plan run in the linked HCP Terraform Cloud workspace?
Speculative plan runs in Terraform Cloud are specifically designed to provide a preview of changes before they are merged, and they are only triggered by opening new pull requests or branches.

Terraform providers are separate plugins that extend the functionality of Terraform and are **not included in the core binary.**

When a `.terraform.lock.hcl` file is present, Terraform consistently uses the provider versions specified in that file for all resources, ensuring uniformity in your infrastructure, even when adding new resources.

The `terraform_remote_state` data source can indeed access state information managed by the local backend, allowing you to retrieve outputs from one configuration to use in another.

**"Air Gapped,"** it refers to a method of installing Terraform in environments without internet access, ensuring that all necessary components are transferred through secure, isolated methods, as explained in the provided HashiCorp article.

During the terraform init operation, **Terraform looks for module blocks in the configuration and retrieves the source code of the referenced modules from the specified locations.**

Terraform workspace feature is **not recommended** for scenarios requiring a strong separation between development and production environments. Instead, it's better to use distinct configurations or directories to maintain clear boundaries and control over the environments.

By selecting "terraform taint null_resource.demo and then run terraform apply," you correctly identified that tainting the resource forces Terraform to recreate it, **thus re-running the local-exec provisioner command associated with it.**

Alice has created a new Public IP in AWS using following code:

```
resource "aws_eip" "lb" {
  vpc      = true
}
```

The Public IP was successfully created in AWS but the IP details was not shown in the CLI. Alice forgot to add "output" section in code that would display the IP details. What is the way in which Alice can find the IP Address details without having to login to AWS?

**`terraform state show aws_eip.lb`**

**"Terraform Configuration for Creating Resource"**: this configuration defines how resources are created but does not interact directly during the terraform refresh operation, which focuses on synchronizing the state with the live infrastructure.

`terraform.tfvars` and `terraform.tfstate` are recommended to be excluded while committing Terraform Code to a Git Repository.
