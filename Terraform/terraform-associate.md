## concepts

**Infrastructure as Code (IaC) best practices emphasize:**

- Version control of all infrastructure changes,
- Code review workflows (e.g., pull requests),
- Automated and auditable deployments via tools like HCP Terraform/Terraform Cloud.

**HCL (HashiCorp Configuration Language) does not support user-defined functions.** It provides a rich set of built-in functions (e.g., file(), join(), lookup(), length(), etc.), but users cannot define custom functions directly within HCL.

**Terraform automatically manages resource dependencies** using the interpolation of resource attributes. The depends_on argument is only needed for manual dependency overrides when **implicit** references are not present but a dependency still exists (e.g., provisioners, side effects).

## syntax

You have declared a variable called `var.list` which is a list of objects that all have an attribute `id`. **Which options will produce a list of the IDs?**

```hcl
[ for o in var.list : o.id]
# or
var.list[*].id
```

In the required_providers block, you must use HCL syntax with **an assignment operator and quotes to define version constraints.**

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # must use quotes
      version = ">= 3.1"
      # version = "~> 3.1"
    }
  }
}
```

**The only required argument when declaring a Terraform output is `value`.**

```
output "instance_id" {
 value = aws_instance.example.id
}
```

## init

**When you run `terraform init`, Terraform:**

- Initializes the working directory,
- Downloads and caches all remote modules defined in the configuration,
- Retrieves provider plugins, and
- Sets up the backend, if configured.

**Terraform installs all required providers during the terraform init phase. This command:**

- Downloads provider plugins,
- Installs modules,
- Initializes the backend (if configured),
- Prepares the working directory for subsequent operations.

It is **discouraged** to change the Terraform backend from the default “local” backend to a different one after performing your first terraform apply.
You must run `terraform init` to reconfigure the backend and migrate existing state, which can be risky if not handled properly. Terraform will prompt to migrate the state file during reinitialization, and incorrect handling could cause infrastructure drift.

## apply

**About `terraform apply`:**

- Depending on provider specification, Terraform may need to destroy and recreate your infrastructure resources.
- It only operates on infrastructure defined in the current working directory or workspace.

**A Terraform backend determines how Terraform loads state and stores updates when you execute which command?**
A Terraform backend controls how state is loaded and updated. When you run `terraform apply` or `terraform destroy`, Terraform loads the current state from the backend, and updates the state after changes are applied.

**Use `terraform init` and `terraform apply`** to provision new infrastructure with Terraform.

## validate

`terraform validate` checks the syntax and internal consistency of your configuration locally. **It does not interact with provider APIs or remote systems.** For provider-level validation (e.g., checking resource existence or credentials), you'd use `terraform plan` or `terraform apply`.

`terraform validate` checks for syntax errors and internal consistency within your configuration files. **It will report an error if you declare the same resource address (e.g., aws_instance.web) more than once, as each resource must have a unique identifier.**

**When you run `terraform validate`, you get the following error, what should you do to retrieve this value?**

```hcl
output "net_id"{
    value = module.my_network.vnet_id
}
```

```bash
Error: Reference to undeclared output value
on main.tf line 12, int output "net_id": value = module.my_network.vnet_id
```

Define the attribute `vnet_id` as an output in the networking module.

## state file

**The Terraform state file:**

- Maps your Terraform configuration to real infrastructure,
- Tracks resource attributes and metadata (e.g., IDs, dependencies),
- Is essential for determining changes between the current state and desired configuration during plan and apply.

**Other options describe capabilities outside the core purpose of state:**

- Dependencies are handled in configuration, not state alone.
- Variables and code reuse are handled by modules and variable files.
- Compliance enforcement is handled via policy tools like Sentinel, not state.

## state backend

**Where in your Terraform configuration do you specify a state backend?** The terraform block
Use **HCP Terraform/Terraform Cloud and S3** to store the state file.

```
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key = "env/dev/terraform.tfstate"
    region = "us-west-2"
  }
}
```

You decide to move a Terraform state file to Amazon S3 from another location. You write the code shown in the Exhibit space into a file called `backend.tf`.

```hcl
terraform{
  backend "s3"{
    bucket = "my-tf-bucket"
    region = "us-east-1"
  }
}
```

You should use `terraform init` command to migrate current state file to the new S3 backend.

## other commands

`terraform fmt` automatically **formats** all `.tf` and `.tfvars` files in the current directory (and
subdirectories with -recursive).

`terraform import` requires **Resource ID or Resource address**, for example: `terraform import aws_instance.example i-0abcd1234efgh5678`

## security

**The best practice to store secret data is to:** 1. Store secrets in secure external systems (e.g., HashiCorp Vault, AWS Secrets Manager). 2. Load them into Terraform via environment variables, terraform.tfvars (excluded from version control), or external data sources.

**Terraform does not encrypt sensitive values in the state file by default.** Even if a variable or output is marked as sensitive, Terraform only hides it from CLI output, not from the state file itself. To protect sensitive values, you should: 1. Use a secure backend that supports encryption at rest (e.g., S3 with server-side encryption, Terraform Cloud). 2. Use appropriate access controls to restrict state file access.

## provider

While Terraform by default installs providers from the Terraform Registry over the internet, it also supports:

- Local provider installation from a filesystem mirror,
- Private registries,
- Custom provider sources via the required_providers block and `provider_installation` configuration.

**This allows offline use, internal provider development, or controlled provider versions within secure environments.**

**Terraform cannot load a provider directly from source code.** Providers must be compiled into binaries and placed in: The plugins directory, or Retrieved from the Terraform Registry or custom sources.
Terraform can load providers from: Provider plugin cache, Plugins directory, Official HashiCorp releases (`releases.hashicorp.com` or the Terraform Registry)

The Terraform CLI binary version and provider versions **do not have to match**. Terraform uses version constraints (in the required_providers block) to determine which provider versions are compatible with the configuration. You can use different versions of providers as long as they are compatible with the Terraform binary version you are using.

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}
```

**You need to deploy resources into two different regions in the same Terraform configuration. To do this, you declare multiple provider configurations as shown in the Exhibit space on this page.**

```hcl
provider = "aws" {
  region = "us-east-1"
}

provider = "aws" {
  alias = "west"
  region = "us-east-2"
}
```

You need to configure in a resource block with meta-argument:

```
resource "aws_instance" "example" {
  # use this meta-argument
  provider = aws.west
}
```

Terraform uses **a plugin-based architecture**, allowing providers to be developed and maintained independently of the core Terraform binary.
If no provider exists for your API, you can write your own custom provider in Go using the Terraform Plugin SDK.

**All of the listed statements about Terraform providers are true:**

- Anyone can write a provider using the Terraform Plugin SDK.
- Community-maintained providers are common and often published to the public Terraform Registry.
- HashiCorp maintains many official providers (e.g., AWS, Azure, Google).
- Cloud vendors and infrastructure companies often create and maintain their own providers or collaborate with the community.

To align with these principles you should use a pull request workflow, ensuring the change is reviewed, approved, and tracked, in another word, you should **Submit a pull request and wait for an approved merge of the proposed changes**.

## HCP (Hashicorp Cloud Platform)

Terraform/Terraform Cloud, workspaces can be managed and switched via the web UI, API, or CLI — **you're not limited to the CLI.** Correct statements: 1. Plans and applies can be triggered via version control system integrations. 2. Workspaces support role-based access control. 3. They can securely store cloud credentials using workspace-specific variables and secrets.

**The benefits of using Sentinel with HCP Terraform/Terraform Cloud include:**
(Note: Sentinel is a policy-as-code framework integrated with HCP Terraform/Terraform Cloud that allows you to enforce governance and compliance rules on infrastructure provisioning.)

- You can restrict specific resource configurations, such as disallowing the use of CIDR=0.0.0.0/0.
- You can enforce a list of approved AWS AMIs.
- Policy-as-code can enforce security best practices.

HCP Terraform (formerly Terraform Cloud) allows workspace state sharing, which means you can use the output values from one workspace as data sources in another workspace. **This is not natively supported in standalone Terraform CLI.**
