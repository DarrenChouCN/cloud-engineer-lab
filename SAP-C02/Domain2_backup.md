# Content Domain 2: Design for New Solutions

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
