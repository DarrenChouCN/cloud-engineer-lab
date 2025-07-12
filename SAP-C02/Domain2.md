# Content Domain 2: Design for New Solutions

## Task 2.1: Design a deployment strategy to meet business requirements

### Infrastructure as Code (IaC)

Infrastructure as Code lets you model and provision AWS environments from version-controlled templates instead of clicking through the console. On the SAP-C02 exam, AWS CloudFormation is the canonical IaC engine; every higher-level tool (CDK, SAM, Amplify) ultimately compiles down to CloudFormation.

**Typical use cases:**

- **Product / Business stakeholders:** IaC keeps the platform elastically scalable to the forecast load and SLA while capping spend. e.g. A flash-sale launch on Black Friday auto-scales from 50 to 200 EC2 instances via a predefined CloudFormation parameter set, yet stays within a Savings-Plans budget ceiling.
- **Application development team:** IaC delivers the required AWS resources with consistent naming and dependency order, guaranteeing environment parity. e.g. A CDK stack rebuilds dev, staging, and prod microservice clusters nightly, so a bug fixed in staging is promoted to prod on identical infrastructure.
- **Security / Compliance team:** IaC embeds encryption, audit trails, and least-privilege policies directly into templates, achieving “configure once, stay compliant.” e.g. Every new S3 bucket comes from a baseline StackSet that enforces KMS encryption, CloudTrail logging, and an AWS Config rule that blocks public access.
- **Platform / Operations team:** IaC bakes monitoring, alerting, and self-healing into the stack, shifting ops from manual firefighting to template-level governance. e.g. Each Auto Scaling group is deployed with CloudWatch alarms and an SSM automation document that replaces unhealthy instances without pager duty intervention.
- **Finance / FinOps:** IaC enforces tagging, budget alarms, and purchase-option choices at deployment time for instant cost visibility and optimization. e.g. Stack creation is blocked by a service control policy if mandatory CostCenter tags are missing; an AWS Budget with SNS/Slack alerts triggers when forecasted monthly spend exceeds 90 percent.

**key points:**

- Change Sets – Create a change set to see adds/modifies/deletes before you press Update Stack. Look for wording such as “must understand the impact before deployment.”
- Drift Detection – Run detect-stack-drift to verify the stack still matches the template; exam stems often say “ensure no one changed security-group rules manually.”
- StackSets – Single operation to push a template to 200 accounts / multiple Regions; supports automatic rollout to new Org accounts.
- Delegated Administrator – You can register a member account as the StackSets delegated admin so the management account doesn’t need day-to-day stack access.
- CDK v2 – Mention only if the question says “developers want to write IaC in Python/TypeScript.” CDK synthesizes to CloudFormation; all the features above (change sets, drift, StackSets) still apply.

Sample exam question (single-select):
Q: A company with 200 AWS accounts in AWS Organizations needs to deploy a standardized CloudTrail and GuardDuty baseline to every current and future account. The security team must own the template in a dedicated sec-ops account without using the management account for day-to-day operations. Which solution meets these requirements with the LEAST operational overhead?
A: C. Register sec-ops as the delegated administrator for CloudFormation StackSets with service-managed permissions and enable automatic deployment to the organization.
Correct answer: C – StackSets with delegated admin provides one-click fan-out and automatic rollout to new Org accounts, satisfying both governance and scalability requirements.

**Note:**
DevOps / SRE engineers translate the combined functional and non-functional requirements of product, development, security, operations, and finance teams into AWS-aligned architectural best practices. They then express this target architecture as Infrastructure as Code—most often CloudFormation or higher-level tools such as CDK, SAM, or Terraform—producing version-controlled templates that AWS orchestration services can automatically validate, deploy, audit, drift-check, and roll back. This workflow delivers environment consistency, rapid and repeatable releases, enforced governance, and a single source of truth for the entire cloud estate.

### CI/CD Pipeline

AWS’s native CI/CD toolchain—CodeCommit (source control) ➜ CodeBuild (build/test) ➜ CodeDeploy (deployment) ➜ CodePipeline (orchestration)—provides an end-to-end, fully managed release pipeline. CodePipeline supports cross-account stages and modern OIDC-based connections (via AWS CodeStar Connections) so you can fetch source from GitHub or Bitbucket without storing long-lived secrets. When the scenario calls for a single SaaS portal that unifies code, issues, environments, and blueprints, choose Amazon CodeCatalyst.

#### Main workflow

| Pipeline Stage                                  | Why this stage exists (plain-English purpose)            | What the DevOps / SRE actually does                                                                                                        | Key AWS services / tools<br><sub>☆ = we’ll deep-dive later</sub> |
| ----------------------------------------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- |
| **0. Code Review** _(pre-pipeline)_             | Keep un-reviewed code out of the main branch             | Enable protected branches and pull-request rules                                                                                           | GitHub / CodeCommit                                              |
| **1. Source**                                   | Detect a new commit and pull the code                    | Set up an **OIDC “secret-less” connection** to the repo; choose the trigger branch                                                         | CodePipeline ☆ + CodeStar Connections ☆                          |
| **2. Build**                                    | Compile, run unit tests, build a Docker image or package | Write `buildspec.yml` (e.g. `mvn test package && docker build/push`) and choose the build container image                                  | CodeBuild ☆ + ECR ☆                                              |
| **3. Static / Security Scan** _(optional gate)_ | Fail fast on vulnerable libs or bad code quality         | Plug scanners (SonarQube, CodeGuru Security, Snyk) into the build; set “break-the-build” thresholds                                        | CodeBuild + external scanners                                    |
| **4. Integration Test**                         | Spin up a short-lived test stack and hit real APIs       | Use CDK/CloudFormation to create a temp environment, run tests, auto-destroy                                                               | CodeBuild + CDK                                                  |
| **5. Package & Artifact**                       | Store deployable output in a shared location             | Tag artifacts (image, ZIP, JAR) and push to **ECR or S3** with commit SHA                                                                  | S3 artifact bucket ☆ / ECR ☆                                     |
| **6. Manual Approval** _(optional)_             | Meet change-management or segregation-of-duty rules      | Add an _Approval_ action; approver clicks “Approve” in email / Slack to continue                                                           | CodePipeline                                                     |
| **7. Deploy**                                   | Roll out the new version to the target stack             | Pick the right _driver_:<br>• ECS ⇒ CodeDeploy Blue/Green<br>• EC2 ⇒ CodeDeploy in-place/Blue-Green<br>• Lambda ⇒ CodeDeploy Canary/Linear | CodeDeploy ☆ + CloudFormation                                    |
| **8. Auto-verify & Rollback**                   | Confirm health and auto-revert on failure                | Attach CloudWatch alarms for 5xx, latency, task health; configure “automatic rollback on alarm”                                            | CodeDeploy + CloudWatch ☆                                        |
| **9. Observability & Alerts**                   | Centralise logs/metrics and notify humans                | Ship build/deploy/service logs to CloudWatch; wire EventBridge → SNS/Slack alerts                                                          | CloudWatch ☆ / SNS / EventBridge                                 |
| **10. Cross-account / Multi-env**               | Keep build and production accounts isolated              | Create an IAM _deploy role_ in prod; let the pipeline **AssumeRole**; share artifact bucket/KMS key                                        | IAM ☆ + S3 + CodePipeline                                        |
| **11. Compliance & Signing** _(optional)_       | Satisfy security auditors                                | Add `cfn-nag`/CFN Guard checks; enable CodeSigning for Lambda/ECR; archive reports                                                         | CodeSigning / Config / CloudTrail                                |

**key points:**

- **Default chain:** CodeCommit → CodeBuild → CodeDeploy (ECS blue/green) → CodePipeline. Look for wording such as “build Java, test, blue/green deploy with automatic rollback.”
- **Cross-account deployments:** CodePipeline can assume roles in target accounts; remember to add an artifact bucket in the target Region.
- **OIDC/CodeStar Connections:** Use OIDC to fetch from GitHub/Bitbucket without long-lived credentials. “Secrets-free access” is a clue.
- **Manual approvals & stage gates:** Insert an Approval action before prod to satisfy change-management requirements.
- **CodeDeploy deployment types:** Blue/green (ECS, Lambda, ASG) vs in-place (EC2/On-Prem); automatic rollback triggers on CloudWatch alarms or deployment failure.
- **CodeCatalyst pick:** When the stem says “single SaaS service for code, infra, tickets, workflows” choose CodeCatalyst—it wraps source repos, workflows, Dev Environments, and issue tracking in one console.

**Sample exam question (single-select):**
Q: A retail company wants to let developers push code to GitHub, run unit tests, and deploy a blue/green update to an Amazon ECS service in a separate production account. The solution must avoid storing long-lived Git credentials and must automatically roll back if the new task set fails its health checks. Which solution meets these requirements with the LEAST operational overhead?

- B. Configure CodePipeline in the dev account. Add a CodeStar GitHub connection as the source, a CodeBuild test stage, and a CodeDeploy blue/green ECS action that assumes an IAM role in the prod account for deployment and rollback.

A: Correct answer: B — This option chains the four Code\* services, uses OIDC-based CodeStar Connections for secrets-less GitHub access, and leverages CodeDeploy blue/green for automatic rollback while supporting cross-account deployment via assumed roles.

### Change Management & Approvals

AWS Systems Manager Change Manager provides built-in change templates with up to five approval levels, sequential or pooled, and executes only the Automation runbook associated with an approved request. All API calls are logged automatically to AWS CloudTrail, satisfying central-audit requirements. For “self-service but guard-railed” changes, combine Change Manager with AWS CloudFormation Change Sets so engineers can preview exactly what will be deployed while Change Manager enforces policy and approvals.

**Application Scenarios**

- Two-stage approval before production: A production stack update must pass team-lead approval and then ops-manager approval; the Change Manager template specifies two sequential approval levels and triggers the runbook only after both levels sign off.
- Central audit trail: Security needs every change logged; because Change Manager writes all actions to CloudTrail, no extra logging setup is required.
- Self-service with guardrails: Developers submit their own CloudFormation Change Sets, preview the diff, and route the change through Change Manager, which checks change windows and requires at least one approver before execution.

**Key Points**

- Multi-level approvals → Change Manager. Up to five approval stages; IAM users, groups, or roles can be approvers.
- Automatic audit logging → CloudTrail integration. No extra configuration needed; every approval, rejection, and runbook invocation is logged.
- Runbook enforcement. Only the Automation runbook referenced by the approved change request can run, preventing drift.
- Guard-railed self-service. Pair Change Manager with CloudFormation Change Sets to let engineers preview and request changes while still requiring policy-based approval.

**Exam Sample Question**
Q: A company must enforce a two-step approval process before any production stack changes and keep a centralized audit trail of all actions. Which AWS solution meets these requirements with the least additional configuration?
A: Use AWS Systems Manager Change Manager with a template that defines two approval levels and runs an Automation runbook; CloudTrail captures the complete audit trail automatically.

**Note:**

**Where Change Manager Applies:** It governs infrastructure-level changes—parameter tweaks, ASG policies, RDS sizing, IAM/SCP updates, CloudFormation stack alterations—especially in production or other regulated environments. It enforces up to five approval stages and logs every action to CloudTrail.

**High-Frequency Changes Bypass It:** Routine code-level releases travel through CI/CD pipelines (dozens to hundreds of deployments per day in mature SaaS teams, or several per week in most B2B apps). These rely on automated tests, canary/blue-green rollouts, and fast rollback—no manual approval required.

**When Manual Approval Is Mandatory:** Any update that touches sensitive data, security boundaries, compliance scope, or has major cost impact must be funneled through Change Manager (or an equivalent CAB flow) so human approvers validate the Automation runbook before execution.

“Two-stage approval with central audit” → choose Systems Manager Change Manager; “self-service but guard-railed” → Change Manager + CloudFormation Change Sets.

### AWS Configuration Management

AWS Systems Manager supplies a full configuration-management toolbox: State Manager enforces the desired OS or resource state; Patch Manager automates security-patch SLAs; Parameter Store and Secrets Manager inject versioned parameters and secrets into build or deployment pipelines; Run Command delivers ad-hoc fixes without exposing SSH ports. These sub-services share a unified audit trail in CloudTrail and can target entire Organizations or individual instances.

**Application Scenarios**

- Desired-state enforcement: Ops defines an association in State Manager that ensures prod EC2 instances always run the approved CIS-hardened AMI and correct security-group rules.
- Patch compliance: Security mandates all Linux nodes must remediate critical CVEs within 48 hours; a Patch Manager schedule applies the latest patches and reports compliance across every account.
- Pipeline parameter injection: A CodePipeline build pulls database endpoints and API keys at runtime from Parameter Store / Secrets Manager, removing hard-coded values and allowing safe version rollbacks.
- No-SSH operations: An engineer needs to restart a misbehaving service on dozens of instances; they invoke Run Command with a runbook, fixing the issue without opening port 22.

**Key Points**

- “Patch, CVE SLA” → Patch Manager (central schedules, compliance reports).
- “Desired state or baseline” → State Manager (associations + automatic drift remediation).
- \*\*“Inject configs/secrets into pipeline” → Parameter Store (plain or SecureString) or Secrets Manager (rotation support).
- “No SSH, run one-off command” → Run Command (IAM-controlled, CloudTrail-logged).
- Parameter vs. Secret choice: Parameter Store suits general configs; Secrets Manager is preferred for credential rotation or encrypted secrets.

**Exam Sample Question**
Q: A company must ensure that critical security patches are applied to all EC2 instances within 24 hours of release, and operators must never SSH into the servers. Which AWS service combination meets these requirements?
A: Use AWS Systems Manager Patch Manager to schedule automatic patching and Run Command for any ad-hoc remediation without opening SSH access.

**Note:**

**State Manager** — continuously enforces baseline OS configuration (e.g., guarantees CloudWatch Agent is running and root SSH is disabled on every EC2); **Patch Manager** — schedules and installs critical CVE patches for Amazon Linux, RHEL, Windows within a controlled maintenance window; **Parameter Store** — centrally stores versioned settings such as /prod/api/endpoint, injecting them into Lambda, ECS or CodeBuild at deploy time; **Secrets Manager** — protects and auto-rotates sensitive credentials like RDS master passwords or third-party API tokens under KMS encryption; **Run Command** — executes ad-hoc commands (e.g., systemctl restart nginx) across selected instances without opening SSH, with full IAM control and CloudTrail auditing.
