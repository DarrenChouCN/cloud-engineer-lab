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
