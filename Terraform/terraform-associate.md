## concepts

**Infrastructure as Code (IaC) best practices emphasize:**

- Version control of all infrastructure changes,
- Code review workflows (e.g., pull requests),
- Automated and auditable deployments via tools like HCP Terraform/Terraform Cloud.

Infrastructure as Code (IaC) focuses on defining infrastructure using declarative configuration files, **not a GUI (Graphical User Interface).** The benefits include Versioning, Automation and Reusability.

**HCL (HashiCorp Configuration Language) does not support user-defined functions.** It provides a rich set of built-in functions (e.g., file(), join(), lookup(), length(), etc.), but users cannot define custom functions directly within HCL.

**Terraform automatically manages resource dependencies** using the interpolation of resource attributes. The depends_on argument is only needed for manual dependency overrides when **implicit** references are not present but a dependency still exists (e.g., provisioners, side effects).

**What is the goal of Iac?** The programmatic configuration of resources.

If a DevOps team adopts AWS CloudFormation as their standardized method for provisioning public cloud resources, which of the following scenarios poses a challenge for this team?
The organization decides to expand into **Azure** and wishes to deploy new infrastructure.

**How can a ticket-based system slow down infrastructure provisioning and limit the ability to scale?**

- End-users have to request infrastructure changes.
- The more resources your organization needs, the more tickets your infrastructure team has to process.

You add a new resource to an existing Terraform configuration, but do not update the version constraint in the configuration. The existing and new resources use the same provider. The working directory contains a `.terraform.lock.hcl` file. **Terraform will use the version recorded in your lock file** (unless you explicitly run terraform init -upgrade to update it).

## syntax

You can reference a resource created with for_each **using a splat ( \* ) expression**, for example: `aws_instance.example[*].id`

**When using multiple configurations of the same Terraform provider,** what meta-argument must you include in any non-default provider configurations? **`alias`**

The three valid **Terraform collection type**: `list, map, set`

**You want to define multiple data disks as nested blocks inside the resource block for a virtual machine.** What Terraform feature would help you define the blocks using the values in a variable? **Dynamic blocks**

An object type ` object({ name=string, age=number})` match value: `{name = "John" age = 52}`

You have declared a variable called `var.list` which is a list of objects that all have an attribute `id`. **Which options will produce a list of the IDs?**

When declaring a variable in Terraform, **no arguments are strictly required.** A minimal variable declaration can be as simple as:
`variable "example" {}`
The type, default, and description arguments are all optional, but often used for clarity, validation, and documentation.

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

Which type of block fetches or computes information for use elsewhere in a Terraform configuration? **`data`**
Example:

```
data "aws_ami" "latest" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}
```

**Reference:**

```
resource "kubernetes_namespace" "example"{
	name = "test"
}
```

Reference the attribute name: `kubernetes_namespace.example.name`

## log

**Error loading state: AccessDenied: Access Denied status code: 403…**
You should Set `TF_LOG=DEBUG` to determine the root cause of the problem.

You want to know from **which paths Terraform is loading providers** referenced in your Terraform configuration ( \*.tf files). You need to enable additional logging messages to find this out. Set the environment variable `TF_LOG=TRACE`.

## init

To ensure your plugins are up-to-date with the latest versions, use terraform `init -upgrade`.

Before you can use a new backend or HCP Terraform/Terraform Cloud integration, you must first execute `terraform init`. (Without running terraform init, Terraform will not be able to communicate with the backend, store state remotely, or connect to Terraform Cloud.)

**When does Terraform create the `.terraform.lock.hcl` file?** After your first `terraform init`.

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

## plan & destroy

Which of the following can you do with `terraform plan`? 1. View the execution plan and check if the changes match your expectations. 2.Save a generated execution plan to apply later.

**What Terraform command always causes a state file to be updated with changes that might have been made outside of Terraform?** `terraform plan -refresh-only`
`terraform plan -refresh-only` updates the state file to reflect the actual real-world infrastructure, without proposing or applying any changes defined in the configuration. It is explicitly used to refresh the state from the current infrastructure and save that to the state file.

Which command should you use to show all the resources that will be deleted?

- Run `terraform destroy`. This will output all the resources that will be deleted before prompting for approval.
- Run `terraform plan -destroy`.

Passing `--destroy` at the end of a plan request is not a way to trigger terraform destroy.

## apply

**About `terraform apply`:**

- Depending on provider specification, Terraform may need to destroy and recreate your infrastructure resources.
- It only operates on infrastructure defined in the current working directory or workspace.

**A Terraform backend determines how Terraform loads state and stores updates when you execute which command?**
A Terraform backend controls how state is loaded and updated. When you run `terraform apply` or `terraform destroy`, Terraform loads the current state from the backend, and updates the state after changes are applied.

**Use `terraform init` and `terraform apply`** to provision new infrastructure with Terraform.

By default, terraform apply will **only print output values from the root module.** If a child module has outputs, those must be explicitly re-exposed in the root module like this:

```

output "child_output" {
value = module.child_module_name.output_name
}

```

Without this, the child module’s outputs are not displayed in the CLI output.

You just scaled your VM infrastructure and realized you set the count variable to the wrong value. You correct the value and save your change. **What do you do next to make your infrastructure match your configuration?**
Run `terraform apply` and confirm the planned changes.

You have a Terraform configuration and have run `terraform apply` to create a virtual machine; then you removed the resource definition from your Terraform configuration file. **What will happen when you run terraform apply in the working directory again?** Terraform will **destroy** the virtual machine.

**When do you need to explicitly execute Terraform in refresh-only mode?** `terraform apply -refresh-only` is useful only when you want to update the state to reflect real-world infrastructure without making changes to the configuration or infrastructure. It’s mainly used for diagnostics or correcting drift in the state without planning/applying any new changes.

## validate

You must run `terraform init` before `terraform validate` because validate needs the provider plugins and module metadata, which are downloaded during initialization.

Use `terraform validate` to check your configuration syntax is correct.

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

## module

**The public Terraform Registry allows anyone with a GitHub account to publish modules**, provided the module follows the required naming conventions and repository structure.

The Terraform Registry displays documentation for published modules, **including required input variables, optional inputs with default values, and the outputs that the module generates.**

**Child modules cannot automatically access variables from their parent module.** The parent must explicitly pass variables to the child module using the module block:

```
module "child" {
  source = "./child"
  my_var = var.parent_var
}
```

Terraform modules **do not need to be publicly accessible** — they can be: Stored locally, Retrieved from a private Git repository, Pulled from private registries like Terraform Cloud.

## state file

Your security team scanned some Terraform workspaces and found secrets stored in plaintext in state files, you should **store the state in an encrypted backend.**

These actions will be forbidden when the Terraform state file is locked: `terraform apply, terraform plan, terraform destroy`

**How does Terraform determine dependencies between resources when it creates an execution plan?** Terraform builds a resource graph based on **your configuration and your state file (if present).**

If you don’t use the local Terraform backend, **where else can Terraform save resource state?** In a remote location configured in the `terraform` block, such as HCP Terraform or a cloud storage system.

**The Terraform state file:**

- Maps your Terraform configuration to real infrastructure,
- Tracks resource attributes and metadata (e.g., IDs, dependencies),
- Is essential for determining changes between the current state and desired configuration during plan and apply.

**Other options describe capabilities outside the core purpose of state:**

- Dependencies are handled in configuration, not state alone.
- Variables and code reuse are handled by modules and variable files.
- Compliance enforcement is handled via policy tools like Sentinel, not state.

Once you configure a new Terraform backend with a terraform code block, **which command(s) should you use to migrate the state file?** `terraform init`

## backend

What is the **default backend** that Terraform CLI use? **Local**.

**Not** all standard backend types support locking and remote operations (like plan, apply, destroy).

**Where in your Terraform configuration do you specify a state backend?** The terraform block

**Configure state locking for your state backend** to prevent two Terraform runs from changing the same state file at the same time.

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

`terraform state list 'provider_type.name'` is used for accessing all of the attributes and details of a resource managed by Terraform.

You have deployed a new webapp with a public IP address on a cloud provider. However, you did not create any outputs for your code. **What is the best method to quickly find** the IP address of the resource you deployed?
Run `terraform state list` to find the name of the resource, then `terraform state show` to find the attributes including public IP address.

How to determine which instance Terraform manages? Run `terraform state list` to find the names of all VMs, then run `terraform state show` for each of them to find which VM ID that Terraform manages.

`terraform fmt` command makes your code more human-readable.

`terraform fmt` automatically **formats** all `.tf` and `.tfvars` files in the current directory (and
subdirectories with -recursive).

Running `terraform fmt` without flags automatically rewrites Terraform configuration files to match the canonical style. It does not just check formatting; it actively changes the file contents to conform to standard formatting. To only check formatting without changing files, the `-check` flag must be used.

`terraform import` requires **Resource ID or Resource address**, for example: `terraform import aws_instance.example i-0abcd1234efgh5678`

**When automatic unlocking has failed** you should use the `force-unlock` command.

You created infrastructure outside the Terraform workflow that you now want to manage using Terraform. You should use `terraform import` to brings the infrastructure into Terraform state.

## security

When **provider credentials are set via environment variables**, Terraform reads them at runtime without writing them into the state file. Credentials specified in provider blocks or variables can be stored in the state, but environment variables ensure sensitive information is not persisted there.

How can HCP Terraform/Terraform Cloud **automatically and proactively enforce this security control?** With a **Sentinel policy**, which runs before every apply.

**The best practice to store secret data is to:** 1. Store secrets in secure external systems (e.g., HashiCorp Vault, AWS Secrets Manager). 2. Load them into Terraform via environment variables, terraform.tfvars (excluded from version control), or external data sources.

**Terraform does not encrypt sensitive values in the state file by default.** Even if a variable or output is marked as sensitive, Terraform only hides it from CLI output, not from the state file itself. To protect sensitive values, you should: 1. Use a secure backend that supports encryption at rest (e.g., S3 with server-side encryption, Terraform Cloud). 2. Use appropriate access controls to restrict state file access.

## provider

**What is a Terraform provider responsible for?**

- Provisioning infrastructure in multiple cloud providers.
- Understanding API interactions with a hosted service.
- Managing resources and data sources based on an API.

Terraform itself (the core engine) is responsible for creating and applying the execution plan, **which determines the actions to take based on resource differences.**

**Terraform providers are not part of the Terraform core binary.** They are separate plugins that Terraform downloads during terraform init based on your configuration.

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

## HCP

Use **HCP Terraform/Terraform Cloud and S3** to store the state file.

**In Terraform, a cloud block defines the configuration for using Terraform Cloud or HCP Terraform. Each cloud block maps directly to a single workspace,** ensuring Terraform runs and state management are tied to that specific workspace.

Speculative plan runs in HCP Terraform/Terraform Cloud occur automatically **when you open a pull request (PR) or push new commits to a PR, not when you merge.**

Terraform/Terraform Cloud, workspaces can be managed and switched via the web UI, API, or CLI — **you're not limited to the CLI.** Correct statements: 1. Plans and applies can be triggered via version control system integrations. 2. Workspaces support role-based access control. 3. They can securely store cloud credentials using workspace-specific variables and secrets.

**The benefits of using Sentinel with HCP Terraform/Terraform Cloud include:**
(Note: Sentinel is a policy-as-code framework integrated with HCP Terraform/Terraform Cloud that allows you to enforce governance and compliance rules on infrastructure provisioning.)

- You can restrict specific resource configurations, such as disallowing the use of CIDR=0.0.0.0/0.
- You can enforce a list of approved AWS AMIs.
- Policy-as-code can enforce security best practices.

HCP Terraform (formerly Terraform Cloud) allows workspace state sharing, which means you can use the output values from one workspace as data sources in another workspace. **This is not natively supported in standalone Terraform CLI.**

**How does the HCP Terraform/Terraform Cloud integration differ from backends such as S3, Consul, etc.?** It can execute Terraform runs on dedicated infrastructure in HCP Terraform/Terraform Cloud.

Which method for sharing Terraform modules fulfills the following criteria: 1. Keeps the module configurations confidential within your organization. 2. Supports Terraform’s semantic version constraints. 3. Provides a browsable directory of your modules.
**HCP Terraform/Terraform Cloud private registry.**
