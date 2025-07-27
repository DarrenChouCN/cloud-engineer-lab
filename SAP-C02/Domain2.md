# Content Domain 2: Design for New Solutions

## Task 2.1: Design a deployment strategy to meet business requirements

### 1. Application and Upgrade Path

#### Infrastructure as Code (IaC)

Model and provision AWS environments from version‑controlled templates instead of clicking in the console. For SAP-C02, CloudFormation is the canonical engine (CDK/SAM/Amplify synthesize to it). IaC gives every team a single, auditable source of truth and a repeatable upgrade path.

- **AWS CloudFormation / CDK / SAM / Amplify:** declarative or higher-level IaC tools that compile to CloudFormation; used to keep dev/stage/prod identical, embed security/cost guardrails, and scale elastically for business events;
- **Change Sets:** pre‑deployment diffs that show add/modify/delete actions so stakeholders “understand the impact before deployment”; commonly inserted into change‑management workflows for approvals;
- **Drift Detection:** verifies deployed resources still match the template, catching manual edits (e.g., someone changed a security group) to maintain compliance;
- **StackSets (service-managed permissions) + Delegated Administrator:** one operation to fan out a baseline (CloudTrail, GuardDuty, Config) to hundreds of accounts/Regions and auto‑deploy to future Org accounts, while letting a sec‑ops account, not the management account, own operations;
- **Parameters / Mappings / Outputs:** template primitives to inject environment-specific values, reuse logic, and chain stacks cleanly;
- **CloudFormation Guard / cfn-nag:** policy-as-code and lint tools that enforce encryption, tagging, least privilege before a template is allowed into prod;
- **Stakeholder Lenses (Product/Dev/Security/Ops/FinOps):** IaC enforces cost tags and budgets (FinOps), guarantees naming/order parity (Dev), bakes KMS/CloudTrail/Config rules (Security), auto-wires alarms and SSM runbooks (Ops), and parameterizes scale to hit SLAs without overspend (Product);

**Environment Consistency and Upgrade Path**

Define every environment in CloudFormation (or CDK) and parameterize size/AZ count; use **Change Sets** whenever the stem says “must understand impact” or “preview before update.”

**Compliance, Audit, and Drift Control**

Schedule **Drift Detection** or trigger it in pipelines when stems say “ensure no manual change”; enforce template policies with **CloudFormation Guard/cfn-nag**.

**Org-Wide Rollout and Governance**

For “deploy a baseline to all current and future Org accounts” choose **StackSets (service-managed) with a delegated admin** account—this signals least overhead and automatic propagation.

**Developer Ergonomics vs Central Control**

Let developers author IaC in TypeScript/Python via **CDK**, but keep governance: synthesize to CloudFormation, review Change Sets, and gate prod with approvals.

_(Exam clue mapping inside design bullets: “preview impact” → Change Sets; “no manual SG change” → Drift Detection; “all Org accounts, future ones too” → StackSets + delegated admin; “devs want TypeScript IaC” → CDK.)_

Q1: A company with 200 AWS accounts must deploy a standardized CloudTrail and GuardDuty baseline to every current and future account. The security team wants to manage the template from a dedicated sec-ops account, not the management account. What is the least-operational-overhead solution?  
A1: Register the sec-ops account as the delegated administrator for CloudFormation StackSets (service-managed permissions) and enable automatic deployment to the organization.

Q2: Security must ensure no one manually alters security groups after deployment. Which IaC feature enforces this control and detects drift?  
A2: Run CloudFormation Drift Detection on the stack and fail the pipeline if drift is found.

Q3: Developers want to write IaC in TypeScript but the security team requires Change Set reviews before prod updates. What approach satisfies both?  
A3: Use AWS CDK to author templates, synthesize to CloudFormation, and require Change Sets for production stack updates.

Q4: A platform team needs to enforce encryption, tagging, and least privilege in every template before deployment. Which tool should be integrated into the CI pipeline?  
A4: CloudFormation Guard (or cfn-nag) to validate templates against policy rules.

Q5: New AWS accounts are added to the organization every month; a logging baseline (CloudTrail, Config) must auto-deploy to each without manual steps. How do you implement this?  
A5: Configure CloudFormation StackSets with service-managed permissions and a delegated admin to automatically deploy to new Org accounts.

Q6: During a production stack update, stakeholders must preview the exact resource changes before execution. What should you do?  
A6: Create and review a CloudFormation Change Set, then execute it after approval.

**Note**

IaC is not just “use CloudFormation”: it is the control plane for consistency, governance, and repeatability. CloudFormation (or CDK → CloudFormation) provides verifiable templates, impact previews (Change Sets), drift audits, and org-wide rollouts (StackSets). Embedding tagging, encryption, alarms, and budgets in templates ensures compliance and cost control are **designed in**, not bolted on. When questions emphasize impact analysis, compliance drift, or multi-account scale, prefer Change Sets, Drift Detection, and StackSets respectively. CDK is an authoring convenience—not a different control plane—so the same governance mechanisms still apply.

#### Change Management and Approvals

Control how infrastructure changes are requested, reviewed, executed, and audited. AWS Systems Manager Change Manager supplies multi‑level approval workflows and ties each approved request to a specific Automation runbook, while CloudTrail records every action. For guard‑railed self‑service, pair Change Manager with CloudFormation Change Sets so engineers preview diffs but cannot bypass policy.

- **AWS Systems Manager Change Manager:** built‑in change templates with up to five sequential or pooled approval levels; executes only the referenced Automation runbook;
- **Automation Runbook (SSM Automation):** the only code path Change Manager will run after approval, ensuring the deployed change matches what was reviewed;
- **CloudTrail Audit Logging:** automatic logging of submissions, approvals, rejections, and executions for centralized compliance records;
- **CloudFormation Change Sets:** pre‑deployment diffs that engineers submit for review; Change Manager enforces approvals and timing while Change Sets provide impact visibility;
- **Approval Actors (IAM users/roles/groups):** approvers defined in the template; integrates with change windows and business calendars;
- **Self‑service with Guardrails:** developers initiate their own requests but cannot execute without passing policy checks and approvals;
- **EventBridge / SNS Notifications (optional):** notify owners when a change enters approval or execution states;

**Multi‑Level Governance and Auditability**

Define up to five approval stages in Change Manager when stems mention “two-step approval,” “segregation of duties,” or “CAB process.” CloudTrail provides the immutable audit trail without extra setup.

**Runbook Enforcement and Drift Prevention**

Bind each approved request to a single Automation runbook so only that code path runs, preventing ad‑hoc scripts or manual console edits from slipping through.

**Guard‑railed Self‑Service**

Combine Change Manager with CloudFormation Change Sets: engineers submit a Change Set (impact preview), Change Manager verifies tags, change windows, and approvals, then executes the runbook to apply the stack update.

**Fast Path vs Manual Path**

Routine, high‑frequency code deployments stay in CI/CD (no human gates, rely on tests and auto‑rollback). Manual approval is reserved for changes that touch security boundaries, sensitive data, or major cost/infra shifts.

_(Exam clue alignment: “two-step approval with central audit” → Change Manager; “must preview stack changes” → Change Sets; “only approved workflow may run” → Automation runbook binding; “developers self-service but under policy” → Change Manager + Change Sets.)_

Q1: A company must enforce a two-step approval process before any production stack change and keep a centralized audit trail. Which AWS solution adds the least configuration?  
A1: AWS Systems Manager Change Manager with a template defining two approval levels and an Automation runbook; CloudTrail records the full audit trail.

Q2: Security requires that only the exact, pre-approved automation can run during a change, and any other commands must be blocked. What should you implement?  
A2: Use Change Manager and tie the request to a specific SSM Automation runbook so only that runbook executes after approval.

Q3: Developers need to submit CloudFormation updates themselves but must follow change windows and obtain at least one approver before execution. How do you meet this?  
A3: Have developers create CloudFormation Change Sets and route them through Change Manager, which enforces approval and scheduling policies.

**Note**

Change Manager governs infrastructure-level or high-risk updates—parameter tweaks, Auto Scaling policies, RDS sizing, IAM/SCP changes, CloudFormation stack updates—especially in regulated or production contexts. It supplies structured approvals (up to five stages), automatic CloudTrail logging, and strict runbook enforcement. High-frequency code releases stay in CI/CD pipelines (blue/green, canary, rolling) without manual gates; manual approval is reserved for sensitive, compliance-impacting, or high-cost changes. When stems emphasize multi-step approval, centralized audit, or controlled self-service, choose Change Manager (often in combination with Change Sets).

#### AWS Configuration Management

Use AWS Systems Manager to define, enforce, patch, and operate your fleet without manual SSH. State Manager keeps resources at a desired baseline, Patch Manager meets CVE SLAs, Parameter Store/Secrets Manager inject configuration safely, and Run Command executes ad‑hoc fixes—all auditable in CloudTrail and scalable across entire Organizations.

- **State Manager:** enforces desired state (approved AMI, SG rules, agents running); associations auto-remediate drift;
- **Patch Manager:** schedules and applies critical/security patches within SLA windows, reporting compliance across accounts;
- **Run Command:** executes ad‑hoc commands on many instances without opening SSH, controlled by IAM and logged in CloudTrail;
- **Parameter Store (Standard / SecureString):** versioned configuration values for pipelines and apps; good for general configs without rotation needs;
- **Secrets Manager:** encrypted secrets with automatic rotation (e.g., RDS passwords, third‑party API keys); integrates with Lambda/ECS/CodeBuild;
- **Organization-wide Targeting:** most SSM features (Patch/State/Run Command) can target tags, resource groups, or entire AWS Organizations;
- **Central Audit Trail (CloudTrail):** every SSM action—approve, run, patch—is automatically logged for compliance;

**Baseline Enforcement and Drift Remediation**

“Desired state or baseline” stems → **State Manager**. Define associations to keep CIS‑hardened AMIs, CloudWatch Agent, or SG rules correct; non‑compliance triggers auto-fix or alerts.

**Patch Compliance and CVE SLAs**

“Patch within 24/48 hours” or “CVE SLA” → **Patch Manager** with maintenance windows and compliance reports. Use tags to segment prod vs dev patch policies.

**Secure Config/Secret Injection into Pipelines**

“Inject configs/secrets into pipeline” → **Parameter Store** (plain/SecureString) or **Secrets Manager** (rotation). Retrieve at build/deploy time to avoid hard‑coding values.

**No-SSH, Fleet-Wide Operations**

“No SSH, run one-off command” → **Run Command**. IAM policies limit who can run which documents; CloudTrail logs execution.

**Exam Clue Mapping (embedded above):**

Patch/CVE SLA → Patch Manager; desired state → State Manager; pipeline configs → Parameter Store/Secrets Manager; no SSH → Run Command; rotation needed → Secrets Manager.

Q1: A company must ensure critical security patches are applied to all EC2 instances within 24 hours, and operators must never SSH. Which services meet the requirement?  
A1: **Patch Manager** for scheduled patching and **Run Command** for ad‑hoc remediation without SSH.

Q2: A CodePipeline build needs DB endpoints and API keys at runtime without committing them to source. Which services should supply these values?  
A2: **Parameter Store** for general configs and **Secrets Manager** for credentials requiring encryption and rotation.

Q3: Security insists that every production EC2 instance continuously runs the CloudWatch Agent and blocks root SSH login. How do you enforce this?  
A3: Create a **State Manager association** that applies and verifies the required configuration, with auto-remediation on drift.

**Note**  
Systems Manager centralizes configuration and operations: State Manager for continuous compliance, Patch Manager for SLA-driven updates, Run Command for controlled ad‑hoc fixes, and Parameter Store/Secrets Manager for secure, versioned runtime data. Prefer Patch Manager over custom scripts for CVE deadlines; choose Secrets Manager when rotation or secret lifecycle matters. Avoid SSH wherever possible—Run Command and Automation documents provide audited, IAM-governed execution. When exam stems stress “no SSH,” “patch within X hours,” “inject configs securely,” or “maintain a baseline,” default to these SSM capabilities.

### 2. Deployment Strategy and Rollback

### CI/CD Pipeline

Building, testing, and releasing code on AWS with a managed toolchain that detects commits, packages artifacts, enforces quality gates, deploys across isolated accounts, and rolls back automatically when health checks fail—ideal for teams wanting repeatable releases, zero long‑lived Git secrets, and minimal ops overhead.

- **CodePipeline:** the managed workflow engine that links source, build, test, approval, and deploy stages to automate releases
- **CodeStar Connections (OIDC):** a secret‑less OAuth/OIDC link to GitHub/Bitbucket so pipelines can pull code without storing credentials
- **CodeBuild:** a fully managed build/test runner driven by `buildspec.yml`, used to compile code, run unit/integration tests, or execute security scans
- **CodeDeploy:** the deployment orchestrator for EC2/On‑Prem (in‑place/blue/green), ECS (blue/green task sets), and Lambda (canary/linear) with auto‑rollback on alarms
- **Artifact Bucket / ECR:** S3 or Elastic Container Registry locations that store versioned build outputs (ZIP/JAR/Docker images) tagged with commit SHAs
- **Manual Approval Action:** a human gate inside CodePipeline to satisfy change‑management or segregation‑of‑duties requirements
- **AssumeRole (Cross‑Account Deploy):** the pattern where a pipeline in one account assumes an IAM role in another to deploy while keeping prod isolated
- **Security / Static Scan Step:** an optional CodeBuild phase running tools like SonarQube, CodeGuru Security, or Snyk to fail fast on vulnerabilities or poor code quality
- **Ephemeral Test Environment (CDK/CloudFormation):** a temporary stack spun up for integration tests and torn down afterward to validate real APIs without leaving residues
- **Compliance & Signing (cfn‑nag, CFN Guard, CodeSigning):** checks and artifact signing steps that prove to auditors the templates and binaries are compliant and untampered
- **Observability Hooks (CloudWatch, EventBridge, SNS):** log/metric collection and alerting for pipeline or deployment failures to notify teams promptly
- **Amazon CodeCatalyst:** an all‑in‑one SaaS portal that bundles repos, issues, blueprints, and workflows when a single unified service is preferred over assembling Code\* pieces

**Secrets‑free Git access ↔ CodeStar Connections (OIDC)**  
When the stem says “no stored Git credentials” or “avoid long‑lived Git tokens”, choose an OIDC-based CodeStar Connection as the pipeline source.

**Cross‑account prod deployment ↔ AssumeRole + shared artifacts/KMS**  
“Deploy to a separate production account” signals a pipeline that assumes an IAM role in the target account and reads artifacts from a shared S3/ECR/KMS setup.

**Automatic rollback on failed health checks ↔ CodeDeploy blue/green + CloudWatch alarms**  
“Rollback automatically if the new version is unhealthy” maps to CodeDeploy’s blue/green (or canary/linear) strategy wired to CloudWatch alarm triggers.

**Least operational overhead ↔ Managed Code\* services over self‑hosted tools**  
Phrases like “minimize operations/maintenance” or “fully managed” point to CodePipeline/CodeBuild/CodeDeploy instead of Jenkins or custom scripts.

**Single SaaS portal for code + tickets + workflows ↔ Amazon CodeCatalyst**  
If the question stresses “one service for repos, issues, blueprints, and pipelines,” the answer is CodeCatalyst rather than assembling individual Code\* services.

**Fail the build on vulnerabilities ↔ Security scan step in CodeBuild**  
“Break the build on security or code quality thresholds” indicates inserting a scanner stage (SonarQube, CodeGuru Security, Snyk) in CodeBuild that fails on violations.

**Change‑management approval before production ↔ Manual Approval action**  
“Require human approval/segregation of duties before prod” corresponds to adding a Manual Approval action in CodePipeline.

**Test against real resources without leftovers ↔ Ephemeral env via CDK/CloudFormation**  
“Run integration tests in a temporary environment and tear it down” implies spinning up a short‑lived stack with CDK/CloudFormation inside the pipeline.

Q1: Developers push to GitHub, must run tests, deploy blue/green to ECS in a separate prod account, avoid long‑lived secrets, and auto‑rollback on failure—what’s the least‑ops solution?  
A1: Use CodePipeline with a CodeStar GitHub connection, CodeBuild for tests, and CodeDeploy blue/green assuming a prod IAM role for deploy and rollback.

Q2: A company wants one SaaS portal to manage code, tickets, blueprints, and workflows without stitching services together—what should they choose?  
A2: Amazon CodeCatalyst because it unifies these functions in a single managed console.

Q3: You need to run thousands of unit tests in parallel to cut build time, but still produce a single report and artifact—what should you configure?  
A3: Use CodeBuild **batch builds** to parallelize tests across containers and aggregate results into one artifact.

Q4: A pipeline in Account A must deploy to ECS in Account B and use an encrypted artifact bucket—how do you set this up?  
A4: Use **AssumeRole** from Account A into Account B, and grant that role access to the shared S3 artifact bucket and KMS key.

Q5: You must push updates to hundreds of accounts/Regions whenever a CloudFormation template changes—what’s the CI/CD pattern?  
A5: Use **CodePipeline with StackSets** and a delegated admin to propagate updates automatically to target accounts.

Q6: The requirement says “rollback automatically if health checks fail during ECS deployment”—which combo fits?  
A6: Use **CodeDeploy blue/green** for ECS with **CloudWatch alarms** configured for automatic rollback.

Q7: Security mandates “only trusted code can reach Lambda”—how do you enforce this in the pipeline?  
A7: Enable **AWS Signer** to sign Lambda packages and enforce signature validation during deployment.

Q8: Change management requires a human to approve before production, and unanswered requests must not block forever—what feature fits?  
A8: Use a **Manual Approval** action in CodePipeline, which fails after 7 days of no response.

Q9: The team wants pipeline notifications to Slack when any stage starts or fails without custom Lambda code—what’s the simplest?  
A9: Configure **CodePipeline notification rules** to send events to **SNS** or **EventBridge**, then integrate with Slack.

Q10: The stem says “no stored Git credentials; use GitHub as source”—what is the correct source action?  
A10: Use an **OIDC-based CodeStar Connection** for GitHub to avoid long-lived credentials.

Q11: An ECS service currently uses a CodeDeploy blue/green template; the team wants to migrate to the newer ECS blue/green action—what’s the recommended move?  
A11: Use **native ECS blue/green deployments in CodePipeline** and follow AWS’s migration guide for seamless switchover.

Q12: A junior engineer suggests using Jenkins on EC2 for “flexibility,” but the question highlights “least operational overhead”—what should you choose?  
A12: Choose the managed **CodePipeline/CodeBuild/CodeDeploy** stack to minimize maintenance and setup.

**workflow**

0. **Code Review (pre‑pipeline):** keep unreviewed code out of main branches and enforce protected branches, PR reviews, and status checks in GitHub or CodeCommit.

1. **Source:** detect a new commit and fetch code by creating an OIDC CodeStar Connection and setting branch/tag triggers in CodePipeline.

2. **Build:** compile, test, and package or build Docker images by defining commands in `buildspec.yml` and running them in a managed CodeBuild container.

3. **Static / Security Scan (optional):** fail fast on vulnerabilities or poor code quality by running scanners in a dedicated CodeBuild phase and breaking the build on thresholds.

4. **Integration Test:** validate real APIs in an ephemeral environment by creating a temporary stack with CDK/CloudFormation, executing tests, and tearing it down automatically.

5. **Package & Artifact Store:** persist deployable outputs by tagging them with the commit SHA and pushing to an S3 artifact bucket or ECR repository.

6. **Manual Approval (optional):** satisfy audit or SoD rules by inserting an Approval action that requires a human to continue the pipeline.

7. **Deploy:** roll out the new version using the appropriate driver—CodeDeploy for ECS/EC2/Lambda or CloudFormation for stack changes—matching the workload type.

8. **Auto‑verify & Rollback:** ensure health and revert failures by wiring CloudWatch alarms (5xx, latency, task health) to trigger CodeDeploy’s automatic rollback.

9. **Observability & Alerts:** centralize telemetry and notify teams by sending logs to CloudWatch Logs and routing pipeline/deploy events through EventBridge to SNS or Slack.

10. **Cross‑account / Multi‑environment:** isolate prod by letting the pipeline AssumeRole into target accounts and sharing artifact buckets and KMS keys across Regions if needed.

11. **Compliance & Signing (optional):** prove integrity and compliance by running cfn‑nag/CFN Guard checks, enabling CodeSigning for Lambda/ECR artifacts, and archiving reports.

**Note**
The default managed chain is CodeCommit → CodeBuild → CodeDeploy → CodePipeline, but real exams stress patterns like OIDC‑based GitHub integration, cross‑account AssumeRole deployments, manual approvals for governance, and CodeDeploy’s blue/green or canary strategies with CloudWatch‑driven rollback; when the prompt emphasizes an integrated SaaS for code and project management, pivot to CodeCatalyst, and always remember artifact storage (S3/ECR), observability, and compliance hooks are integral parts of a production‑grade pipeline.

### 3. Managed Service Adoption

### 4. Delegating Complex Tasks to AWS

## Task 2.4 - Design a strategy to meet reliability requirements

### 1. Highly Available Application Design

Building redundancy into every layer—compute, data, and networking—so the system keeps serving users even when an entire Availability Zone or Region experiences issues; ideal for customer‑facing workloads that demand near‑constant uptime such as e‑commerce sites, SaaS platforms, or critical internal tools, eliminating single points of failure and minimizing downtime.

- **Multi-AZ Deployments:** deploying services across multiple Availability Zones to achieve fault isolation and high availability;
- **Active-Active vs Active-Passive Topologies:** Active-Active means multiple nodes handle traffic simultaneously; Active-Passive means a primary node handles traffic while a standby node takes over upon failure;
- **Aurora Global Database:** Amazon Aurora feature that replicates data across regions with one primary region and multiple read-only secondary regions, enabling near real-time synchronization and disaster recovery;
- **S3 Cross-Region Replication:** automatically replicates S3 objects from one region’s bucket to another for cross-region redundancy;
- **ALB/NLB Cross-Zone Load Balancing:** distributes traffic evenly across targets in different Availability Zones to avoid overloading a single zone;
- **Auto Scaling Target Tracking:** automatically adjusts resource capacity based on predefined metrics (e.g., CPU utilization) to maintain desired performance levels;
- **RTO/RPO Targets:** RTO (Recovery Time Objective) is the maximum acceptable time to restore service after a failure; RPO (Recovery Point Objective) is the maximum acceptable duration of data loss in a disaster scenario;

**Availability Goal ↔ Resilience Scope**

- **99.99 % availability within a Region:** choose Multi‑AZ; deploying across multiple AZs isolates single‑AZ failure and lets AWS handle automatic failover
- **≥ 99.999 % availability or geographic isolation required:** choose Multi‑Region; cross‑Region replication and regional traffic routing keep service alive if an entire Region goes down

**RTO / RPO ↔ Data Replication Mechanism**

- **Sub‑minute RTO / RPO:** Aurora Global Database; asynchronous replication lag < 1 s with rapid primary failover
- **RTO < 1 h, RPO minutes:** Warm Standby; continuous replication and pre‑warmed core resources shorten recovery time
- **RTO hours, RPO hours:** Pilot‑Light or backup‑and‑restore; only minimal core components stay running, other services start on demand to save cost

**Budget Constraint ↔ Compute Topology**

- **Ample budget and need for horizontal scale:** Active‑Active; all Region/AZ nodes receive traffic concurrently, avoiding bottlenecks
- **Moderate budget and need quick switchover:** Active‑Passive; primary handles traffic, standby is hot and takes over automatically on failure
- **Limited budget and relaxed recovery time:** Cold Standby or data‑only backups; compute resources start manually or automatically after an incident to minimize daily spend

Q1: An application needs 99.99 % availability in one Region, RTO ≤ 15 min, RPO ≤ 15 min, and the budget allows a small amount of idle capacity
A1: Multi‑AZ + Warm Standby

Q2: A global e‑commerce platform must keep RTO ≈ 1 min and RPO ≈ 1 min during a Region‑wide disaster while maintaining read/write capability
A2: Aurora Global Database + Active‑Active multi‑Region deployment

### 2. Design for Failure

Engineering under the assumption that components will inevitably break by injecting faults, adding graceful retry logic, and isolating blast radius; suited to complex distributed systems where transient errors, network partitions, or cascading failures are common, ensuring the application degrades gracefully and recovers automatically without manual intervention.

- **Chaos Engineering (AWS Fault Injection Simulator):** deliberately injects faults into production‑like environments to confirm system resilience;
- **Retries with Back‑off and Jitter:** re‑attempts failed requests using exponential delays plus random jitter to prevent synchronized retries;
- **Idempotent Operations:** operations that can be repeated safely because multiple executions yield the same end state;
- **Circuit Breakers:** monitors call failures and opens to reject further calls until the downstream service recovers;
- **Bulkheads:** partitions resources so failure in one compartment does not cascade to others;
- **RDS/Aurora Automatic Failover:** promotes a standby database instance when the primary becomes unavailable, reducing recovery time;
- **ElastiCache Global Datastore:** replicates Redis data across Regions and can promote a secondary cluster during Regional failures;

**Failure Anticipation ↔ Chaos Testing**

Inject CPU, network, or AZ outages with AWS Fault Injection Simulator; validate alarms and recovery playbooks to surface hidden dependencies

**Transient Fault Handling ↔ Retry and Timeout Policy**

Use exponential back‑off with full jitter in retries; keep calls idempotent to prevent state corruption when duplicates occur

**Persistent Fault Handling ↔ Isolation and Failover**

Apply circuit breakers and bulkheads to localize impact; enable automatic database or cache failover so traffic routes to healthy replicas without manual action

Q1: A microservice occasionally receives 500 errors from an external payment API; the business must avoid duplicate charges and keep latency low
A1: Idempotent operations with exponential back‑off and jitter

Q2: A global retail site must verify that its multi‑tier architecture withstands an Availability‑Zone network black‑hole without manual intervention
A2: Chaos engineering using AWS Fault Injection Simulator plus Multi‑AZ automatic database failover and circuit breakers

### 3. Loosely Coupled Dependencies

Decoupling microservices and event producers through asynchronous messaging and event buses so each part can scale, deploy, or fail independently; perfect for microservice architectures, data pipelines, and bursty workloads, solving tight coupling problems that otherwise cause back‑pressure, lock‑step scaling, or cross‑service outages.

- **SNS fan‑out to SQS:** publishing a single message to an SNS topic that delivers copies to multiple SQS queues, enabling parallel processing;
- **FIFO vs Standard Queues:** FIFO queues preserve strict order and guarantee exactly‑once processing; Standard queues offer at‑least‑once delivery with best‑effort ordering but higher throughput;
- **Dead‑Letter Queues (DLQ):** secondary queues that store messages that could not be processed after the maximum retry count, isolating poison messages for later analysis;
- **AWS Step Functions Orchestration:** serverless workflow service that coordinates distributed components with retries, parallel branches, and timeout handling;
- **EventBridge Buses:** event router that receives, filters, and delivers events to multiple targets across AWS accounts and services without tight coupling;
- **Lambda Pollers:** AWS‑managed pollers that automatically retrieve messages from SQS and invoke Lambda functions, scaling concurrency with queue depth;

**Ordering / Exactly‑Once ↔ Queue Type**

Use FIFO SQS with content‑based deduplication for strict order and exactly‑once delivery; employ message groups if parallelism with ordered subsets is needed

**Error Isolation ↔ Dead‑Letter Handling**

Attach DLQs to SQS, Lambda, or Step Functions to divert poison messages after retry limits; monitor DLQ size with CloudWatch alarms to trigger remediation workflows

**Independent Scaling ↔ Event‑Driven Fan‑out**

Combine SNS fan‑out or EventBridge buses with multiple SQS queues so each microservice scales independently; Lambda pollers auto‑scale with incoming messages, and Step Functions orchestrate long‑running or multi‑step transactions without blocking upstream producers

Q1: A workload must process orders in the exact sequence received and ensure each order is handled only once
A1: Use an SQS FIFO queue with content‑based deduplication

Q2: A payment microservice occasionally receives malformed events that break JSON parsing and block the queue; the team must isolate these bad messages without affecting healthy traffic
A2: Configure an SQS dead‑letter queue and route messages there after the maximum retry attempts

### 4. Operate & Maintain Highly Available Systems

Ensuring a live system stays healthy after go‑live by automating failover checks, managing seamless rollouts, and scheduling maintenance so updates never violate uptime targets; critical for production workloads that must evolve continuously—patches, schema changes, traffic shifts—without introducing new single points of failure or extended outages.

- **Multi‑AZ Failover Health Checks:** continuous probes that detect primary‑instance failure and trigger automatic promotion within the same Region;
- **Cross‑Region Replica Promotion Times:** measured duration to elevate a read replica in another Region to primary, used to validate RTO targets;
- **Aurora Failover Tiers:** priority levels that define which replica becomes the new writer during an Aurora cluster failover;
- **Auto Scaling Instance Refresh:** rolling replacement of EC2 instances in an Auto Scaling group with the latest AMI while preserving capacity;
- **Blue/Green and Canary Deployments:** traffic‑shifting strategies that direct a subset of users to new code to verify stability before full cutover;
- **Staggered Patch Windows:** offset maintenance windows across instances or AZs so only a fraction of the fleet is updated at any time;

**Fault Detection ↔ Health Check Hierarchy**

Use layered health checks—ELB target health, Auto Scaling EC2 status, database replication lag—to trigger Multi‑AZ or Aurora failovers quickly and avoid sending traffic to unhealthy nodes

**Zero‑Downtime Updates ↔ Progressive Deployment**

Combine blue/green or canary strategies with Auto Scaling instance refresh to roll out AMI or configuration changes without dropping connections; monitor key metrics and roll back if error rates rise

**Maintenance Continuity ↔ Staggered Windows & Replica Promotion**

Schedule staggered patch windows across AZs and Regions so at least one healthy replica or instance group is always online; validate cross‑Region promotion time to ensure it meets business RTO during planned or unplanned events

Q1: A production Aurora cluster must promote a standby writer in under 30 seconds when the primary fails; which configuration ensures this target is met?
A1: Assign the highest failover tier (tier 0) to the preferred replica and enable Aurora automated monitoring health checks

Q2: A company needs to roll out a security patch to hundreds of EC2 instances without affecting live traffic; which approach satisfies this requirement?
A2: Use Auto Scaling instance refresh with a blue/green deployment strategy and verify health checks before shifting 100 % traffic to the new instances

Q3: During maintenance, one Availability Zone must stay fully operational while the other is patched; how should the patch schedule be arranged?
A3: Apply staggered patch windows so each AZ is updated at a different time, ensuring continuous capacity across the Region

### 5. Managed Highly Available Services

Leveraging fully managed AWS offerings that embed high availability, replication, and fail‑in routing so you don’t have to build or operate clusters yourself; ideal when the goal is to meet strict replication‑lag or uptime targets with the lowest operational burden—letting AWS handle scaling, patching, and cross‑Region traffic steering while you focus on business logic.

**DynamoDB Global Tables:** multi‑Region, multi‑active NoSQL replication with single‑digit‑millisecond latency and ≤ 1 s cross‑Region lag;
**S3 Standard:** durable (11 nines) object storage automatically replicated across three AZs in one Region;
**EFS Standard:** regional NFS file system that stores data redundantly across multiple AZs and scales to petabytes without manual provisioning;
**Kinesis Enhanced Fan‑out:** dedicated throughput pipes (up to 2 MB/s per consumer) that eliminate consumer‑level throttling on data streams;
**Global Accelerator:** AnyCast edge network that directs users to the closest healthy AWS endpoint and instantaneously shifts traffic on failure;
**Elastic Load Balancing (ALB/NLB):** managed layer 7/4 load balancers with cross‑Zone failover and health checks—no self‑managed HA proxy layer required;

**Operational Simplicity ↔ Managed Option**

Replace self‑built clusters with DynamoDB Global Tables, S3 Standard, or EFS Standard to offload patching, scaling, and replication tasks to AWS

**Replication & Consistency ↔ Built‑in HA Features**

Use services whose default behavior meets RTO/RPO—e.g., DynamoDB global tables for sub‑second multi‑Region writes, ELB cross‑Zone routing for AZ resilience

**Global Performance ↔ Edge Routing & Stream Throughput**

Adopt Global Accelerator for low‑latency routing to the nearest healthy Region and Kinesis enhanced fan‑out to guarantee consistent consumer throughput without tuning shards

Q1: A gaming backend needs < 1 second cross‑Region data replication with minimal operational overhead; which service meets this requirement?
A1: DynamoDB Global Tables

Q2: A video analytics pipeline requires each consumer to read up to 2 MB/s from the same stream without throttling or shard rebalancing; which managed feature should be used?
A2: Kinesis Enhanced Fan‑out

### 6. DNS Routing Policies

Directing user traffic at the DNS layer with policy‑based decision logic—latency, geography, failover status, or traffic shifting—so clients reach the optimal endpoint without changing application code; ideal for global services that need low latency delivery, jurisdiction‑aware routing, disaster recovery cut‑over, or controlled blue/green rollouts while AWS Route 53 handles resolution and health checks.

- **Route 53 Simple Routing:** returns one record set for a domain, suitable for single‑endpoint workloads;
- **Weighted Routing:** splits traffic across multiple records using adjustable weights, supporting blue/green or canary releases;
- **Latency‑Based Routing:** routes each client to the Region with the lowest observed latency to that user’s DNS resolver;
- **Failover Routing:** designates primary and secondary records, automatically switching to the secondary when Route 53 health checks detect the primary is unhealthy;
- **Geolocation Routing:** directs users based on the country or continent of their originating IP address, useful for data sovereignty or localized content;
- **Geoproximity Routing:** uses Route 53 Traffic Flow to shift traffic toward or away from resources based on geographic distance and optional bias, handy for gradual Region migrations;
- **Health Checks:** automated probes (HTTP, HTTPS, TCP) that mark a record healthy or unhealthy for failover decisions;
- **Alias A Records:** special Route 53 records that map a DNS name to AWS resources (ELB, CloudFront, S3, etc.) without extra cost or DNS lookups;

**Latency Optimization ↔ Latency‑Based Routing**

Deploy identical endpoints in multiple Regions; Route 53 returns the IP of the Region with the lowest latency to each user, reducing round‑trip time without additional application logic

**Jurisdiction Compliance ↔ Geo‑Aware Policies**

Use Geolocation routing to keep EU traffic within EU data centers for GDPR compliance; apply Geoproximity with bias to gradually shift traffic from an old Region to a new one during migrations

**Disaster Recovery & Traffic Shifting ↔ Failover / Weighted**

Combine Failover routing with health checks to cut over from primary to secondary Region automatically during outages; apply Weighted routing (e.g., 90/10, 50/50) for blue/green deployments, increasing weight on the new version as it proves stable

Q1: A worldwide API must ensure each client hits the Region with the shortest network latency while falling back to another Region if its endpoint becomes unhealthy
A1: Use Latency‑Based routing for primary selection combined with Route 53 health checks and Failover routing for automatic Regional failover

Q2: A company needs to route Canadian users to a data center in Toronto for data residency, while the rest of the world continues to use the US Region
A2: Configure a Geolocation routing policy with a rule for the CA country code pointing to the Toronto endpoint and a default rule pointing to the US endpoint

## Task 2.5: Design a solution to meet performance objectives

### 1. Large‑Scale Access Patterns

Designing data and traffic flows so that high‑volume, uneven, or bursty workloads remain low‑latency and scalable; common in systems facing “hot keys,” spikes in writes, or globally distributed reads, where smart partitioning, buffering, and edge caching prevent throttling and keep performance predictable.

- **Partitioning / Sharding:** distributing data or traffic across keys or shards (e.g., DynamoDB partition keys, Kinesis shards) to spread load evenly;
- **Read / Write Separation:** offloading reads to Aurora reader endpoints or RDS read replicas so the writer is not overloaded;
- **Batching and Parallelism:** grouping events for efficient processing and using SQS, Kinesis, and Lambda concurrency to process in parallel;
- **CDN Edge Delivery (CloudFront):** caching static and dynamic content at global edge locations to minimize origin load and latency;
- **API Gateway Throttling / Caching:** enforcing rate limits per client and caching responses at the API edge layer to shield backends from bursts;

**Hot Key Mitigation ↔ Partition Strategy**

Choose high‑cardinality partition keys or add random suffixes/salt to spread “hot” traffic; pre‑split Kinesis shards or use on‑demand scaling to prevent shard hotspots

**Read Scalability ↔ Replicas and Edge Caches**

Add Aurora reader endpoints or RDS read replicas for heavy read workloads; push frequently accessed content to CloudFront to reduce round trips to the origin

**Burst Write Handling ↔ Streaming / Buffering Layer**

Insert SQS or Kinesis between producers and consumers to smooth write spikes; process in batches with Lambda or consumer fleets that scale with queue depth

**Latency & Backend Protection ↔ Throttling and Caching**

Apply API Gateway throttling to prevent client floods; enable API Gateway or CloudFront caching to return cached responses quickly and cut load on downstream services

Q1: A DynamoDB table experiences “hot key” access during flash sales, causing throttling; which approach solves the issue without major schema changes?
A1: Introduce a partition key sharding strategy (e.g., random suffixes) to distribute writes evenly across partitions

Q2: A read‑heavy reporting workload is overloading the primary RDS instance; how can you scale reads without affecting writes?
A2: Add RDS read replicas or use the Aurora reader endpoint to offload read traffic

Q3: A mobile game sends bursty telemetry data that overwhelms the backend; what should you implement to absorb and process these spikes efficiently?
A3: Use Kinesis (or SQS) as a buffering layer and process records in batches with Lambda concurrency scaling

### 2. Elastic Architecture Design

Designing systems that expand and contract capacity automatically to match demand, maintaining SLA targets without paying for idle resources; ideal for workloads with diurnal peaks, unpredictable bursts, or seasonal patterns where each component should scale on its own metrics rather than as a monolith.

- **EC2 Auto Scaling (target-tracking, step, scheduled):** automatically adjusts EC2 instance counts using metric targets, threshold steps, or time-based schedules;

- **DynamoDB On-Demand / Auto Scaling:** capacity modes that either scale transparently per request or adjust provisioned throughput based on traffic trends;

- **Lambda Reserved & Provisioned Concurrency:** controls to guarantee function concurrency or pre-warm execution environments to avoid cold starts;

- **ECS/EKS Cluster Auto Scaling:** automatically adds or removes container hosts (EC2 or Fargate capacity providers) in response to pending tasks or pod scheduling;

- **Application Auto Scaling (for Kinesis, EMR, etc.):** unified scaling service that applies scaling policies to non-EC2 resources such as stream shards or EMR task nodes;

**Demand Pattern ↔ Scaling Policy Type**

Use target-tracking to keep a steady metric (e.g., 60% CPU) for variable traffic; pick step scaling when you need discrete jumps at threshold breaks; rely on scheduled scaling for predictable spikes, such as daily batch loads

**Cost Efficiency ↔ Capacity Mode**

Prefer serverless or on-demand modes (Lambda, DynamoDB On-Demand) for unpredictable or spiky workloads; switch to provisioned capacity with auto scaling when you have steady baselines and want cost control with throttling guarantees

**Latency & Cold Starts ↔ Concurrency Controls**

Apply Lambda reserved or provisioned concurrency to guarantee consistent latency during bursts; pre-scale ECS tasks or keep minimum EC2 instances online if startup time would violate SLA

**Component Independence ↔ Scaling Boundaries**

Ensure each microservice or data pipeline scales on its own metrics; separate read/write scaling (e.g., Kinesis shard count vs consumer concurrency) so one bottleneck does not force global overprovisioning

Q1: A retail app has unpredictable spikes and must maintain 200 ms API latency without paying for idle servers overnight; which approach should you take?
A1: Use Lambda with provisioned concurrency for latency guarantees and DynamoDB On-Demand to handle bursty traffic without preprovisioning

Q2: A reporting job runs every weekday at 9 AM, doubling compute needs for one hour; how do you scale efficiently?
A2: Configure scheduled scaling on the EC2 Auto Scaling group (or EMR task nodes via Application Auto Scaling) to add capacity just before 9 AM and scale back after the job

Q3: A streaming pipeline must increase shard count when incoming records exceed current throughput, but other components should remain unaffected; what should you implement?
A3: Use Application Auto Scaling on Kinesis stream shards with a target-tracking policy so shard scaling is independent of downstream consumer scaling

### 3. Caching & Buffering Patterns

Using in-memory caches, edge caches, and message buffers to cut read/write latency and smooth burst traffic; ideal when hotspots or sudden spikes would overwhelm databases or downstream services, ensuring fast responses for frequently accessed data and controlled ingestion for high-volume writes.

- **ElastiCache (Redis / Memcached):** in-memory data store for sub-millisecond reads; Redis supports persistence and advanced data structures, Memcached is simple key-value with no persistence;
- **DynamoDB DAX:** fully managed in-memory cache for DynamoDB that accelerates read-heavy and hot-key workloads with microsecond latency;
- **CloudFront:** global CDN that caches static and dynamic content at edge locations to reduce origin load and latency;
- **API Gateway Caching:** response caching at the API edge to lower backend calls and improve request latency;
- **RDS / Aurora Read Replicas:** database replicas dedicated to read traffic, offloading reads from the primary and reducing contention;
- **SQS / Kinesis Buffers:** message queues and streaming services that absorb bursty writes and decouple producers from consumers;
- **SNS Fan-out to SQS:** publishes one message to SNS and delivers copies to multiple SQS queues so consumers can process independently;

**Read Latency Reduction ↔ In-Memory & Edge Caches**

Place ElastiCache (Redis/Memcached) close to application servers for sub-millisecond reads of hot objects; use CloudFront or API Gateway caching to return cached responses at the edge and reduce origin round trips

**DynamoDB Hot Key Relief ↔ DAX Layer**

Add DAX in front of DynamoDB tables to cache frequently accessed items, avoiding partition throttling and read capacity spikes without changing application logic significantly

**Read Scalability ↔ Database Replicas**

Use RDS/Aurora read replicas for heavy read workloads that aren’t a good fit for caching (e.g., complex queries); direct reporting or analytics reads to replicas to protect the primary

**Write Spike Absorption ↔ Message Buffers**

Introduce SQS or Kinesis between producers and consumers to smooth write peaks; consumers process in batches or scale concurrency based on queue depth to avoid throttling the database or downstream service

**Fan-out Decoupling ↔ SNS → SQS Pattern**

Use SNS to broadcast events to multiple SQS queues so each consumer scales and retries independently, preventing a slow consumer from blocking others

Q1: An app experiences read latency spikes on frequently accessed DynamoDB items during sales events; how do you reduce latency without redesigning the table?
A1: Add DynamoDB DAX to cache hot keys and serve microsecond reads

Q2: A media portal must serve global users with low latency for static assets and offload origin servers; what should you implement?
A2: Use CloudFront to cache static content at edge locations

Q3: A telemetry system receives bursty write traffic that overwhelms the database; how can you prevent throttling and maintain resiliency?
A3: Insert SQS or Kinesis as a buffering layer and process records in batches with scalable consumers

### 4. Purpose‑Built Service Selection

Choosing the right managed database, storage, and monitoring tool for a specific data access pattern—time‑series ingestion, graph traversal, full‑text search, ledger integrity—so performance, cost, and operational effort align with business needs; this avoids forcing one engine to do everything and reduces bottlenecks, while dedicated monitoring tools expose root causes quickly.

- **DynamoDB (key‑value):** NoSQL key‑value store with single‑digit‑millisecond latency and automatic scaling;
- **Aurora / RDS (relational):** managed relational databases (MySQL/PostgreSQL engines in Aurora, multiple engines in RDS) for transactional consistency and SQL queries;
- **Neptune (graph):** graph database optimized for highly connected data and traversal queries;
- **Timestream (time‑series):** serverless time‑series DB for IoT metrics and time‑ordered events with built‑in tiered storage;
- **QLDB (ledger):** immutable, cryptographically verifiable ledger database for audit trails;
- **OpenSearch (search/analytics):** distributed search engine for full‑text search, log analytics, and near‑real‑time visualization;
- **DocumentDB (document):** MongoDB‑compatible document store for JSON‑like semi‑structured data;
- **Keyspaces (wide‑column):** managed Apache Cassandra‑compatible service for wide‑column workloads;
- **S3 (object storage):** durable, scalable object store for unstructured data, backups, logs;
- **EBS gp3 / io2 (block storage):** high‑performance block volumes for EC2 instances; io2 offers high IOPS, gp3 balances cost and performance;
- **Instance Store:** ephemeral block storage physically attached to EC2 host, ultra‑fast but non‑persistent;
- **EFS (file storage):** regional, elastic NFS file system for shared POSIX access;
- **FSx families (Lustre / Windows / ONTAP / OpenZFS):** high‑performance or specialized file systems for HPC, Windows workloads, NetApp ONTAP compatibility, or ZFS features;
- **CloudWatch Metrics / Alarms:** time‑series metrics and automated alarms for threshold breaches;
- **AWS X‑Ray Tracing:** distributed tracing to identify latency hotspots in microservice calls;
- **CloudWatch Logs / RUM / Synthetics:** log aggregation, real user monitoring, and scripted canaries to detect front‑end or API performance issues;
- **Performance Insights for RDS:** visualizes database load and SQL bottlenecks to pinpoint slow queries;

**Access Pattern ↔ Engine Selection**

Pick the engine built for the query shape: time‑series → Timestream; graph traversal → Neptune; full‑text search → OpenSearch; ledger integrity → QLDB; key‑value at scale → DynamoDB; standard OLTP/SQL joins → Aurora/RDS

**Data Structure & Consistency ↔ Storage/DB Model**

Semi‑structured JSON → DocumentDB; wide‑column high throughput → Keyspaces; immutable audit logs → QLDB; strong relational integrity (transactions, joins) → Aurora/RDS

**Throughput / Latency Needs ↔ Storage Tier**

High IOPS block workloads → EBS io2; cost‑efficient block → gp3; ephemeral scratch space → Instance Store; shared POSIX file system → EFS or FSx families; object archival or static files → S3

**Bottleneck Visibility ↔ Monitoring & Tracing**

Use CloudWatch Metrics/Alarms for thresholds, Performance Insights to diagnose slow SQL, X‑Ray to trace end‑to‑end latency, and CloudWatch Logs/RUM/Synthetics to surface application or client‑side delays

Q1: An IoT platform ingests millions of timestamped sensor readings per minute and needs built‑in tiered storage with SQL‑like time filters  
A1: Amazon Timestream

Q2: A social network requires millisecond traversal of highly connected user relationships and recommendation graphs  
A2: Amazon Neptune

Q3: A compliance system must maintain an immutable, cryptographically verifiable audit trail for financial transactions  
A3: Amazon QLDB

Q4: A team suspects slow SQL queries are causing spikes in RDS CPU; which tool best visualizes query load and waits?  
A4: Performance Insights for RDS

### 5. Rightsizing Strategy

Selecting the smallest, most cost‑efficient compute and storage resources that still meet performance requirements by analyzing real utilization metrics; ideal for eliminating overprovisioning (idle CPU, excess memory or IOPS) and adjusting to actual workload profiles using AWS recommendations and metrics, rather than guesswork.

- **Instance Families (M/T general; C compute‑optimized; R/X memory‑optimized; I storage‑optimized; P/G/Trn accelerated):** categorized EC2 types tuned for balanced, CPU‑heavy, memory‑heavy, storage‑intensive, or GPU/accelerator workloads respectively;
- **EBS Volume Types and IOPS:** gp3 provides baseline performance with configurable IOPS and throughput at lower cost; io2/io2 Block Express deliver high, consistent IOPS for mission‑critical databases;
- **Graviton vs x86:** ARM‑based Graviton instances offer better price/performance for many workloads but may require architecture compatibility checks; x86 instances support broader legacy binaries;
- **AWS Compute Optimizer:** service that analyzes historical usage (CPU, memory, network) to recommend optimal instance types and sizes;
- **Cost Explorer Rightsizing:** tool in AWS Billing to identify underutilized EC2, RDS, and other resources and suggest downsizing or termination;
- **Burstable / On‑Demand Capacity (T instances, Fargate/Lambda):** pay‑for‑use options or credit‑based burst capacity to avoid paying for idle baseline;
- **gp3 vs io2 for Storage:** gp3 offers flexible IOPS cost‑effectively; io2 is for sustained, high IOPS needs with SLA guarantees;

**Utilization Metrics ↔ Instance/Volume Selection**  
Match resource family to bottleneck: low CPU but high memory → R/X family; high CPU but low memory → C family; high IOPS requirements → io2 volumes; balanced workloads → M/T family and gp3 volumes

**Cost Efficiency ↔ Purchase & Capacity Mode**  
Use burstable (T series) or serverless/on‑demand (Lambda, Fargate) for sporadic workloads; reserve savings plans or rightsize to smaller instances for consistently low utilization

**Performance Headroom ↔ Provisioned IOPS & Throughput**  
Increase EBS provisioned IOPS/throughput or upgrade to io2/io2 Block Express when storage latency and IOPS are the bottleneck; reduce IOPS if metrics show sustained underuse

**Architecture Optimization ↔ Graviton Adoption**  
Consider migrating to Graviton for better price/performance when applications support ARM or can be recompiled; keep x86 for proprietary binaries or when migration cost outweighs benefits

**Visibility & Recommendations ↔ Monitoring Tools**  
Leverage AWS Compute Optimizer and Cost Explorer rightsizing reports to identify low‑utilization resources; confirm with CloudWatch metrics before applying changes to avoid undersizing

Q1: CloudWatch shows CPU utilization at 10% but memory consistently at 80% on an M5 instance; how do you rightsize?  
A1: Move to an R5/R6 (memory‑optimized) instance to match the high memory usage and avoid paying for unused CPU

Q2: An application’s database volume shows sustained 25,000 IOPS demand with latency spikes; which storage option is appropriate?  
A2: Switch the EBS volume to io2 (or io2 Block Express) and configure provisioned IOPS to meet the sustained requirement

Q3: Compute Optimizer flags several C5 instances as underutilized and suggests smaller T4g instances; what should you verify before switching?  
A3: Confirm application compatibility with ARM (Graviton/T4g) architecture and test performance, then migrate to benefit from better price/performance

Q4: Nightly ETL jobs cause a fivefold spike in write throughput, but daytime usage is minimal; how can you control cost without overprovisioning?  
A4: Use scheduled scaling or burstable instances (T series) and gp3 volumes with adjustable IOPS, scaling up just before ETL and down afterward

### Task 2.6 – Determine a Cost Optimization Strategy to Meet Solution Goals and Objectives

### 1. Rightsize & Select Cost‑Effective Resources

Optimizing compute and storage to meet performance SLAs at the lowest possible cost by matching real utilization patterns—CPU, memory, IOPS—to the right instance family, storage tier, or pricing model; ideal for eliminating idle capacity, switching to Spot or serverless where appropriate, and using AWS tools to validate changes rather than guessing.

- **AWS Compute Optimizer:** analyzes historical utilization (CPU, memory, network) and recommends better‑fit instance types or sizes;
- **Cost Explorer Resource Optimization:** identifies underutilized EC2/RDS resources and suggests downsizing or termination;
- **S3 Storage Lens:** organization‑wide visibility into S3 usage, costs, and data access patterns for lifecycle and tiering decisions;
- **gp3 vs io2 EBS:** gp3 offers cost‑efficient, adjustable IOPS/throughput; io2 provides high, consistent IOPS and durability for critical workloads;
- **Graviton Instances:** ARM‑based EC2 types with improved price/performance but require software compatibility checks;
- **Spot Fleets:** discounted EC2 capacity subject to interruption, suited for fault‑tolerant or stateless workloads;
- **Instance Families (M/T/C/R/X/I/P/G/Trn):** general purpose, burstable, compute‑optimized, memory‑optimized, storage‑optimized, accelerated (GPU/ML) categories to align hardware to workload needs;
- **Serverless / On‑Demand vs Provisioned Capacity:** pay‑per‑use options (Lambda, Fargate, DynamoDB On‑Demand) vs pre‑allocated resources (EC2, provisioned DynamoDB) to balance cost with predictability;

**Utilization Metrics ↔ Resource Match**

Analyze CPU, memory, and I/O profiles; choose instance families that fit the dominant constraint (e.g., memory‑heavy → R/X, high IOPS → io2, balanced → M/T with gp3)

**Cost Model ↔ Purchase & Capacity Options**

Shift predictable steady workloads to Reserved Instances/Savings Plans; use Spot fleets or serverless/on‑demand for bursty, interruptible, or low‑duty workloads to avoid paying for idle capacity

**Storage Cost Optimization ↔ Volume & Tier Selection**

Select gp3 for tunable IOPS at lower cost; upgrade to io2/io2 Block Express only if sustained high IOPS/low latency is required; leverage S3 Storage Lens to identify objects for lifecycle transitions (e.g., Standard‑IA, Glacier)

**Architecture Choice ↔ Graviton & Platform Fit**

Migrate compatible applications to Graviton for better price/performance; retain x86 where legacy binaries or unsupported libraries make migration costly

**Visibility & Governance ↔ Optimization Tools**

Use Compute Optimizer and Cost Explorer to locate underutilized resources; confirm with CloudWatch metrics to avoid undersizing; implement tagging and budgets for governance and ongoing optimization

Q1: CPU utilization averages 8% while memory sits at 70% on an M5 instance; what change reduces cost without harming performance?  
A1: Move to a memory‑optimized R5/R6 instance that better matches the workload’s memory needs

Q2: An EC2 volume shows sustained 30,000 IOPS usage and frequent latency spikes; which EBS type is appropriate?  
A2: Switch to an io2 (or io2 Block Express) volume with provisioned IOPS aligned to the workload’s sustained demand

Q3: Several dev/test servers run 24/7 but are used only during business hours; how do you cut cost?  
A3: Implement scheduled stop/start or migrate to serverless/on‑demand resources (e.g., Lambda, Fargate) where possible, or use smaller burstable T instances

Q4: Compute Optimizer recommends downsizing C5 instances to T4g for better price/performance; what must be validated first?  
A4: Confirm application compatibility with ARM architecture before moving to Graviton‑based T4g instances

Q5: A batch analytics job is fault‑tolerant and runs nightly; how can you minimize compute spend?  
A5: Use Spot fleets for EC2 instances (or Fargate Spot) to leverage discounted capacity with acceptable interruption risk

### 2. Choose Appropriate Pricing Models

Selecting the most cost‑effective purchase option—Reserved Instances, Savings Plans, Spot, or On‑Demand—based on workload predictability, flexibility needs, and interruption tolerance; ideal for balancing long‑term savings against architectural portability and ensuring stateless or batch tiers leverage Spot while stable baselines commit for deeper discounts.

- **Reserved Instances (Standard vs Convertible):** Standard RIs lock instance family/region/OS for maximum discount; Convertible RIs allow exchange for different instance families while still offering significant savings;
- **Savings Plans (Compute / EC2 Instance / SageMaker):** flexible commitment models; Compute SP applies to any compute (EC2, Fargate, Lambda), EC2 Instance SP targets specific instance families/regions, SageMaker SP is for ML workloads;
- **Spot Instances:** spare EC2 capacity at steep discounts, interruptible with two‑minute notice, suitable for stateless, batch, or fault‑tolerant workloads;
- **On‑Demand:** pay‑as‑you‑go pricing with no commitment, ideal for unpredictable or short‑term workloads;
- **Committed Term Lengths (1‑year / 3‑year):** longer terms offer higher discounts but reduce flexibility;
- **Payment Options (No Upfront / Partial Upfront / All Upfront):** increasing upfront payment yields higher effective savings;
- **Mixing Purchase Models:** blending baseline RIs/SP with Spot for burst capacity or dev/test tiers to optimize overall cost;

**Workload Predictability ↔ Commitment Model**

Stable, long‑running workloads: choose Standard RIs or EC2 Instance SP; moderate predictability or migration plans: use Convertible RIs or Compute SP for flexibility; highly unpredictable workloads: stick to On‑Demand or serverless

**Portability & Service Mix ↔ Savings Plan Type**

If workloads may move between EC2, Fargate, and Lambda, opt for Compute Savings Plans; if you remain on a fixed EC2 family/region, EC2 Instance SP or Standard RI can achieve deeper discounts

**Interruption Tolerance ↔ Spot Integration**

For stateless web tiers, CI/CD runners, batch analytics, or ETL jobs, use Spot fleets or Spot capacity providers; ensure autoscaling and checkpointing to handle interruptions gracefully

**Discount Maximization ↔ Term & Upfront Choice**

3‑year terms and All Upfront payments yield the highest discount; for cash‑flow constraints, choose Partial or No Upfront; balance finance policy with AWS cost reduction targets

**Cost Governance ↔ Tooling & Monitoring**

Track commit utilization with Cost Explorer and AWS Budgets; simulate scenarios before purchase to avoid under‑ or over‑commitment; adjust with Convertible RIs or shift workloads to fit committed SP coverage

Q1: A company migrates parts of its workload from EC2 to Fargate over the next year; which commitment model provides broad coverage and long‑term savings?  
A1: Compute Savings Plans (rather than Standard RIs) for flexibility across EC2 and Fargate

Q2: A steady web application runs 24/7 on the same EC2 instance family and region; how do you maximize savings?  
A2: Purchase 3‑year Standard Reserved Instances (or EC2 Instance Savings Plans) with All Upfront payment

Q3: A nightly batch job is fault‑tolerant and can handle interruptions; what is the most cost‑effective compute option?  
A3: Use Spot Instances (or Spot Fleets) for the batch tier

Q4: Utilization data shows servers idle 60% of the time, but traffic is unpredictable; how can you cut cost without locking into a specific instance type?  
A4: Choose Compute Savings Plans and supplement with Spot for burst capacity; avoid rigid Standard RIs

### 3. Model & Minimize Data Transfer Costs

Analyzing where bytes move—across AZs, Regions, or the public internet—and redesigning paths to cheaper, private, or cached routes; ideal for workloads surprised by high egress bills, frequent cross‑Region replication, or NAT gateway charges, where simple architectural shifts (endpoints, caching, peering) can drastically cut cost without hurting performance.

- **Inter‑AZ / Inter‑Region Transfer Pricing:** data sent between AZs or Regions is billed; same‑AZ traffic is usually free or cheaper, while cross‑Region replication is often the most expensive path;
- **PrivateLink / VPC Endpoints (Interface & Gateway):** private connections to AWS services or third‑party SaaS over the AWS network; interface endpoints (ENI‑based) vs gateway endpoints (S3/DynamoDB only, free data path within Region);
- **CloudFront for Egress Offload:** CDN caching that serves content from edge locations, reducing origin egress and lowering internet data transfer costs;
- **S3 Transfer Acceleration vs Standard PUT/GET:** accelerated uploads/downloads via edge locations for long‑distance transfers; standard operations are cheaper if latency is acceptable;
- **Direct Connect vs Internet Egress:** dedicated private link to AWS with predictable bandwidth pricing vs variable internet egress charges;
- **NAT Gateway vs NAT Instance Costs:** managed NAT gateways charge per GB processed and per hour; NAT instances can be cheaper at scale but require management;
- **Data Transfer Monitoring & Tagging:** using Cost Explorer, CUR, and tagging to attribute transfer costs and identify hotspots;

**Cost Drivers ↔ Traffic Path Selection**

Minimize inter‑Region replication unless required; keep producer/consumer in the same AZ or Region when possible to avoid per‑GB cross‑Zone/Region fees

**Private Connectivity ↔ Endpoint & Peering Choices**

Use gateway endpoints for S3/DynamoDB access to avoid NAT/data egress; prefer PrivateLink or VPC peering over public endpoints to keep traffic on the AWS backbone

**Egress Offload ↔ Edge Caching & Acceleration**

Place CloudFront in front of S3 or ALB to serve cached/static assets and reduce origin egress; enable S3 Transfer Acceleration only for globally distributed clients where upload/download latency matters

**On‑Prem Connectivity ↔ Direct Connect vs Internet**

For steady, high‑volume data exchange, choose Direct Connect to lower per‑GB rates and improve consistency; use VPN/Internet for sporadic or low‑volume workloads

**NAT Architecture ↔ Gateway vs Instance Economics**

For heavy outbound traffic, evaluate NAT instance (auto scaling + scripts) vs managed NAT gateway fees; consolidate NAT gateways per AZ if needed but consider fault domains

**Monitoring & Governance ↔ Visibility Tools**

Tag resources and use Cost Explorer or the Cost & Usage Report to attribute transfer spend; establish budgets and alerts for unexpected spikes in inter‑Region or NAT charges

Q1: A workload replicates large datasets nightly between us‑east‑1 and ap‑southeast‑2, causing high transfer bills; how can you reduce cost?  
A1: Restrict replication to critical subsets or redesign to keep processing in one Region, minimizing inter‑Region data movement

Q2: An application in a private subnet accesses S3 through a NAT gateway, incurring large NAT data processing fees; what is the cheaper alternative?  
A2: Use an S3 gateway VPC endpoint to route traffic privately within the Region and avoid NAT charges

Q3: A media site’s origin in us‑west‑2 is incurring high internet egress costs; users are global and request static assets frequently  
A3: Put CloudFront in front of the origin to cache and deliver content from edge locations, reducing origin egress

Q4: A company needs a consistent, high‑bandwidth link from on‑premises to AWS with lower per‑GB charges than the public internet  
A4: Provision AWS Direct Connect to replace or supplement internet egress for steady data transfer

### 4. Govern Spend & Usage Awareness

Establishing visibility, controls, and alerts around AWS costs so teams know where money goes, can react to anomalies quickly, and stay within budgets; ideal for organizations needing auditable chargeback/showback processes, proactive notifications on spikes, and enforced tagging policies to prevent untracked spend.

- **AWS Budgets:** set custom cost or usage thresholds and trigger alerts (email/SNS) when limits are approached or exceeded;
- **Cost Explorer:** analyze historical spend and usage trends with filtering/grouping (by service, tag, account) for optimization insights;
- **Cost & Usage Report (CUR):** detailed, hourly-level billing data delivered to S3 for advanced analytics (Athena/QuickSight);
- **Trusted Advisor Cost Checks:** automated recommendations for underutilized resources, idle load balancers, low EBS usage, etc.;
- **Cost Anomaly Detection:** ML-based detection of unusual spend patterns with SNS notifications;
- **Tagging / Cost Categories:** enforce metadata on resources for chargeback/showback, and group costs logically (departments, projects);
- **Service Control Policies (SCPs) & Guardrails:** organization-wide policies to restrict actions that could incur unexpected costs;
- **AWS Pricing Calculator:** estimate and forecast monthly costs for architectures before deployment;

**Cost Visibility ↔ Reporting & Analytics**

Enable CUR for granular billing data, analyze via Athena/QuickSight; use Cost Explorer for quick trend insights and to segment spend by tag/account

**Proactive Control ↔ Budgets, Alerts & Anomaly Detection**

Configure AWS Budgets for each team/project with SNS or email alerts; enable Cost Anomaly Detection to auto-notify owners of spend spikes

**Chargeback / Showback ↔ Tagging & Cost Categories**

Enforce mandatory tags (e.g., Owner, Environment, Project) and use Cost Categories to group costs for internal billing; automate tag compliance via IAM/SCPs or Config rules

**Policy Enforcement ↔ SCPs & Guardrails**

Apply SCPs to block launching expensive resource types or Regions; use AWS Control Tower guardrails to codify cost governance best practices

**Forecasting & Planning ↔ Pricing Calculator & Historical Trends**

Use AWS Pricing Calculator to estimate cost pre-deployment; review Cost Explorer trends and CUR analytics to refine budgets and commitments (RIs/SPs)

Q1: A team’s monthly costs suddenly spike without explanation; which AWS service can automatically detect and alert on this anomaly?  
A1: Cost Anomaly Detection with SNS notifications

Q2: Finance wants to allocate costs to departments based on usage; how do you implement this with AWS-native tools?  
A2: Enforce resource tagging and use Cost Categories to group and report spend per department

Q3: A project owner needs an alert when forecasted monthly costs exceed a set threshold; what should you configure?  
A3: AWS Budgets with a cost threshold and SNS/email alerts

Q4: An architect must provide an upfront cost estimate for a new multi-tier web application; which tool is best suited?  
A4: AWS Pricing Calculator for pre-deployment cost forecasting
