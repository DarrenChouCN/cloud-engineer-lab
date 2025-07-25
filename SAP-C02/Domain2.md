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

### Blue/Green Deployment

| Section                   | Key Points                                                                                                                                                                                                                                                                                                                                                           |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Summary**               | Two parallel environments (“blue” current, “green” new). Shift production traffic with CodeDeploy’s ALB / Route 53 traffic-shifting or the built-in RDS Blue/Green clone. Rollback = instant DNS/target-group flip.                                                                                                                                                  |
| **Application Scenarios** | • Zero-downtime version upgrades, schema migrations.<br>• Regulatory workloads needing fast rollback proof.<br>• Major library/OS jumps where inplace upgrade is risky.                                                                                                                                                                                              |
| **Key Points**            | • _CodeDeploy blue/green_ supports EC2, Lambda, ECS; choose “Traffic Routing = Blue/green”.<br>• ALB/Route 53 weighted shifting: all-at-once, linear, or canary 10/90.<br>• Pre-traffic and post-traffic hooks → CloudWatch alarms trigger automatic rollback.<br>• _RDS Blue/Green_ clones prod, syncs changes, then swaps endpoints in <1 min with zero data loss. |
| **Sample Q**              | _“Need zero-downtime schema change; must revert in seconds if errors exceed 1 %. Which deployment pattern & services?”_ → **Blue/green with CodeDeploy + ALB weighted shifting & CloudWatch alarm rollback**.                                                                                                                                                        |

**Note:**
In essence, a blue/green deployment operates two parallel environments: blue continues to serve stable production traffic, while green hosts the new—hence potentially risky—version. By deliberately shifting traffic between these environments, teams isolate the blast radius of failures and can revert in seconds, shielding users and the business from costly downtime.

Initially, every request is routed to the blue environment. Once development finishes, the team provisions an identical green stack and deploys the new release to it; during this phase traffic still stays on blue. After validating the green stack, an explicit trigger—manual or policy-driven—gradually or instantly redirects traffic from blue to green. If post-cut-over metrics breach predefined CloudWatch alarms, an automated rollback flips the ALB/Route 53 target back to blue, restoring the stable version and decommissioning the faulty green stack.

### Canary Deployment

| Section                   | Key Points                                                                                                                                                                                                                                                                                               |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Summary**               | Release first to a small slice (e.g., 5–10 %) of users or hosts, monitor, then expand. AWS AppConfig makes this trivial for configs/feature flags; CodeDeploy and API Gateway canary do the same for code or APIs. Auto-rollback on CloudWatch alarms.                                                   |
| **Application Scenarios** | • Limit blast radius while testing new logic.<br>• Config toggles, ML model swaps, mobile A/B tests.<br>• SLA-sensitive apps where 100 % failure is unacceptable.                                                                                                                                        |
| **Key Points**            | • _AWS AppConfig_ deployment strategies: “Canary10Percent30Minutes” etc.—built-in rollback.<br>• Attach CloudWatch Alarm → AppConfig stops & rolls back when breaching threshold.<br>• CodeDeploy supports “Canary10Percent5Minutes” for Lambda & ECS.<br>• API Gateway stage canary for 1–99 % traffic. |
| **Sample Q**              | _“Must expose new feature to only 10 % of users and auto-revert on 5XX spike—minimal code change.”_ → **AppConfig canary + CloudWatch alarm**.                                                                                                                                                           |

**Note:**
A canary deployment releases a new version to a deliberately small subset of users or hosts—typically 5-10 percent—so the team can watch real-time metrics before expanding the audience. By tuning that slice upward only when error rates and latency stay within thresholds, and by wiring the rollout to auto-rollback on any alarm breach, canary delivery minimizes blast radius yet avoids the cost of running a full parallel environment.

All traffic initially targets the stable production stack. The team configures a canary strategy—say “10 percent for 30 minutes, then linear 10 percent every 5 minutes”—in AWS AppConfig or CodeDeploy, binds CloudWatch alarms for key metrics, and launches the deployment, which routes just the first 10 percent of requests to the new code or configuration while the remainder stays on the old path. If those early signals remain healthy, the orchestrator automatically advances through each scheduled increment until 100 percent of traffic reaches the new version; if any alarm fires, the system halts the rollout, rolls every affected request back to the prior release, and records the failure for post-mortem, leaving customer experience intact.

### Rolling Update

| Section                   | Key Points                                                                                                                                                                                                                                                                                                              |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Summary**               | Replace a fleet in chunks; each batch is terminated and relaunched with the new version until 100 % are updated. No duplicate environment needed, but rollback equals a second rolling cycle. Best delivered via EC2 Auto Scaling _Instance Refresh_, ECS rolling, or Beanstalk rolling with batch settings.            |
| **Application Scenarios** | • Large stateless fleets where short capacity dip is acceptable.<br>• Cost-conscious teams avoiding double infra.<br>• Minor, frequent releases (patches, small features).                                                                                                                                              |
| **SAP Exam Key Points**   | • _Instance Refresh_ params: `MinHealthyPercentage`, `SkipMatching` to avoid churn.<br>• CodeDeploy “in-place” for EC2 offers automatic rollback if a batch fails.<br>• For stateful workloads, combine with Multi-AZ to preserve availability.<br>• Compared with blue/green, rollback is slower (another full cycle). |
| **Sample Q**              | _“Service can lose up to 20 % capacity during upgrade; cost must stay flat.”_ → **Rolling update via Auto Scaling Instance Refresh (MinHealthy = 80 %)**.                                                                                                                                                               |

**Note:**

A rolling deployment updates a service by replacing its instances in small, controlled batches—retiring a few old nodes, launching the new version, verifying health, and repeating until every node runs the release. Because it reuses the existing fleet, it keeps infrastructure cost flat, though each batch briefly lowers available capacity and a rollback requires running the same cycle in reverse.

Production traffic starts on a healthy Auto Scaling group. An Instance Refresh is kicked off with a policy such as “replace 10 percent at a time, keep 90 percent healthy,” so the orchestrator terminates the first slice of instances, spins up replacements with the new launch template, attaches them to the load balancer after they pass health checks, and only then proceeds to the next slice. CloudWatch alarms watch error rate and latency throughout; if any batch fails to register healthy within its grace period or an alarm fires, the refresh halts and a reverse cycle restores the previous launch template, returning capacity to its pre-deployment state while user traffic experiences at most a transient reduction but no hard outage.

### Offload with Managed Services

| Managed service    | What it off-loads for you                                                                                                                      | When the exam will prefer it                                                               | 1-liner you can memorise                                                  |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| **AWS App Runner** | - No cluster, load-balancer, or auto-scaling to build.<br>- Point at a container image or repo; the platform builds, deploys, patches, scales. | Question says _“publish a container/web app with zero infrastructure or patching effort.”_ | “PaaS-for-containers: just give it code/image, App Runner does the rest.” |
| **AWS Proton**     | - Platform team defines _golden_ IaC & CI/CD templates once; dev teams self-service new micro-services without touching the underlying infra.  | _“Central platform wants standardised stacks; application squads need self-service.”_      | “Self-service micro-service factory.”                                     |
| **AWS Fargate**    | - Serverless compute for ECS/EKS: no EC2 provisioning, patching, or scaling.                                                                   | _“Run containers but remove instance management overhead.”_                                | “Serverless containers.”                                                  |
| **AWS Lambda**     | - AWS patches the runtime & underlying fleet automatically; you only own the function code.                                                    | _“Cut ops burden / no servers / per-request scaling.”_                                     | “Functions, not servers.”                                                 |
| **RDS Proxy**      | - Manages DB connection pooling, automatic fail-over, TLS, & secret rotation—saves writing pooling logic & reduces client-side retries.        | _“Reduce database connection management / spiky Lambda traffic.”_                          | “Managed, auto-scaling DB pool.”                                          |

| Typical stem                                                                                       | Correct pick   | Why the others lose                                                                          |
| -------------------------------------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------------------------------- |
| _“Deploy a new containerised web API in minutes, no cluster expertise.”_                           | **App Runner** | ECS/EKS need cluster admin.                                                                  |
| _“Platform team must enforce standards; devs must spin up services by themselves.”_                | **Proton**     | CodePipeline + CloudFormation alone lack self-service guard-rails.                           |
| _“Run bursty containers, avoid patching EC2.”_                                                     | **Fargate**    | EC2 launch templates still need patching.                                                    |
| _“Need to scale a Python ETL job to zero, pay per request.”_                                       | **Lambda**     | Fargate stays warm, EC2 always on.                                                           |
| _“Thousands of short-lived Lambda invocations exhaust DB connections; must lower admin overhead.”_ | **RDS Proxy**  | Adding read-replicas or increasing `max_connections` treats the symptom, not the ops burden. |

## Task 2.2: Design a solution to ensure business continuity

### Route 53 Failover Toolbox

Beyond traditional DNS resolution, Route 53 introduces smart routing logic to direct traffic dynamically to the next healthy endpoint—based on business priorities such as latency, availability, or regional compliance.

#### Routing Policy Types

- Failover – Designate one record as primary and another as secondary, then attach a health check. When the primary becomes unhealthy, Route 53 automatically fails over to the secondary. Classic active–passive setup.
- Latency-based – Picks the Region with the lowest network latency relative to each user’s location. Ideal for multi-Region, globally distributed applications.
- Weighted – Split traffic between records by percentage (e.g., 10/90), often used for canary deployments or gradual cutovers across environments or clouds.
- Multi-value answer – Returns up to 8 healthy IP addresses per DNS query. Offers basic load balancing and failure tolerance without needing a full load balancer.
- Geo / Geo-proximity – Routes traffic based on user geography. Useful for compliance (e.g., keeping EU users in EU Regions), or biasing traffic to certain regions during peak loads.
- Simple – A static DNS record without any routing logic. No health check, no failover.

#### TTL: The Hidden Key to Faster Failover

Since DNS results are cached, Route 53 failover isn’t instantaneous unless TTL is kept low. AWS best practices recommend setting TTL between 30–60 seconds for any record involved in health-based routing.

Even then, some clients or ISPs may cache records longer than expected, preventing timely failover.

#### Why Add Global Accelerator on Top?

To guarantee <30-second failover unaffected by DNS caching, AWS recommends fronting latency-sensitive or mission-critical applications with Global Accelerator, which works at the IP layer:

- Fixed Anycast IPs – Users always connect to the same global IP; routing decisions happen behind the scenes, unaffected by local DNS caching.
- Edge-level health checks – If an entire Region becomes unhealthy, Accelerator shifts traffic to the next healthy endpoint—automatically and instantly.
- ARC Zonal Shift integration – When you or AWS ARC marks a specific AZ as degraded, Global Accelerator instantly stops routing traffic to that AZ, enabling sub-second failover at the AZ level.

### AWS disaster-recovery services

#### AWS Elastic Disaster Recovery (DRS)

A fully-managed replication engine that streams block-level changes from your primary EBS volumes to a standby Region (or AZ). A single Failover click launches identical EC2 instances—network, IAM roles, tags, even VPC mappings—within minutes; Failback re-syncs deltas and powers workloads back on the primary site. The service covers both pilot-light and warm-standby patterns, giving sub-hour RTO and sub-minute RPO with no custom scripts.

**Note:** “DRS is the parachute you never want to pull—if an entire Region melts down, it rebuilds your stack in another Region almost automatically.” It tackles the rare Region-wide failure scenario; think of it as recovering all AZs at once.

#### AWS Application Recovery Controller (ARC)

A control-plane service that protects you from in-Region availability-zone trouble. Zonal shift lets you manually drain traffic from one AZ; zonal autoshift does it automatically when AWS detects AZ-level degradation. ARC talks to Route 53 and Global Accelerator, shifting traffic away in ~30 s without touching your application code. It also exposes routing controls and readiness checks so you can script full Region failovers and confirm—via simulation—that they will work before you pull the trigger.

**Note:** “If one building in a city has a fire, ARC reroutes the traffic lights so cars avoid that block.” It is the fast, AZ-scoped counterpart to DRS’s Region-scale recovery.

#### AWS Resilience Hub

A resiliency control tower. Register your application (CloudFormation stacks, Terraform state, App Registry tags), declare target RTO/RPO, and run an automated assessment. Resilience Hub scores every disruption type, flags gaps, and produces a playbook—extra AZs, cross-Region replicas, Route 53 policies, alarms, etc. It can schedule periodic re-assessments and raise findings in Security Hub so configuration drift is caught long before disaster strikes.

**Note:** “A virtual chief-auditor: it tells you, before the outage, whether your RTO/RPO promises are actually achievable—and how to fix them if they’re not.”

#### AWS Backup + Vault Lock

Centralises snapshots for RDS, DynamoDB, EFS, EC2/EBS, FSx, and more, and can copy them automatically to a secondary Region. Vault Lock turns a backup vault into WORM storage whose retention and deletion policies cannot be changed—not even by the root user—meeting ransomware and regulatory “air-gap” requirements.

**Note:** “The un-delete-able safety-deposit box.” Whereas DRS and ARC protect running workloads, Backup + Vault Lock protects the data itself—a last-line defence if both primary and standby copies are corrupted or encrypted by attackers.

### Data & database replication cheats

#### Aurora Global Database

Engine-side, asynchronous storage replication uses the Aurora log stream. A secondary Region lags by typically <1 second RPO; if the primary Region dies you promote a secondary cluster in ≈60 seconds RTO. Failover is one-way; when the old primary comes back you re-add it as a replica. Supports up to 10 secondary Regions today.

Why you pick it: relational workload, near-zero data loss, read scaling close to users.

#### DynamoDB Global Tables

Fully managed, multi-active, multi-Region replication. Every replica table can take writes; DynamoDB resolves conflicts with “last writer wins.” Route 53 latency routing (or API client token) decides which Region the user hits. Latency is single-digit milliseconds locally—perfect for mobile, gaming, or IoT data that must be writable everywhere.

Why you pick it: No-SQL, globally available read and write access; you don’t tolerate write downtime.

#### S3 Cross-Region Replication (CRR)

Bucket-level, asynchronous object copy—including tags, ACLs, and (optionally) delete markers—into one or more target Regions. Meets compliance rules that demand an off-site replica and acts as the data layer for backup-and-restore DR. CRR now supports “replication metrics” so you can alarm if lag exceeds an SLA.

Why you pick it: object data, compliance/long-term archive, or static-site assets that must survive a Region outage.

#### EBS & EFS Replication

EBS: point-in-time snapshots or continuous block replication via EBS Multi-AZ/Region Snapshot Copy (DRS uses the same stream behind the scenes).

EFS: one-click file-system replication to a secondary Region; the destination is read-only until you promote it during disaster recovery.

Why you pick it: lift-and-shift EC2 or Linux workloads that depend on block/file storage rather than database engines.

#### RDS Cross-Region Read Replicas

Available for MySQL, MariaDB, PostgreSQL, Oracle, SQL Server. Uses engine-native asynchronous replication; promotion of a replica makes it the new primary (minutes-level RTO, seconds-to-minutes RPO). Good midway option when Aurora Global DB is over-kill or unsupported.

Why you pick it: traditional RDS engine, single-writer-many-reader pattern, moderate RPO/RTO.

**Exam tips:**

- “Sub-second RPO, relational, writer in one Region only” → Aurora Global DB.

- “Multi-Region active-active writes, sub-20 ms latency everywhere” → DynamoDB Global Tables.

- “Object data must have an immutable copy in another Region for compliance” → S3 CRR.

- “Block/file storage for EC2/EFS workload, need simple replica you can promote” → EBS/EFS Replication (or DRS if you want one-click rebuild).

- “Classic MySQL/Postgres DB, Region outage must promote a standby within minutes” → RDS Cross-Region read replica.

### Automated, low-cost backups

AWS Backup can be turned into an organisation-wide policy engine: you attach a backup plan at the OU or account level and every new RDS, DynamoDB, EFS, EC2/EBS or FSx resource is automatically protected, no per-team scripting required. When compliance or ransomware defence matters, you place the recovery points in a Vault Lock. Once the grace period ends the vault becomes WORM; even the root user (or a compromised IAM role) cannot shorten retention or delete snapshots.

To avoid “backup sprawl” on the bill, tier ageing recovery points to S3 Glacier Deep Archive—a click in the backup plan—cutting long-term storage cost by up to 75 %.

**Exam cue:** a stem that says “govern backups across every account and Region and be sure nobody can delete them early” maps straight to AWS Backup org-level policies + Vault Lock.

### Testing & chaos engineering

Elastic Disaster Recovery drills let you spin up hundreds of replicated servers in the target Region without touching production I/O; you validate end-to-end service health, then terminate the drill and pay only for the test hours.

For AZ-level chaos, run the AWS Fault Injection Simulator scenario AZ Availability: Power Interruption with a recovery action that triggers Application Recovery Controller (ARC) zonal autoshift. The experiment yanks an Availability Zone out from under your workload and proves that Route 53 / Global Accelerator really stop routing traffic there within ~30 s.

Continuous assurance comes from Resilience Hub scheduled assessments: enable daily scans; if an RTO/RPO score turns from “Achieved” to “Breached” the hub can post a Security Hub finding or SNS notification—treat it exactly like a change-request you must fix before the next release.

**Exam cue:** anything that reads “prove the automation works, inject failure, validate alarms” → Fault Injection Simulator + ARC; anything about “run full fail-over tests with no production impact” → DRS Recovery Drill; a line about “periodic, automatic resilience assessments” → Resilience Hub.

### Centralised monitoring to “sense & heal”

#### CloudWatch + EventBridge = the cross-account nerve system

- Put every application metric and log in Amazon CloudWatch.
- Share the alarms to a monitoring hub account by turning on CloudWatch cross-account observability (or by routing alarms through EventBridge `PutEvents`).
- Wire the alarms to an EventBridge rule that targets AWS Systems Manager Automation runbooks (SSM documents).
  Examples – restart a failed ECS task, enlarge an Auto-Scaling group, or block an IP in the WAF.

**Exam cue:** a stem that says “sense the failure and auto-remediate across all accounts” → CloudWatch alarm → EventBridge → SSM runbook.

#### AWS Health + Application Recovery Controller (ARC) = platform-level insight & traffic self-healing

- AWS Health Dashboard / Health API streams service events: degraded AZ networking, EBS impairment, Route 53 DNS issue, etc.
- ARC zonal autoshift subscribes to those Health events; when an AZ is flagged unhealthy, ARC instructs Route 53 or Global Accelerator to drain traffic in ≈30 s.
- You can also push the Health events into EventBridge and fan-out to PagerDuty, Slack, or a “war-room” SNS topic.

#### One “single pane of glass” for critical alarms

Set up a dedicated Security / Operations master account that owns:

- An SNS topic (high-sev alerts).
- AWS Chatbot or Slack / MS Teams integration.
- EventBridge rules that filter only `ALARM` or `AWS_HEALTH_EVENT` from every spoke account/Region.

**Exam cue:** “central notification”, “single pane of glass”, “cross-Region/X-account visibility” — they map to: CloudWatch cross-account → EventBridge → central SNS/Chatbot

## Task 2.3 — Determine security controls based on requirements

### Endpoints

AWS Endpoints are private entry points that let resources inside a VPC reach AWS services without traversing the public Internet. There are two kinds:

- Gateway Endpoint – a route-table target that supports only Amazon S3 and DynamoDB.
- Interface Endpoint / AWS PrivateLink – an elastic network interface (ENI) with a private IP; DNS for the service resolves to that ENI. Since Nov 2024, an interface endpoint can even reach a service in another Region.

**Use Cases**

- Write logs from EC2 instances to S3 while blocking all Internet egress → create a Gateway Endpoint and add the route.
- Call a third-party SaaS API privately from a Sydney VPC to us-east-1 → create a cross-Region Interface Endpoint.

| Scenario                                           | Steps & Components                                                                                                                                                  |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Private S3/DynamoDB access**                     | ① Create Gateway Endpoint → ② Update subnet route table to target `vpce-xxxx` → ③ (Optional) add S3 bucket policy that _denies_ `aws:SourceVpce` ≠ your endpoint    |
| **Private access to regional AWS or SaaS service** | ① Create Interface Endpoint → ② Security group allows outbound 443 and inbound responses → ③ DNS hostname of service now resolves to the ENI’s 10.x address         |
| **Cross‑Region PrivateLink**                       | ① Consumer VPC creates Interface Endpoint (cross‑Region flag) → ② AWS transparently routes over the backbone to the service’s Region; origin never sees a public IP |

**Exam Focus**
Identify cues such as “private access to S3/DynamoDB” (Gateway Endpoint) and “private API call to a Regional service or SaaS provider, cross-Region” (Interface Endpoint / PrivateLink).

Q: A compliance rule states: “No Internet gateway or NAT may be attached, yet the app must write audit files to Amazon S3.” Which design meets the requirement with minimal changes?
A: B. Create an S3 Gateway Endpoint and update the route table

Q: A compliance rule states: “EC2 instances in a private subnet must write logs to S3 without using public IPs, NAT, or Internet Gateways.” What is the simplest solution?
A: Create an S3 Gateway Endpoint and add the endpoint ID to the bucket policy.

**Note:**
Endpoints exist to keep traffic inside the VPC; a Gateway Endpoint is a routing shortcut for S3/DynamoDB, whereas an Interface Endpoint (PrivateLink) drops an ENI in the subnet and—after Nov 2024—can even bridge Regions, so you choose the type strictly by the target service and privacy scope.

Just remember the decision table: S3 / DynamoDB → Gateway; everything else → Interface Endpoint / PrivateLink; different Region → Interface Endpoint + cross‑Region flag. Gateway endpoints are free and use routing; interface endpoints cost per‑hour and behave like miniature NLBs inside your subnet, but both keep packets on the AWS backbone—meeting “no public Internet” requirements with almost zero network re‑architecture.

### S3 Encryption – SSE-KMS vs. SSE-S3

Both options encrypt objects at rest:

- SSE-S3 – AWS owns and rotates the keys; simplest and fastest.
- SSE-KMS – uses a KMS key (AWS-managed or customer-managed); gives audit trails, key rotation, and per-tenant segregation, at the cost of KMS API rate limits.

**Use Cases**

- General archival data → SSE-S3 is sufficient.
- Regulated workloads needing separate keys per customer and detailed audit → enforce SSE-KMS in a bucket policy and require `aws:kms` encryption context.

**Exam Focus**
Look for phrases such as “must use customer-managed keys” or “need to audit each decrypt” (SSE-KMS) versus “quickly enable default encryption” (SSE-S3).

Q: An auditor finds that some PUT requests to S3 occur over HTTP. What is the fastest way to block future non-TLS uploads without touching every client?
A: Attach a bucket policy that DENY requests where "aws:SecureTransport":"false".

**Note:** SSE-S3 relies entirely on AWS-controlled keys for hassle-free encryption, whereas SSE-KMS shifts control to KMS so DevOps can prove key ownership, configure rotation, enforce encryption context, and monitor every decrypt API call—choosing between them depends on audit and segregation needs, not on extra code.

### Multi-Region KMS Keys for EBS / RDS / DynamoDB

A Multi-Region Key (MRK) is a pair of KMS keys in two Regions that share the same key ID and key material; AWS keeps their policies and rotation state in sync.

**Use Cases**

- Aurora Global Database or DynamoDB Global Tables replicating across Regions: the source encrypts with its MRK copy; the replica Region transparently decrypts with the identical twin key.
- Cross-Region EBS snapshot copy: the snapshot remains encrypted and usable on arrival with no re-encryption.

**Exam Focus**
Key phrases: “encrypt in one Region, decrypt in another”, “no plaintext key material crosses Regions” → choose a Multi-Region Key rather than separate single-Region CMKs.

Q: A multinational bank replicates DynamoDB tables between `ap-southeast-2` and `us-east-1`. Compliance demands no plaintext key material cross Region. Which feature meets the requirement with least effort?
A: B. AWS KMS Multi-Region Keys

**Note:** The MRK concept works because each Region holds an identical, independently stored copy of the key—so encryption and decryption succeed transparently on both sides while satisfying regulations that forbid exporting raw key material; it is the go-to choice whenever AWS-managed cross-Region replication of encrypted data is required.

### Custom Applications / Load-Balancer Encryption

Client here means the entity initiating the TLS session—browser, mobile app, EC2 process, IoT device, Lambda, etc.
Load balancer is the single entry point that distributes traffic across many targets; in AWS this is usually:

- ALB (Application Load Balancer) – layer 7 HTTPS; integrates with ACM for server certificates and supports TLS termination.
- NLB (Network Load Balancer) – layer 4 TCP/TLS for ultra-low latency. API Gateway can additionally enforce mutual TLS (mTLS) to authenticate clients with X.509 certificates.

**Use Cases**

- Serve a public website → front it with an ALB, request an ACM certificate, terminate TLS at the ALB.
- B2B API requiring client-certificate auth and no Internet exposure → Regional API Gateway + PrivateLink + mTLS.

**Exam Focus**
Exam keywords include “mutual TLS”, “client certificate authentication”, “terminate HTTPS at ALB with ACM”, and “private API with PrivateLink”.

Q: A fintech partner must call your REST API with client certificate authentication and no public Internet exposure. What is the best AWS-native design?
A: Place the API behind a Regional API Gateway with PrivateLink and enable mutual TLS using an ACM-imported client CA.

**Note:** In this context the client is simply whichever component starts the TLS handshake, while the load balancer (ALB/NLB) or API Gateway serves as the secure front door—terminating TLS with ACM certificates or performing mTLS when extra authentication is needed—so DevOps mostly toggles a few TLS settings, attaches certs, and lets the managed service enforce encryption and identity.

### AWS Shield Advanced

AWS Shield Advanced is a subscription service that mitigates DDoS attacks at three OSI layers:

| OSI layer            | Attack examples                             | Shield Advanced defence technique                                                                             |
| -------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| **L3 (Network)**     | ICMP flood, IP fragmentation, amplification | Edge‑based packet filtering and traffic engineering at AWS border                                             |
| **L4 (Transport)**   | TCP SYN/ACK flood, UDP reflection           | State tracking & connection quotas applied in the AWS DDoS scrubbing fleet                                    |
| **L7 (Application)** | HTTP floods, login abuse, API scraping      | _Since Jun 2025_ Shield automatically deploys AWS WAF rule groups that rate‑limit or block malicious requests |

Additional benefits: 24 × 7 Shield Response Team (SRT) support, cost‑protection credits, and detailed attack dashboards.

**Application Scenarios**

- L3: A DNS‑based amplification flood saturates your public IP space → Shield drops traffic at the edge before it reaches the VPC.
- L4: A SYN flood exhausts connection tables on your Network Load Balancer → Shield’s L4 defences absorb and shape the flood.
- L7: A botnet sends a million HTTP POSTs per minute to /login → Shield configures WAF rate‑based rules automatically; legitimate traffic continues.

**Exam Cues**
“Automatic layer‑7 DDoS mitigation”, “24 × 7 SRT”, “cost‑protection” → Shield Advanced.

Q: A gaming company wants AWS to automatically block large HTTP floods and provide expert assistance during attacks. Which service should they use?
A: AWS Shield Advanced

**Note:** Shield Advanced maps directly onto the practical attack surface of today’s Internet: OSI L3 and L4 volumetric floods that aim to congest networks, and OSI L7 request floods that exhaust application resources. AWS handles all three in one service—invoking its own packet‑scrubbing pipeline for L3/L4 and orchestrating AWS WAF for L7—so you activate protection with a few clicks rather than designing per‑layer defences yourself.

### AWS WAF 

AWS WAF is a fully customisable OSI Layer 7 Web Application Firewall. You attach a Web ACL to resources such as CloudFront, ALB, API Gateway or App Runner and create rules that inspect IPs, headers, bodies, cookies, or request rates.

**Application Scenarios**

- SQL Injection (L7): Block any request whose URI or body matches `(?i)union\s+select` to protect legacy search endpoints.
- Credential‑Stuffing (L7): Apply the managed Account Takeover Protection rule set to throttle failed logins across IP/user pairs.
- Bot‑Scraping (L7): Combine header inspection and rate‑based rules to identify non‑browser agents and deny or challenge them.
  (All scenarios sit at OSI Layer 7; lower layers are handled by Shield Advanced or the AWS network itself.)

**Exam Cues**
“Custom rule to block specific URI”, “rate‑limit to 100 req/s”, “account takeover protection” → AWS WAF.

Q: A SaaS team must block requests containing union select on /search. Which managed service requires the least operational overhead?
A: AWS WAF

**Note:** AWS WAF is an application‑layer control: you can run it standalone (just attach a Web ACL) or let Shield Advanced manage it automatically for L7 DDoS response. Either way, WAF lives only at OSI Layer 7—transport‑layer and network‑layer threats are outside its scope and are countered by Shield Advanced or built‑in AWS edge protections.

### Patch & Configuration Compliance

Patch & Configuration Compliance is the “policy → scan → fix” subsystem of AWS Systems Manager (SSM).

1. **Patch Manager** – you define a Patch Baseline (which CVEs, which OS, auto‑approval rules, maintenance window). It then scans or installs patches on any managed node running the SSM Agent.

2. **Compliance** – continuously evaluates every node against patch baselines and against optional State Manager or Association documents (for example “CloudWatch Agent must run”). Results roll up to a single dashboard and can be aggregated across accounts/Regions via Quick Setup or AWS Organizations.

3. **Auto‑remediation (optional)** – when Compliance marks a resource NON_COMPLIANT, an EventBridge rule can trigger Run Command, State Manager or Automation to patch or re‑configure automatically.

**Use Cases**

- Org‑wide patch hygiene: One Patch Baseline that auto‑approves “Critical” CVEs after 3 days. Patch Manager scans nightly; the Compliance dashboard shows red/green across 200 accounts and 15 Regions.
- Config drift guardrail: State Manager document enforces that CloudWatch Agent and a custom IAM policy are present on every EC2; Compliance highlights any box where the agent was disabled and re‑enables it.
- Audit report: Every Monday, a Lambda calls the Compliance API, writes a CSV of NON_COMPLIANT instances to an S3 audit bucket, and notifies Slack.

**Exam Focus**

Look for verbs such as “report non‑patched instances across all accounts/Regions”, “auto‑remediate config drift”, “baseline approves patches after 7 days”. The correct answer almost always combines Patch Manager + Compliance, optionally with Run Command / State Manager / Automation for the “fix” step.

Q: The security officer needs a weekly organisation‑wide list of EC2 instances missing critical patches and wants them fixed automatically. Which Systems Manager features provide the MOST operationally efficient solution?
A: Use Patch Manager to define and scan a critical‑patch baseline, Compliance to surface NON_COMPLIANT nodes, and Run Command or State Manager associations triggered by EventBridge for remediation.

**Note:** Patch & Configuration Compliance treats “patch status” and “configuration drift” as data points evaluated against a declared policy. Patch Manager answers “What should be installed and when?”; Compliance answers “Is reality matching the policy?”; optional Automation tools enact “Bring it back into compliance.” Because results aggregate across accounts/Regions and export via API, DevOps teams spend their time setting a few baselines and remediation documents instead of building a patch‑orchestration pipeline from scratch.

### Attack‑Mitigation Playbook for Large‑Scale Web Applications

#### Edge Defence – CloudFront + AWS WAF Managed Rules

- CloudFront is AWS’s global CDN. It terminates TLS close to users, caches content, and absorbs traffic spikes.
- AWS WAF is a Layer‑7 firewall. Managed rule groups (SQLi, XSS, bot control, account‑takeover) inspect every request.
- Together they block common web exploits before traffic ever reaches the VPC origin.

**Typical Flow**

1. Client → nearest CloudFront Point‑of‑Presence (POP).
2. WAF managed rules evaluate the request.
3. Allowed traffic is served from cache or forwarded to the origin (ALB, S3, API Gateway).
4. Rejected requests are counted and optionally logged to CloudWatch → EventBridge for alerting.

**Exam Keywords**
“OWASP Top 10 at the edge”, “block bots in CloudFront”, “managed rule set”.

Q: A SaaS team must stop SQL‑injection and bot scraping at the edge with minimal rule writing. Which service pair fits?
A: CloudFront with AWS WAF managed rules

**Note:** Think of CloudFront as the castle wall and AWS WAF as the archers on that wall—malicious traffic is shot down outside the gate, saving origin capacity and developer effort.

#### DDoS Resilience – Shield Advanced + AWS Global Accelerator

- Shield Advanced auto‑mitigates volumetric L3/L4 floods and, since 2025, pushes WAF rules for L7 floods; includes 24×7 SRT and cost protection.
- Global Accelerator advertises two anycast IPs worldwide, health‑checks Regional endpoints, and steers traffic to the closest healthy Region.
- Together they deliver a single, attack‑resilient IP that fails over seamlessly.

**Typical Flow**

1. Users and attackers hit the anycast IP.
2. Shield drops malicious packets at AWS edge scrubbing centres.
3. Legitimate packets are routed by Global Accelerator to the healthiest ALB/API Gateway.

**Exam Keywords**
“Anycast IP + DDoS mitigation”, “fail‑over during regional attack”.

Sample Question
Q: A gaming platform wants one global IP that withstands L3–L7 DDoS attacks and auto‑fail‑overs between Regions. Which AWS combo?
A: Shield Advanced with AWS Global Accelerator

**Note:** Picture Global Accelerator as the front door and Shield Advanced as the riot police stationed outside; the door keeps opening, but only clean traffic makes it through.

#### Identity & Access – Amazon Cognito / IAM Identity Center + JWT Validation

- Cognito issues OIDC/OAuth tokens for customers; Identity Center handles workforce SSO and ABAC.
- Application Load Balancer (OIDC authentication action) or API Gateway (JWT authoriser) validates each JWT before forwarding.
- Together they externalise sign‑up/SSO while offloading token checks to the edge.

**Typical Flow**

1. User authenticates with Cognito/Identity Center → receives JWT.
2. JWT sent in Authorization header to ALB/API Gateway.
3. ALB/API Gateway verifies signature, expiry, claims; only valid requests reach microservices.

**Exam Keywords**
“JWT authoriser”, “OIDC authentication on ALB”, “central SSO with ABAC”.

Q: How do you reject expired JWTs without adding code to the microservice?
A: Configure an ALB OIDC authentication action (or API Gateway JWT authoriser) tied to Cognito/Identity Center.

**Note:** Think of Cognito/Identity Center as the passport office and ALB/API Gateway as the border guard—no valid passport, no entry.

#### Secret Management – AWS KMS + AWS Secrets Manager Rotation

- KMS holds the customer master keys (CMKs) and performs envelope encryption/decryption.
- Secrets Manager stores DB passwords, API keys, and rotates them automatically via Lambda.
- Together they eliminate hard‑coded credentials and provide full audit trails.

**Typical Flow**

1. App fetches secret (GetSecretValue); Secrets Manager decrypts payload with KMS.
2. Rotation Lambda creates a new DB password, updates the database, and writes the new version.
3. Old version is retained for rollback then retired.

**Exam Keywords**
“automatic secret rotation”, “KMS‑encrypted secret”, “no plain‑text in Git”.

Q: Compliance demands automatic rotation of RDS passwords every 30 days without downtime. Which service combo?
A: Secrets Manager rotation powered by KMS‑encrypted secrets

**Note:** KMS is the key vault; Secrets Manager is the butler who fetches keys on demand and changes the lock on schedule.

#### Observability & Automated Response – CloudWatch Logs / EventBridge + Security Lake / Security Hub

- CloudWatch Logs captures WAF, ALB, Lambda, and application logs; EventBridge routes real‑time events cross‑account (“the nerve system”).
- Security Lake ingests CloudTrail, VPC Flow Logs, S3 access logs into OCSF‑formatted S3 partitions; Security Hub deduplicates findings from GuardDuty, Inspector, Macie.
- Together they provide centralised log storage, analytics, and alert‑driven automation.

**Typical Flow**

1. Logs/alerts stream to CloudWatch; EventBridge forwards critical events to Slack, PagerDuty, or remediation Lambda.
2. Batched logs land in Security Lake for Athena/SIEM queries.
3. All security findings surface in Security Hub with severity scores.

**Exam Keywords**
“cross‑account event bus”, “OCSF log lake”, “single pane of glass for findings”.

Q: You must auto‑remediate WAF‑blocked IPs in every account and keep raw logs for threat hunting. Which services?
A: CloudWatch Logs + EventBridge for real‑time triggers, Security Lake for central log storage, Security Hub for finding aggregation.

**Note:** CloudWatch/EventBridge act as the central nervous system—feeling pain and firing reflexes—while Security Lake/Hub store the memory and provide a doctor’s dashboard.

| Pain Point                         | AWS Pair that Solves It                    |
| ---------------------------------- | ------------------------------------------ |
| Web exploits & bot abuse           | CloudFront + AWS WAF                       |
| Volumetric DDoS & regional outages | Shield Advanced + Global Accelerator       |
| Stateless, scalable authentication | Cognito / Identity Center + JWT validation |
| Secret sprawl & manual rotation    | KMS + Secrets Manager                      |
| Siloed logs & slow response        | CloudWatch/EventBridge + Security Lake/Hub |

## Task 2.4 - Design a strategy to meet reliability requirements

### 1. Highly Available Application Design

Building redundancy into every layer—compute, data, and networking—so the system keeps serving users even when an entire Availability Zone or Region experiences issues; ideal for customer‑facing workloads that demand near‑constant uptime such as e‑commerce sites, SaaS platforms, or critical internal tools, eliminating single points of failure and minimizing downtime.

#### Terminology / Technologies

- **Multi-AZ Deployments:** deploying services across multiple Availability Zones to achieve fault isolation and high availability;
- **Active-Active vs Active-Passive Topologies:** Active-Active means multiple nodes handle traffic simultaneously; Active-Passive means a primary node handles traffic while a standby node takes over upon failure;
- **Aurora Global Database:** Amazon Aurora feature that replicates data across regions with one primary region and multiple read-only secondary regions, enabling near real-time synchronization and disaster recovery;
- **S3 Cross-Region Replication:** automatically replicates S3 objects from one region’s bucket to another for cross-region redundancy;
- **ALB/NLB Cross-Zone Load Balancing:** distributes traffic evenly across targets in different Availability Zones to avoid overloading a single zone;
- **Auto Scaling Target Tracking:** automatically adjusts resource capacity based on predefined metrics (e.g., CPU utilization) to maintain desired performance levels;
- **RTO/RPO Targets:** RTO (Recovery Time Objective) is the maximum acceptable time to restore service after a failure; RPO (Recovery Point Objective) is the maximum acceptable duration of data loss in a disaster scenario;

#### System Design

**Availability Goal ↔ Resilience Scope**

- 99.99 % availability within a Region: choose Multi‑AZ; deploying across multiple AZs isolates single‑AZ failure and lets AWS handle automatic failover
- ≥ 99.999 % availability or geographic isolation required: choose Multi‑Region; cross‑Region replication and regional traffic routing keep service alive if an entire Region goes down

**RTO / RPO ↔ Data Replication Mechanism**

- Sub‑minute RTO / RPO: Aurora Global Database; asynchronous replication lag < 1 s with rapid primary failover
- RTO < 1 h, RPO minutes: Warm Standby; continuous replication and pre‑warmed core resources shorten recovery time
- RTO hours, RPO hours: Pilot‑Light or backup‑and‑restore; only minimal core components stay running, other services start on demand to save cost

**Budget Constraint ↔ Compute Topology**

- Ample budget and need for horizontal scale: Active‑Active; all Region/AZ nodes receive traffic concurrently, avoiding bottlenecks
- Moderate budget and need quick switchover: Active‑Passive; primary handles traffic, standby is hot and takes over automatically on failure
- Limited budget and relaxed recovery time: Cold Standby or data‑only backups; compute resources start manually or automatically after an incident to minimize daily spend

#### Sample Question

Q1: An application needs 99.99 % availability in one Region, RTO ≤ 15 min, RPO ≤ 15 min, and the budget allows a small amount of idle capacity
A1: Multi‑AZ + Warm Standby

Q2: A global e‑commerce platform must keep RTO ≈ 1 min and RPO ≈ 1 min during a Region‑wide disaster while maintaining read/write capability
A2: Aurora Global Database + Active‑Active multi‑Region deployment

### 2. Design for Failure

Engineering under the assumption that components will inevitably break by injecting faults, adding graceful retry logic, and isolating blast radius; suited to complex distributed systems where transient errors, network partitions, or cascading failures are common, ensuring the application degrades gracefully and recovers automatically without manual intervention.

#### Terminology / Technologies

- **Chaos Engineering (AWS Fault Injection Simulator):** deliberately injects faults into production‑like environments to confirm system resilience;
- **Retries with Back‑off and Jitter:** re‑attempts failed requests using exponential delays plus random jitter to prevent synchronized retries;
- **Idempotent Operations:** operations that can be repeated safely because multiple executions yield the same end state;
- **Circuit Breakers:** monitors call failures and opens to reject further calls until the downstream service recovers;
- **Bulkheads:** partitions resources so failure in one compartment does not cascade to others;
- **RDS/Aurora Automatic Failover:** promotes a standby database instance when the primary becomes unavailable, reducing recovery time;
- **ElastiCache Global Datastore:** replicates Redis data across Regions and can promote a secondary cluster during Regional failures;

#### System Design

**Failure Anticipation ↔ Chaos Testing**

Inject CPU, network, or AZ outages with AWS Fault Injection Simulator; validate alarms and recovery playbooks to surface hidden dependencies

**Transient Fault Handling ↔ Retry and Timeout Policy**

Use exponential back‑off with full jitter in retries; keep calls idempotent to prevent state corruption when duplicates occur

**Persistent Fault Handling ↔ Isolation and Failover**

Apply circuit breakers and bulkheads to localize impact; enable automatic database or cache failover so traffic routes to healthy replicas without manual action

#### Sample Question

Q1: A microservice occasionally receives 500 errors from an external payment API; the business must avoid duplicate charges and keep latency low
A1: Idempotent operations with exponential back‑off and jitter

Q2: A global retail site must verify that its multi‑tier architecture withstands an Availability‑Zone network black‑hole without manual intervention
A2: Chaos engineering using AWS Fault Injection Simulator plus Multi‑AZ automatic database failover and circuit breakers

### 3. Loosely Coupled Dependencies

Decoupling microservices and event producers through asynchronous messaging and event buses so each part can scale, deploy, or fail independently; perfect for microservice architectures, data pipelines, and bursty workloads, solving tight coupling problems that otherwise cause back‑pressure, lock‑step scaling, or cross‑service outages.

#### Terminology / Technologies

- **SNS fan‑out to SQS:** publishing a single message to an SNS topic that delivers copies to multiple SQS queues, enabling parallel processing;
- **FIFO vs Standard Queues:** FIFO queues preserve strict order and guarantee exactly‑once processing; Standard queues offer at‑least‑once delivery with best‑effort ordering but higher throughput;
- **Dead‑Letter Queues (DLQ):** secondary queues that store messages that could not be processed after the maximum retry count, isolating poison messages for later analysis;
- **AWS Step Functions Orchestration:** serverless workflow service that coordinates distributed components with retries, parallel branches, and timeout handling;
- **EventBridge Buses:** event router that receives, filters, and delivers events to multiple targets across AWS accounts and services without tight coupling;
- **Lambda Pollers:** AWS‑managed pollers that automatically retrieve messages from SQS and invoke Lambda functions, scaling concurrency with queue depth;

#### System Design

**Ordering / Exactly‑Once ↔ Queue Type**

Use FIFO SQS with content‑based deduplication for strict order and exactly‑once delivery; employ message groups if parallelism with ordered subsets is needed

**Error Isolation ↔ Dead‑Letter Handling**

Attach DLQs to SQS, Lambda, or Step Functions to divert poison messages after retry limits; monitor DLQ size with CloudWatch alarms to trigger remediation workflows

**Independent Scaling ↔ Event‑Driven Fan‑out**

Combine SNS fan‑out or EventBridge buses with multiple SQS queues so each microservice scales independently; Lambda pollers auto‑scale with incoming messages, and Step Functions orchestrate long‑running or multi‑step transactions without blocking upstream producers

#### Sample Question

Q1: A workload must process orders in the exact sequence received and ensure each order is handled only once
A1: Use an SQS FIFO queue with content‑based deduplication

Q2: A payment microservice occasionally receives malformed events that break JSON parsing and block the queue; the team must isolate these bad messages without affecting healthy traffic
A2: Configure an SQS dead‑letter queue and route messages there after the maximum retry attempts

### 4. Operate & Maintain Highly Available Systems

Ensuring a live system stays healthy after go‑live by automating failover checks, managing seamless rollouts, and scheduling maintenance so updates never violate uptime targets; critical for production workloads that must evolve continuously—patches, schema changes, traffic shifts—without introducing new single points of failure or extended outages.

#### Terminology / Technologies

- **Multi‑AZ Failover Health Checks:** continuous probes that detect primary‑instance failure and trigger automatic promotion within the same Region;
- **Cross‑Region Replica Promotion Times:** measured duration to elevate a read replica in another Region to primary, used to validate RTO targets;
- **Aurora Failover Tiers:** priority levels that define which replica becomes the new writer during an Aurora cluster failover;
- **Auto Scaling Instance Refresh:** rolling replacement of EC2 instances in an Auto Scaling group with the latest AMI while preserving capacity;
- **Blue/Green and Canary Deployments:** traffic‑shifting strategies that direct a subset of users to new code to verify stability before full cutover;
- **Staggered Patch Windows:** offset maintenance windows across instances or AZs so only a fraction of the fleet is updated at any time;

#### System Design

**Fault Detection ↔ Health Check Hierarchy**

Use layered health checks—ELB target health, Auto Scaling EC2 status, database replication lag—to trigger Multi‑AZ or Aurora failovers quickly and avoid sending traffic to unhealthy nodes

**Zero‑Downtime Updates ↔ Progressive Deployment**

Combine blue/green or canary strategies with Auto Scaling instance refresh to roll out AMI or configuration changes without dropping connections; monitor key metrics and roll back if error rates rise

**Maintenance Continuity ↔ Staggered Windows & Replica Promotion**

Schedule staggered patch windows across AZs and Regions so at least one healthy replica or instance group is always online; validate cross‑Region promotion time to ensure it meets business RTO during planned or unplanned events

#### Sample Question

Q1: A production Aurora cluster must promote a standby writer in under 30 seconds when the primary fails; which configuration ensures this target is met?
A1: Assign the highest failover tier (tier 0) to the preferred replica and enable Aurora automated monitoring health checks

Q2: A company needs to roll out a security patch to hundreds of EC2 instances without affecting live traffic; which approach satisfies this requirement?
A2: Use Auto Scaling instance refresh with a blue/green deployment strategy and verify health checks before shifting 100 % traffic to the new instances

Q3: During maintenance, one Availability Zone must stay fully operational while the other is patched; how should the patch schedule be arranged?
A3: Apply staggered patch windows so each AZ is updated at a different time, ensuring continuous capacity across the Region

### 5. Managed Highly Available Services

Leveraging fully managed AWS offerings that embed high availability, replication, and fail‑in routing so you don’t have to build or operate clusters yourself; ideal when the goal is to meet strict replication‑lag or uptime targets with the lowest operational burden—letting AWS handle scaling, patching, and cross‑Region traffic steering while you focus on business logic.

#### Terminology / Technologies

**DynamoDB Global Tables:** multi‑Region, multi‑active NoSQL replication with single‑digit‑millisecond latency and ≤ 1 s cross‑Region lag;
**S3 Standard:** durable (11 nines) object storage automatically replicated across three AZs in one Region;
**EFS Standard:** regional NFS file system that stores data redundantly across multiple AZs and scales to petabytes without manual provisioning;
**Kinesis Enhanced Fan‑out:** dedicated throughput pipes (up to 2 MB/s per consumer) that eliminate consumer‑level throttling on data streams;
**Global Accelerator:** AnyCast edge network that directs users to the closest healthy AWS endpoint and instantaneously shifts traffic on failure;
**Elastic Load Balancing (ALB/NLB):** managed layer 7/4 load balancers with cross‑Zone failover and health checks—no self‑managed HA proxy layer required;

#### System Design

**Operational Simplicity ↔ Managed Option**

Replace self‑built clusters with DynamoDB Global Tables, S3 Standard, or EFS Standard to offload patching, scaling, and replication tasks to AWS

**Replication & Consistency ↔ Built‑in HA Features**

Use services whose default behavior meets RTO/RPO—e.g., DynamoDB global tables for sub‑second multi‑Region writes, ELB cross‑Zone routing for AZ resilience

**Global Performance ↔ Edge Routing & Stream Throughput**

Adopt Global Accelerator for low‑latency routing to the nearest healthy Region and Kinesis enhanced fan‑out to guarantee consistent consumer throughput without tuning shards

#### Sample Question

Q1: A gaming backend needs < 1 second cross‑Region data replication with minimal operational overhead; which service meets this requirement?
A1: DynamoDB Global Tables

Q2: A video analytics pipeline requires each consumer to read up to 2 MB/s from the same stream without throttling or shard rebalancing; which managed feature should be used?
A2: Kinesis Enhanced Fan‑out

### 6. DNS Routing Policies

Directing user traffic at the DNS layer with policy‑based decision logic—latency, geography, failover status, or traffic shifting—so clients reach the optimal endpoint without changing application code; ideal for global services that need low latency delivery, jurisdiction‑aware routing, disaster recovery cut‑over, or controlled blue/green rollouts while AWS Route 53 handles resolution and health checks.

#### Terminology / Technologies

- **Route 53 Simple Routing:** returns one record set for a domain, suitable for single‑endpoint workloads;
- **Weighted Routing:** splits traffic across multiple records using adjustable weights, supporting blue/green or canary releases;
- **Latency‑Based Routing:** routes each client to the Region with the lowest observed latency to that user’s DNS resolver;
- **Failover Routing:** designates primary and secondary records, automatically switching to the secondary when Route 53 health checks detect the primary is unhealthy;
- **Geolocation Routing:** directs users based on the country or continent of their originating IP address, useful for data sovereignty or localized content;
- **Geoproximity Routing:** uses Route 53 Traffic Flow to shift traffic toward or away from resources based on geographic distance and optional bias, handy for gradual Region migrations;
- **Health Checks:** automated probes (HTTP, HTTPS, TCP) that mark a record healthy or unhealthy for failover decisions;
- **Alias A Records:** special Route 53 records that map a DNS name to AWS resources (ELB, CloudFront, S3, etc.) without extra cost or DNS lookups;

#### System Design

**Latency Optimization ↔ Latency‑Based Routing**

Deploy identical endpoints in multiple Regions; Route 53 returns the IP of the Region with the lowest latency to each user, reducing round‑trip time without additional application logic

**Jurisdiction Compliance ↔ Geo‑Aware Policies**

Use Geolocation routing to keep EU traffic within EU data centers for GDPR compliance; apply Geoproximity with bias to gradually shift traffic from an old Region to a new one during migrations

**Disaster Recovery & Traffic Shifting ↔ Failover / Weighted**

Combine Failover routing with health checks to cut over from primary to secondary Region automatically during outages; apply Weighted routing (e.g., 90/10, 50/50) for blue/green deployments, increasing weight on the new version as it proves stable

#### Sample Question

Q1: A worldwide API must ensure each client hits the Region with the shortest network latency while falling back to another Region if its endpoint becomes unhealthy
A1: Use Latency‑Based routing for primary selection combined with Route 53 health checks and Failover routing for automatic Regional failover

Q2: A company needs to route Canadian users to a data center in Toronto for data residency, while the rest of the world continues to use the US Region
A2: Configure a Geolocation routing policy with a rule for the CA country code pointing to the Toronto endpoint and a default rule pointing to the US endpoint

## Task 2.5: Design a solution to meet performance objectives

### 1. Large‑Scale Access Patterns

Designing data and traffic flows so that high‑volume, uneven, or bursty workloads remain low‑latency and scalable; common in systems facing “hot keys,” spikes in writes, or globally distributed reads, where smart partitioning, buffering, and edge caching prevent throttling and keep performance predictable.

#### Terminology / Technologies

- **Partitioning / Sharding:** distributing data or traffic across keys or shards (e.g., DynamoDB partition keys, Kinesis shards) to spread load evenly;
- **Read / Write Separation:** offloading reads to Aurora reader endpoints or RDS read replicas so the writer is not overloaded;
- **Batching and Parallelism:** grouping events for efficient processing and using SQS, Kinesis, and Lambda concurrency to process in parallel;
- **CDN Edge Delivery (CloudFront):** caching static and dynamic content at global edge locations to minimize origin load and latency;
- **API Gateway Throttling / Caching:** enforcing rate limits per client and caching responses at the API edge layer to shield backends from bursts;

#### System Design

**Hot Key Mitigation ↔ Partition Strategy**

Choose high‑cardinality partition keys or add random suffixes/salt to spread “hot” traffic; pre‑split Kinesis shards or use on‑demand scaling to prevent shard hotspots

**Read Scalability ↔ Replicas and Edge Caches**

Add Aurora reader endpoints or RDS read replicas for heavy read workloads; push frequently accessed content to CloudFront to reduce round trips to the origin

**Burst Write Handling ↔ Streaming / Buffering Layer**

Insert SQS or Kinesis between producers and consumers to smooth write spikes; process in batches with Lambda or consumer fleets that scale with queue depth

**Latency & Backend Protection ↔ Throttling and Caching**

Apply API Gateway throttling to prevent client floods; enable API Gateway or CloudFront caching to return cached responses quickly and cut load on downstream services

#### Sample Question

Q1: A DynamoDB table experiences “hot key” access during flash sales, causing throttling; which approach solves the issue without major schema changes?
A1: Introduce a partition key sharding strategy (e.g., random suffixes) to distribute writes evenly across partitions

Q2: A read‑heavy reporting workload is overloading the primary RDS instance; how can you scale reads without affecting writes?
A2: Add RDS read replicas or use the Aurora reader endpoint to offload read traffic

Q3: A mobile game sends bursty telemetry data that overwhelms the backend; what should you implement to absorb and process these spikes efficiently?
A3: Use Kinesis (or SQS) as a buffering layer and process records in batches with Lambda concurrency scaling

### 2. Elastic Architecture Design

Designing systems that expand and contract capacity automatically to match demand, maintaining SLA targets without paying for idle resources; ideal for workloads with diurnal peaks, unpredictable bursts, or seasonal patterns where each component should scale on its own metrics rather than as a monolith.

#### Terminology / Technologies

- **EC2 Auto Scaling (target-tracking, step, scheduled):** automatically adjusts EC2 instance counts using metric targets, threshold steps, or time-based schedules;

- **DynamoDB On-Demand / Auto Scaling:** capacity modes that either scale transparently per request or adjust provisioned throughput based on traffic trends;

- **Lambda Reserved & Provisioned Concurrency:** controls to guarantee function concurrency or pre-warm execution environments to avoid cold starts;

- **ECS/EKS Cluster Auto Scaling:** automatically adds or removes container hosts (EC2 or Fargate capacity providers) in response to pending tasks or pod scheduling;

- **Application Auto Scaling (for Kinesis, EMR, etc.):** unified scaling service that applies scaling policies to non-EC2 resources such as stream shards or EMR task nodes;

#### System Design

**Demand Pattern ↔ Scaling Policy Type**

Use target-tracking to keep a steady metric (e.g., 60% CPU) for variable traffic; pick step scaling when you need discrete jumps at threshold breaks; rely on scheduled scaling for predictable spikes, such as daily batch loads

**Cost Efficiency ↔ Capacity Mode**

Prefer serverless or on-demand modes (Lambda, DynamoDB On-Demand) for unpredictable or spiky workloads; switch to provisioned capacity with auto scaling when you have steady baselines and want cost control with throttling guarantees

**Latency & Cold Starts ↔ Concurrency Controls**

Apply Lambda reserved or provisioned concurrency to guarantee consistent latency during bursts; pre-scale ECS tasks or keep minimum EC2 instances online if startup time would violate SLA

**Component Independence ↔ Scaling Boundaries**

Ensure each microservice or data pipeline scales on its own metrics; separate read/write scaling (e.g., Kinesis shard count vs consumer concurrency) so one bottleneck does not force global overprovisioning

#### Sample Question

Q1: A retail app has unpredictable spikes and must maintain 200 ms API latency without paying for idle servers overnight; which approach should you take?
A1: Use Lambda with provisioned concurrency for latency guarantees and DynamoDB On-Demand to handle bursty traffic without preprovisioning

Q2: A reporting job runs every weekday at 9 AM, doubling compute needs for one hour; how do you scale efficiently?
A2: Configure scheduled scaling on the EC2 Auto Scaling group (or EMR task nodes via Application Auto Scaling) to add capacity just before 9 AM and scale back after the job

Q3: A streaming pipeline must increase shard count when incoming records exceed current throughput, but other components should remain unaffected; what should you implement?
A3: Use Application Auto Scaling on Kinesis stream shards with a target-tracking policy so shard scaling is independent of downstream consumer scaling

### 3. Caching & Buffering Patterns

Using in-memory caches, edge caches, and message buffers to cut read/write latency and smooth burst traffic; ideal when hotspots or sudden spikes would overwhelm databases or downstream services, ensuring fast responses for frequently accessed data and controlled ingestion for high-volume writes.

#### Terminology / Technologies

- **ElastiCache (Redis / Memcached):** in-memory data store for sub-millisecond reads; Redis supports persistence and advanced data structures, Memcached is simple key-value with no persistence;
- **DynamoDB DAX:** fully managed in-memory cache for DynamoDB that accelerates read-heavy and hot-key workloads with microsecond latency;
- **CloudFront:** global CDN that caches static and dynamic content at edge locations to reduce origin load and latency;
- **API Gateway Caching:** response caching at the API edge to lower backend calls and improve request latency;
- **RDS / Aurora Read Replicas:** database replicas dedicated to read traffic, offloading reads from the primary and reducing contention;
- **SQS / Kinesis Buffers:** message queues and streaming services that absorb bursty writes and decouple producers from consumers;
- **SNS Fan-out to SQS:** publishes one message to SNS and delivers copies to multiple SQS queues so consumers can process independently;

#### System Design

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

#### Sample Question

Q1: An app experiences read latency spikes on frequently accessed DynamoDB items during sales events; how do you reduce latency without redesigning the table?
A1: Add DynamoDB DAX to cache hot keys and serve microsecond reads

Q2: A media portal must serve global users with low latency for static assets and offload origin servers; what should you implement?
A2: Use CloudFront to cache static content at edge locations

Q3: A telemetry system receives bursty write traffic that overwhelms the database; how can you prevent throttling and maintain resiliency?
A3: Insert SQS or Kinesis as a buffering layer and process records in batches with scalable consumers

### 4. Purpose‑Built Service Selection

Choosing the right managed database, storage, and monitoring tool for a specific data access pattern—time‑series ingestion, graph traversal, full‑text search, ledger integrity—so performance, cost, and operational effort align with business needs; this avoids forcing one engine to do everything and reduces bottlenecks, while dedicated monitoring tools expose root causes quickly.

#### Terminology / Technologies

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

#### System Design

**Access Pattern ↔ Engine Selection**

Pick the engine built for the query shape: time‑series → Timestream; graph traversal → Neptune; full‑text search → OpenSearch; ledger integrity → QLDB; key‑value at scale → DynamoDB; standard OLTP/SQL joins → Aurora/RDS

**Data Structure & Consistency ↔ Storage/DB Model**

Semi‑structured JSON → DocumentDB; wide‑column high throughput → Keyspaces; immutable audit logs → QLDB; strong relational integrity (transactions, joins) → Aurora/RDS

**Throughput / Latency Needs ↔ Storage Tier**

High IOPS block workloads → EBS io2; cost‑efficient block → gp3; ephemeral scratch space → Instance Store; shared POSIX file system → EFS or FSx families; object archival or static files → S3

**Bottleneck Visibility ↔ Monitoring & Tracing**

Use CloudWatch Metrics/Alarms for thresholds, Performance Insights to diagnose slow SQL, X‑Ray to trace end‑to‑end latency, and CloudWatch Logs/RUM/Synthetics to surface application or client‑side delays

#### Sample Question

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

#### Terminology / Technologies

- **Instance Families (M/T general; C compute‑optimized; R/X memory‑optimized; I storage‑optimized; P/G/Trn accelerated):** categorized EC2 types tuned for balanced, CPU‑heavy, memory‑heavy, storage‑intensive, or GPU/accelerator workloads respectively;
- **EBS Volume Types and IOPS:** gp3 provides baseline performance with configurable IOPS and throughput at lower cost; io2/io2 Block Express deliver high, consistent IOPS for mission‑critical databases;
- **Graviton vs x86:** ARM‑based Graviton instances offer better price/performance for many workloads but may require architecture compatibility checks; x86 instances support broader legacy binaries;
- **AWS Compute Optimizer:** service that analyzes historical usage (CPU, memory, network) to recommend optimal instance types and sizes;
- **Cost Explorer Rightsizing:** tool in AWS Billing to identify underutilized EC2, RDS, and other resources and suggest downsizing or termination;
- **Burstable / On‑Demand Capacity (T instances, Fargate/Lambda):** pay‑for‑use options or credit‑based burst capacity to avoid paying for idle baseline;
- **gp3 vs io2 for Storage:** gp3 offers flexible IOPS cost‑effectively; io2 is for sustained, high IOPS needs with SLA guarantees;

#### System Design

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

#### Sample Question

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

#### Terminology / Technologies

- **AWS Compute Optimizer:** analyzes historical utilization (CPU, memory, network) and recommends better‑fit instance types or sizes;
- **Cost Explorer Resource Optimization:** identifies underutilized EC2/RDS resources and suggests downsizing or termination;
- **S3 Storage Lens:** organization‑wide visibility into S3 usage, costs, and data access patterns for lifecycle and tiering decisions;
- **gp3 vs io2 EBS:** gp3 offers cost‑efficient, adjustable IOPS/throughput; io2 provides high, consistent IOPS and durability for critical workloads;
- **Graviton Instances:** ARM‑based EC2 types with improved price/performance but require software compatibility checks;
- **Spot Fleets:** discounted EC2 capacity subject to interruption, suited for fault‑tolerant or stateless workloads;
- **Instance Families (M/T/C/R/X/I/P/G/Trn):** general purpose, burstable, compute‑optimized, memory‑optimized, storage‑optimized, accelerated (GPU/ML) categories to align hardware to workload needs;
- **Serverless / On‑Demand vs Provisioned Capacity:** pay‑per‑use options (Lambda, Fargate, DynamoDB On‑Demand) vs pre‑allocated resources (EC2, provisioned DynamoDB) to balance cost with predictability;

#### System Design

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

#### Sample Question

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

#### Terminology / Technologies

- **Reserved Instances (Standard vs Convertible):** Standard RIs lock instance family/region/OS for maximum discount; Convertible RIs allow exchange for different instance families while still offering significant savings;
- **Savings Plans (Compute / EC2 Instance / SageMaker):** flexible commitment models; Compute SP applies to any compute (EC2, Fargate, Lambda), EC2 Instance SP targets specific instance families/regions, SageMaker SP is for ML workloads;
- **Spot Instances:** spare EC2 capacity at steep discounts, interruptible with two‑minute notice, suitable for stateless, batch, or fault‑tolerant workloads;
- **On‑Demand:** pay‑as‑you‑go pricing with no commitment, ideal for unpredictable or short‑term workloads;
- **Committed Term Lengths (1‑year / 3‑year):** longer terms offer higher discounts but reduce flexibility;
- **Payment Options (No Upfront / Partial Upfront / All Upfront):** increasing upfront payment yields higher effective savings;
- **Mixing Purchase Models:** blending baseline RIs/SP with Spot for burst capacity or dev/test tiers to optimize overall cost;

#### System Design

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

#### Sample Question

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

#### Terminology / Technologies

- **Inter‑AZ / Inter‑Region Transfer Pricing:** data sent between AZs or Regions is billed; same‑AZ traffic is usually free or cheaper, while cross‑Region replication is often the most expensive path;
- **PrivateLink / VPC Endpoints (Interface & Gateway):** private connections to AWS services or third‑party SaaS over the AWS network; interface endpoints (ENI‑based) vs gateway endpoints (S3/DynamoDB only, free data path within Region);
- **CloudFront for Egress Offload:** CDN caching that serves content from edge locations, reducing origin egress and lowering internet data transfer costs;
- **S3 Transfer Acceleration vs Standard PUT/GET:** accelerated uploads/downloads via edge locations for long‑distance transfers; standard operations are cheaper if latency is acceptable;
- **Direct Connect vs Internet Egress:** dedicated private link to AWS with predictable bandwidth pricing vs variable internet egress charges;
- **NAT Gateway vs NAT Instance Costs:** managed NAT gateways charge per GB processed and per hour; NAT instances can be cheaper at scale but require management;
- **Data Transfer Monitoring & Tagging:** using Cost Explorer, CUR, and tagging to attribute transfer costs and identify hotspots;

#### System Design

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

#### Sample Question

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

#### Terminology / Technologies

- **AWS Budgets:** set custom cost or usage thresholds and trigger alerts (email/SNS) when limits are approached or exceeded;
- **Cost Explorer:** analyze historical spend and usage trends with filtering/grouping (by service, tag, account) for optimization insights;
- **Cost & Usage Report (CUR):** detailed, hourly-level billing data delivered to S3 for advanced analytics (Athena/QuickSight);
- **Trusted Advisor Cost Checks:** automated recommendations for underutilized resources, idle load balancers, low EBS usage, etc.;
- **Cost Anomaly Detection:** ML-based detection of unusual spend patterns with SNS notifications;
- **Tagging / Cost Categories:** enforce metadata on resources for chargeback/showback, and group costs logically (departments, projects);
- **Service Control Policies (SCPs) & Guardrails:** organization-wide policies to restrict actions that could incur unexpected costs;
- **AWS Pricing Calculator:** estimate and forecast monthly costs for architectures before deployment;

#### System Design

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

#### Sample Question

Q1: A team’s monthly costs suddenly spike without explanation; which AWS service can automatically detect and alert on this anomaly?  
A1: Cost Anomaly Detection with SNS notifications

Q2: Finance wants to allocate costs to departments based on usage; how do you implement this with AWS-native tools?  
A2: Enforce resource tagging and use Cost Categories to group and report spend per department

Q3: A project owner needs an alert when forecasted monthly costs exceed a set threshold; what should you configure?  
A3: AWS Budgets with a cost threshold and SNS/email alerts

Q4: An architect must provide an upfront cost estimate for a new multi-tier web application; which tool is best suited?  
A4: AWS Pricing Calculator for pre-deployment cost forecasting
