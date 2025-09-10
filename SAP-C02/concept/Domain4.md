# Content Domain 4: Accelerate Workload Migration and Modernization

## Task 4.1: Select existing workloads and processes for potential migration

### 1. Migration Assessment

Creating a **data-driven portfolio assessment** so you know _what_ to move, _how_ to sequence it, and _which 7 R_ strategy (Rehost, Replatform, etc.) fits each application. This module covers the discovery tools that inventory servers, map dependencies, and generate wave plans—plus the services that let you refactor incrementally once migration begins.

- **AWS Migration Hub Strategy Recommendations:** analyzes application binaries, databases, and usage metrics to recommend the optimal 7 R path; exports detailed wave plans;
- **Application Discovery Service (ADS) Agents / Collector:** installs on-prem to gather CPU, memory, network, and process-level dependency data; feeds Migration Hub dashboards;
- **AWS Migration Hub Refactor Spaces:** scaffolds a _strangler-fig_ pattern—creating proxies, routing rules, and service groups so you can carve out micro-services while tracking migration waves;
- **Migration Evaluator (formerly TSO Logic):** ingests inventory + licensing data to build right-sized cost models (On-Demand, RI, Savings Plans) and break-even charts for every server;
- **Migration Hub Workloads & Wave Planning:** central console to group servers into waves, assign owners, and monitor progress across accounts/Regions.

**Inventory & Dependency Mapping ↔ ADS + Migration Hub**

“Need a complete list of servers and their inter-app calls” → Deploy **Application Discovery Service agents** feeding **Migration Hub** dashboards.

**7 R Path Recommendation ↔ Strategy Recommendations**

“Which applications should be replatformed vs. refactored?” → Run **Migration Hub Strategy Recommendations** for automated guidance.

**Cost & Licensing Model ↔ Migration Evaluator**

“Finance wants a TCO report for 300 Windows VMs” → Use **Migration Evaluator** to generate cost/licensing comparisons.

**Incremental Micro-service Carve-Out ↔ Refactor Spaces**

“Refactor monolith gradually without downtime” → Use **Migration Hub Refactor Spaces** to create routing proxies and track new services.

**Wave Planning & Tracking ↔ Migration Hub**

“Organize 500 VMs into three waves and view cut-over status” → Build **Wave Plans** in **Migration Hub Workloads**.

Q1: A migration team must inventory all on-prem servers, capture CPU/IO metrics, and discover application dependencies. Which AWS service/agent solves this first step?  
A1: **Application Discovery Service** (agents or network-based collector).

Q2: After discovery, you need an automated report recommending whether each workload should be rehosted, replatformed, or refactored. Which tool provides this 7 R assessment?  
A2: **AWS Migration Hub Strategy Recommendations**.

Q3: Finance requests a cost comparison between current VMware licensing and three-year RI pricing on AWS. Which service produces this analysis?  
A3: **Migration Evaluator** (formerly TSO Logic).

Q4: The architecture team wants to peel a single checkout function out of a monolith while routing only that traffic to a new Lambda service. How can you manage this refactor?  
A4: Use **Migration Hub Refactor Spaces** to create a service group and routing rules.

Q5: Project managers need a dashboard that shows which servers belong to “Wave 2” and their real-time migration status. Where do they configure and monitor this?  
A5: In **AWS Migration Hub** Workloads/Wave Planning console.

Q6: During discovery you find a legacy Oracle DB tightly coupled to a Java app. Strategy Recommendations suggests “Replatform.” What AWS migration pattern would that imply?  
A6: Migrate the DB to **Amazon RDS for Oracle** (or Aurora), and move the Java app to **EC2 / Elastic Beanstalk** with minimal code changes—i.e., _Replatform_.

### 2. 7 R Strategy Evaluation

Choosing the **right migration pattern** for each application—balancing speed, cost, licensing, and long-term agility. The “7 Rs” framework ranks every workload across **Retire, Retain, Rehost, Replatform, Repurchase, Refactor, Relocate**; Strategy Recommendations in Migration Hub automates this ranking and links each choice to the supporting AWS service.

- **Retire:** decommission obsolete apps or servers; free up budget and reduce attack surface (no AWS service required, but tracked in Migration Hub);
- **Retain (“Revisit Later”):** keep on-prem for compliance or contractual lock-in; still inventory in **Application Discovery Service** to revisit annually;
- **Rehost (Lift & Shift):** migrate as-is with **AWS Application Migration Service (MGN)**; minimal changes, fastest path to cloud exit;
- **Replatform (“Lift, Tweak & Shift”):** minor optimizations—e.g., move Oracle → **Aurora I/O-Optimized**, or Windows IIS → **Elastic Beanstalk**; often uses **AWS Database Migration Service (DMS)**;
- **Repurchase (Drop & Shop):** replace with SaaS such as **Workday, Salesforce, or Amazon Connect**; frees licensing/maintenance burden;
- **Refactor / Re-architect:** rewrite into **Lambda / Fargate / EKS** micro-services; coordinated with **Migration Hub Refactor Spaces** for routing and wave tracking;
- **Relocate:** move VMware vSphere clusters intact to **VMware Cloud on AWS** with **HCX**, preserving tools and skills while reducing data-center footprint;
- **Migration Hub Strategy Recommendations:** scans code, databases, and utilization to rank each workload against these 7 Rs and generate wave plans.

**Fast Data-Center Exit ↔ Rehost**

“Exit in <90 days, minimal code change” → **Rehost with AWS MGN**.

**License Cost Reduction ↔ Repurchase**

“Oracle E-Business Suite costly; SaaS alternative OK” → **Repurchase** with SaaS (e.g., **NetSuite**).

**Limited Downtime Budget ↔ Replatform**

“Accept <15 min outage, want managed DB” → **Replatform to Amazon RDS/Aurora** via **DMS**.

**Agility & Long-Term TCO ↔ Refactor**

“Need faster releases, event-driven scale” → **Refactor onto Lambda / containers** with **Refactor Spaces**.

**Compliance Holdover ↔ Retain**

“Must stay on-prem until audit cycle ends” → **Retain** (mark for future review).

**End-of-Life App ↔ Retire**

“Legacy reporting server unused for 6 months” → **Retire**.

**Data-Center Consolidation, Keep VMware ↔ Relocate**

“vSphere skills strong, no refactor budget” → **Relocate** to **VMware Cloud on AWS** with **HCX**.

Q1: A company must vacate its colo in 60 days and lacks refactor budget. Which migration pattern and AWS service are most appropriate?  
A1: **Rehost** using **AWS Application Migration Service (MGN)**.

Q2: Finance demands elimination of perpetual Oracle licenses and supports moving to a managed equivalent with minimal code edits. Which “R” fits?  
A2: **Replatform**—migrate Oracle to **Amazon Aurora I/O-Optimized** via **DMS**.

Q3: An HR system is being replaced by Workday SaaS next quarter. How should this be classified under the 7 Rs?  
A3: **Repurchase** (move to SaaS).

Q4: A monolithic Java app needs near-zero downtime, auto-scaling, and weekly feature releases. Which migration path is recommended?  
A4: **Refactor** onto **AWS Lambda / Fargate** using **Migration Hub Refactor Spaces**.

Q5: A regulatory system must remain on-prem due to data sovereignty laws for at least two more years. What is the correct 7 R classification?  
A5: **Retain**.

Q6: Hundreds of idle legacy servers serve no active users but still incur maintenance. What should you do?  
A6: **Retire** those workloads.

Q7: Executives want to keep vSphere tooling yet exit the data center. Which 7 R and AWS offering meet this requirement?  
A7: **Relocate** the workloads to **VMware Cloud on AWS** using **HCX** for seamless migration.

### 3. TCO Analysis

Building a **data-backed business case** that compares on-prem costs to AWS—factoring licensing, rightsizing, and even carbon impact. This module shows how to quantify savings per VM, size the right EC2/Graviton targets, and present an executive-ready summary that highlights both money _and_ sustainability wins.

- **Migration Evaluator (formerly TSO Logic):** ingests server inventory and licensing data to create per-VM cost models for On-Demand, RI, Savings Plans, and license portability; exports Executive Summary and detailed line-item sheets.
- **AWS TCO Calculator (2025 refresh):** now integrates **Customer Carbon Footprint Tool v2.0** results—showing projected carbon-reduction alongside three-year TCO comparisons.
- **Customer Carbon Footprint Tool v2.0:** supplies verified emissions data by Region, feeding into the refreshed TCO Calculator for sustainability KPIs.
- **AWS Compute Optimizer cross-platform rightsizing:** analyzes current x86 workloads and recommends optimal **Graviton** targets (c7g, m7g, etc.) with cost-savings estimates, enabling pre-migration sizing accuracy.
- **Optimization & Licensing Assessment (OLA):** optional module of Migration Evaluator that models BYOL vs. AWS-provided licensing to maximize savings.

**Per-VM Cost Model ↔ Migration Evaluator**

“Need line-item analysis with license portability” → Use **Migration Evaluator** + **OLA** for detailed TCO and licensing scenarios.

**Executive Sustainability KPI ↔ TCO Calculator + CCFT v2.0**

“Board demands carbon-reduction figures with cost report” → Run **TCO Calculator 2025** which embeds **Carbon Footprint Tool v2.0** metrics.

**Rightsizing & Graviton Savings ↔ Compute Optimizer**

“Want to show 20–40 % cost cut by moving to ARM” → Present **Compute Optimizer** Graviton recommendations in the TCO model.

**Scenario Comparison ↔ TCO Calculator**

“Compare 3-year On-Demand vs. 1-year SP vs. RI” → Use **TCO Calculator** scenarios, importing Migration Evaluator outputs.

Q1: Leadership asks for a data-driven comparison of current VMware costs against three-year RI pricing on AWS, including license portability. Which tool provides this?  
A1: **Migration Evaluator** (with Optimization & Licensing Assessment).

Q2: Sustainability goals require a report showing how migrating will cut Scope 2 emissions alongside dollar savings. Which 2025 AWS feature supports this?  
A2: **AWS TCO Calculator (2025 refresh)** that embeds **Customer Carbon Footprint Tool v2.0** data.

Q3: An engineer wants to prove that moving 50 m6i instances to Graviton c7g can save 35 %. Which AWS service supplies those rightsizing numbers?  
A3: **AWS Compute Optimizer** cross-platform (Graviton) recommendations.

Q4: Finance demands an executive summary, plus raw CSVs, detailing three migration scenarios for 400 Windows servers. Which workflow meets this?  
A4: Run **Migration Evaluator**, export the Executive Summary PDF and detailed CSVs, then import into **TCO Calculator** for scenario visualization.

Q5: When presenting the TCO, you want to include both dollar savings and estimated metric tons of CO₂ avoided. Which combination of tools provides that data?  
A5: Use **Migration Evaluator** for cost, and **TCO Calculator** with **Carbon Footprint Tool v2.0** integration for emissions metrics.

## Task 4.2: Determine the optimal migration approach for existing workloads

### 1. Database Transfer Mechanism

Selecting the **right migration tooling** to move databases with the least risk, lowest downtime, and best performance—whether the job is a simple lift-and-shift, a heterogeneous engine swap, or a near-zero-downtime cut-over.

- **AWS DMS Serverless:** fully serverless migration service whose replication storage now auto-scales beyond the former 100 GB limit—no capacity planning required for very large or long-running migrations.
- **DMS Fleet Advisor:** agent-less discovery that inventories on-prem databases (SQL Server, Oracle, MySQL, PostgreSQL) and their dependencies, feeding recommendations into Migration Hub.
- **AWS Schema Conversion Tool (SCT):** automatically converts schemas, views, stored procedures, and functions for heterogeneous moves (e.g., Oracle → Aurora PostgreSQL).
- **Amazon RDS Blue/Green Deployments:** creates a fully-synced staging environment and switches roles in **under one minute**, achieving near-zero downtime for engine upgrades or parameter changes.
- **Classic AWS DMS (provisioned):** still preferred for steady-throughput migrations where you want full control over replication instance size and storage IOPS.

**Huge Data Set ↔ DMS Serverless**

“Migrate a multi-TB OLTP DB with bursty change rates” → Use **DMS Serverless**—automatic storage scaling removes the 100 GB ceiling.

**Portfolio Discovery ↔ DMS Fleet Advisor**

“Need dependency maps for 500 on-prem DBs before scoping effort” → Deploy **Fleet Advisor** to discover and group workloads.

**Heterogeneous Engine ↔ SCT + DMS**

“Oracle to Aurora with minimal manual code rewrite” → Run **AWS SCT** for schema conversion, then **DMS (Serverless or classic)** for data replication.

**Seconds-Level Cut-Over ↔ RDS Blue/Green**

“SLA allows <60 s downtime during version upgrade” → Implement **RDS Blue/Green Deployment** for safe switch-over.

**Predictable, Smaller DBs ↔ Classic DMS**

“100 GB MySQL dev DB; want fixed cost node” → Choose **classic provisioned DMS** instance.

Q1: A 3 TB Oracle database must move to AWS with ongoing heavy write traffic; storage growth is unpredictable. Which migration service best handles this?  
A1: **AWS DMS Serverless** (auto-scaling storage).

Q2: Before migrating, architects must catalog every on-prem database server, its version, and inter-DB dependencies. What AWS feature provides this inventory?  
A2: **DMS Fleet Advisor**.

Q3: The team will convert Oracle schemas to Aurora PostgreSQL and needs automated object conversion. Which tool fits?  
A3: **AWS Schema Conversion Tool (SCT)**.

Q4: A production RDS MySQL instance requires an engine minor-version upgrade with <1 minute downtime. Which AWS capability meets this SLA?  
A4: **Amazon RDS Blue/Green Deployments**.

Q5: Developers are moving a 50 GB test PostgreSQL DB over a predictable 100 Mbps link and prefer a fixed-size replication instance. What should they select?  
A5: **Classic (provisioned) AWS DMS** replication instance.

### 2. Application Transfer Mechanism

Moving application binaries and VMs with the **right level of change**—from agentless lift-and-shift, to container conversion, to incremental strangler-fig refactoring. This module maps OS / tooling constraints and modernization goals to the matching AWS service.

- **AWS Application Migration Service (MGN) – Agentless:** replicates vCenter fleets without installing guest agents; uses VMware snapshots + HTTPS to stream blocks into AWS; supports automated launch templates and post-cut-over actions;
- **AWS Migration Hub Refactor Spaces:** scaffolds a strangler-fig pattern—creates proxy endpoints, routing rules, and service groups so you can carve micro-services from a monolith while tracking waves;
- **App2Container (A2C):** CLI that analyzes .NET/IIS or Java/Tomcat/Jetty applications, containerizes them into Docker images, and generates ECS/EKS deployment artifacts;
- **VMware Cloud on AWS (VMC):** “Relocate” option—migrate vSphere workloads intact with **VMware HCX**; zero code change, keep existing tools/skillsets;
- **MGN (Agent-based):** standard choice when OS access is available and fine-grained continuous block replication is desired;

**Agent Restrictions ↔ Agentless MGN**

“Security policy bans guest agents on prod VMs” → Use **MGN Agentless** for vCenter-based replication.

**Incremental Micro-service Carve-Out ↔ Refactor Spaces**

“Split checkout service from monolith with zero downtime” → Choose **Migration Hub Refactor Spaces**.

**Container Modernization ↔ App2Container**

“Java WebLogic app needs container packaging for EKS” → Run **App2Container** to auto-create Dockerfile & task defs.

**Zero Code / Keep vSphere ↔ VMware Cloud on AWS**

“Board demands data-center exit, but no refactor budget” → **Relocate** to **VMware Cloud on AWS** using HCX bulk migration.

**Standard Lift-and-Shift ↔ MGN (Agent-based)**

“Linux VMs allow agents, want continuous replication” → Install **MGN agents** for block-level streaming.

Q1: A regulated workload bans installation of third-party agents inside the guest OS. Which AWS migration service handles lift-and-shift?  
A1: **AWS Application Migration Service – Agentless** for vCenter fleets.

Q2: Architects must peel APIs out of a legacy monolith over several waves while maintaining one DNS entry. Which AWS service provides routing and progress tracking?  
A2: **AWS Migration Hub Refactor Spaces**.

Q3: A .NET Framework app on Windows Server 2016 needs to move to EKS with minimal manual Docker work. Which tool automates the conversion?  
A3: **App2Container (A2C)**.

Q4: Executives want to exit the colo but keep vSphere tooling unchanged and avoid code edits. What migration path fits?  
A4: **Relocate** the workloads to **VMware Cloud on AWS** using **HCX**.

Q5: An Ubuntu VM allows agents and needs continuous replication with short cut-over. Which mechanism is simplest?  
A5: **AWS Application Migration Service** with the **standard agent-based** replication.

### 3. Data Transfer Service & Strategy

Choosing the right **online or offline data-movement service** to hit schedule, bandwidth, and security targets—whether that means an agent-free cloud-to-S3 sync, a petabyte-scale device shipment, or a dedicated private link.

- **AWS DataSync – Enhanced Mode (Agent-less):** moves data directly from other clouds or on-prem NFS/SMB into Amazon S3 without deploying DataSync agents; higher parallelism boosts throughput and removes the historic 100 GB job limit.
- **AWS Snow Family (Snowball, Snowcone, Snowmobile):** rugged, PB-scale appliances that ship to your site; _job-wave automation_ in the console batches hundreds of devices and tracks task progress.
- **Amazon S3 Transfer Acceleration:** edge-optimised upload path that uses CloudFront POPs to speed long-distance transfers into an S3 bucket; requires only a DNS change.
- **AWS Direct Connect (DX):** dedicated 1–100 Gbps fibre link offering consistent throughput, private routing, and lower per-GB cost for steady hybrid workloads.
- **Site-to-Site VPN:** IPSec tunnels over the public Internet—quick to set up, ~1.25 Gbps per tunnel; good for bursty or temporary traffic before DX is provisioned.

**Agent-Free Cloud Sync ↔ DataSync Enhanced**

“Need fastest path from Azure Blob to S3; can’t deploy agents.” → **AWS DataSync (Enhanced Mode)**.

**Petabyte Offline Move ↔ Snow Family**

“Ship 800 TB from a plant with 10 Mbps links.” → Order **Snowball Edge** devices (or **Snowmobile** if >10 PB).

**Global Latency Bottleneck ↔ S3 Transfer Acceleration**

“Users in APJ upload to us-east-1 bucket; latency is killing uploads.” → Enable **Transfer Acceleration** on the bucket.

**Steady Hybrid Workload ↔ Direct Connect**

“Run nightly 5 TB DR sync, must avoid Internet jitter.” → Set up **10 Gbps Direct Connect** with Private VIF.

**Quick Start / Temporary Link ↔ Site-to-Site VPN**

“Need connectivity in two days for pilot migration.” → Configure **Site-to-Site VPN**; switch to DX later.

Q1: A data-science team must copy 50 TB from Google Cloud Storage to S3 next week, but security forbids installing agents. Which AWS service meets this?  
A1: **AWS DataSync Enhanced Mode (Agent-less).**

Q2: A manufacturing site with only a 20 Mbps uplink needs to move 600 TB of sensor data to AWS within a month. What’s the most practical option?  
A2: Order **Snowball Edge** devices and use **job-wave automation** to track the transfers.

Q3: Customers in Europe see slow uploads to an S3 bucket hosted in us-west-2. Which bucket-level feature fixes this with no code changes?  
A3: **Amazon S3 Transfer Acceleration.**

Q4: A financial firm requires a private, low-latency 10 Gbps link between its data centre and AWS for continuous replication traffic. Which connectivity choice fits?  
A4: **AWS Direct Connect** with a Private VIF.

Q5: A startup begins migrating tonight and needs an encrypted link from its on-prem firewall to VPC, but Direct Connect won’t be ready for 8 weeks. What should they use now?  
A5: **Site-to-Site VPN** tunnels (then cut over to Direct Connect later).

Q6: During planning you find that DataSync with agents can’t exceed 100 GB storage for staging. Which new feature removes this limit?  
A6: **DataSync Enhanced Mode**—its managed storage auto-scales beyond 100 GB.

### 4. Security Methods for Migration Tools

Protecting **credentials, data-in-transit, and data-at-rest** throughout every migration wave—whether traffic moves over the network or inside a Snow appliance. This module maps common exam scenarios to the encryption, identity, and least-privilege controls that AWS migration services provide.

- **AWS KMS-encrypted DataSync streams:** both agent-based and enhanced (agent-less) DataSync jobs encrypt every transfer with KMS-managed keys and AES-256 payload encryption;
- **Snow Family device security:** each appliance uses 256-bit XTS AES hardware encryption, tamper-evident seals, and a _chain-of-custody_ tracking dashboard; keys are deleted on job completion;
- **TLS-only endpoints for MGN / DMS:** replication traffic is forced over TLS 1.2+; MGN’s console can enforce _TLS-only_ connections;
- **IAM Identity Center (SSO) for migration waves:** centralizes login to Migration Hub, MGN, DMS consoles with MFA and fine-grained permission sets;
- **IAM roles with scoped permissions:** migration services assume temporary roles limited to source and target resources—least-privilege best practice;
- **PrivateLink / VPC Endpoints (optional):** keep DataSync, DMS, and MGN API calls on AWS’s private network instead of the public Internet.

**Data-in-Transit Encryption ↔ TLS-Only Endpoints**

“Replication must traverse TLS 1.2-only links” → Configure **TLS-only** settings on **MGN** / **DMS** and verify certificates.

**Data-at-Rest Encryption ↔ KMS & Snow Hardware**

“Backup files must remain encrypted while queued” → Use **DataSync with KMS keys** or rely on **Snowball Edge** built-in AES-256 encryption.

**Credential Governance ↔ IAM Identity Center**

“Engineers need SSO + MFA during Wave 2 cut-over” → Integrate **IAM Identity Center** and assign permission sets scoped to migration roles.

**Least Privilege ↔ IAM Roles**

“Service should read only source bucket A and write to target bucket B” → Create **IAM role** with those two actions; attach to **DataSync task**.

**Private Network Requirement ↔ VPC Endpoints**

“Replication traffic must avoid the public Internet” → Use **AWS PrivateLink VPC endpoints** for **DataSync** / **DMS** API calls.

Q1: Compliance mandates that all replication traffic be encrypted in flight with TLS 1.2 or higher. Which setting should be enabled for AWS Application Migration Service?  
A1: **TLS-only endpoints** for **MGN** replication and console access.

Q2: A terabyte-scale offline transfer must ensure the device cannot be read if stolen. Which AWS feature addresses this?  
A2: **Snow Family’s built-in 256-bit XTS AES hardware encryption** with tamper seals and chain-of-custody.

Q3: During migration, engineers need single sign-on with MFA to the Migration Hub dashboard. Which AWS service provides this?  
A3: **IAM Identity Center (AWS SSO)**.

Q4: A DataSync task must write only to `ProdBucket` and nowhere else. How do you enforce this?  
A4: Attach a **least-privilege IAM role** to the DataSync task granting `s3:PutObject` on `ProdBucket/*` only.

Q5: Security insists that KMS keys, not default service keys, protect replication objects. Which configuration meets this for DataSync?  
A5: Specify a **customer-managed KMS key (CMK)** for the DataSync destination.

Q6: A database migration must run over an isolated network path with no public Internet exposure. What AWS option enables this?  
A6: Create **VPC Interface Endpoints (PrivateLink)** for **AWS DMS** or **DataSync** and route traffic internally.

### 5. Governance Model

Establishing a **multi-account landing zone** with built-in guardrails, least-privilege policies, and cost-allocation tagging—so every migration wave lands in a secure, compliant, and well-governed environment.

- **AWS Control Tower Account Factory:** provisions new AWS accounts from a standardized blueprint and auto-enrolls them under preventive & detective guardrails; supports nested OUs and bulk “account vending.”
- **Control Tower Guardrails:** _preventive_ (SCP-backed), _detective_ (Config-backed), and _proactive_ controls that enforce or monitor compliance across accounts/OUs.
- **Service Control Policies (SCPs):** organization-wide allow/deny policies—e.g., block all Regions except `ap-southeast-2` while exempting global services.
- **AWS Organizations Cost-Allocation Tags:** propagate mandatory tags (`Project`, `CostCenter`) to every account and surface them in Cost Explorer/Budgets for show-back.
- **Landing Zone Accelerator on AWS (LZA):** infrastructure-as-code baseline that deploys hundreds of security & compliance controls (PCI DSS v4, digital-sovereignty regions, etc.) in minutes—ideal for regulated industries.

**Account Vending ↔ Control Tower Account Factory**

“Create 20 new LOB accounts with baseline security” → Use **Account Factory**; guardrails auto-apply.

**Policy Enforcement ↔ Guardrails + SCPs**

“Block S3 public buckets and non-compliant Regions” → Enable **preventive guardrails** and attach an **SCP** denying unwanted Regions.

**Regulated Compliance ↔ Landing Zone Accelerator**

“Healthcare org needs HIPAA/FedRAMP controls on day 1” → Deploy **Landing Zone Accelerator on AWS** templates.

**Charge-Back Readiness ↔ Org Tags**

“Finance demands cost visibility by business unit” → Mandate **cost-allocation tags** at account creation; surfaced in Cost Explorer.

Q1: A migration program must spin up dozens of standardized accounts for each business unit, applying baseline security controls automatically. Which AWS feature meets this?  
A1: **AWS Control Tower Account Factory** with preventive & detective guardrails.

Q2: Governance requires that workloads run only in `ap-southeast-2`; all other Regions must be blocked. What’s the correct control mechanism?  
A2: Attach an **SCP** that denies actions where `aws:RequestedRegion` ≠ `ap-southeast-2`.

Q3: A bank needs to satisfy PCI DSS v4 controls before its first workload goes live. Which AWS solution accelerates this compliance baseline?  
A3: **Landing Zone Accelerator on AWS** (includes PCI DSS v4 guardrails).

Q4: Cloud operations wants to ensure no one can create S3 buckets with public ACLs across all new accounts. Which control enforces this from day one?  
A4: Enable the **preventive S3-public-access guardrail** in **AWS Control Tower** for the target OU.

Q5: Finance needs show-back reports grouped by `CostCenter` across every migrated account. What governance step enables this?  
A5: Enforce **mandatory cost-allocation tags** via **AWS Organizations Tag Policies** and surface them in **Cost Explorer/Categories**.

## Task 4.3: Determine a new architecture for existing workloads

### 1. Compute Platform Selection

Picking the _right_ compute substrate—EC2, containers, serverless, or edge—to satisfy performance, latency, and operational-overhead goals for modernised workloads.

- **EC2 C7g / M7i / R7g & Graviton 4:** latest 7-series instances (Graviton 3 & 4) deliver up to 25 % higher price-performance for compute-bound, general-purpose, and memory-intensive apps; GHz-optimised M7i adds Intel Xeon Sapphire Rapids for licence-tethered workloads
- **Block Express io2 volumes:** provide up to **4 000 MB/s** throughput and 256 000 IOPS per volume—ideal for monolithic DB lift-and-shift or ultra-hot data sets
- **EC2 Mac2 (Apple Silicon):** purpose-built M2 Pro Mac Mini hosts for fast iOS/macOS CI/CD pipelines and code-signing
- **Predictive Auto Scaling:** ML-based capacity forecasting for EC2 Auto Scaling groups—warms capacity ahead of demand spikes to maintain SLA
- **AWS App Runner (2025 runtime updates):** fully managed container platform for HTTP APIs—now offers larger compute configs and simplified GPU preview builds for inference workloads
- **Lambda SnapStart (Java):** caches a _pre-initialised_ execution snapshot, cutting Java cold-starts by up to 90 %
- **Outposts Rack Gen 2 & Local Zones:** delivers < 10 ms latency edge compute with Nitro-based racks or metro-area Zones; supports Graviton and GPU SKUs

**Steady, Licence-Bound Workloads ↔ EC2 M7i / R7g**

“24×7 SAP HANA cluster, sockets counted for licensing” → Place on **M7i** (Intel) or **R7g** (Graviton) depending on vendor support.

**Compute-Bound Micro-services ↔ C7g / Graviton 4**

“High-throughput API, cost sensitive” → Use **C7g** or next-gen **Graviton 4** for best $/vCPU.

**Ultra-Hot DB or Analytics ↔ io2 Block Express**

“Requires 4 GB/s disk throughput” → Attach **io2 Block Express** volumes.

**Mobile CI/CD ↔ EC2 Mac2**

“iOS apps need code-signing on Apple silicon” → Launch **Mac2** instances.

**Event-Driven Bursts ↔ Lambda + SnapStart**

“Bursty Java workloads, latency critical” → Deploy on **Lambda with SnapStart**.

**Containerised Web / ML Inference ↔ App Runner**

“Stateless API, want PaaS & optional GPU” → Use **App Runner**; pick GPU preview size for inference.

**Predictable Daily Peaks ↔ Predictive Auto Scaling**

“Traffic rises every weekday 9 AM” → Enable **Predictive Auto Scaling** on the ASG.

**Edge-Constrained ↔ Outposts / Local Zones**

“Factory floor needs < 10 ms to control robots” → Deploy to **Outposts Gen 2** rack or local **AWS Local Zone**.

Q1: A finance batch job runs 24×7 and is CPU-bound. Which EC2 family gives the best price-performance without licensing constraints?  
A1: **C7g** (Graviton 3) or **C7g-class Graviton 4** if available.

Q2: A 40-TB Oracle DB migration demands 4 000 MB/s disk throughput per node. Which EBS option meets this?  
A2: **io2 Block Express** volumes.

Q3: DevOps needs to build and sign iOS apps in the pipeline using Apple silicon. What instance type is required?  
A3: **EC2 Mac2** (M2 Pro).

Q4: A Java Lambda function has unacceptable 1-second cold-start latency. Which feature can reduce this by ~90 %?  
A4: **Lambda SnapStart**.

Q5: Traffic to an e-commerce API doubles every day at 08:00. How do you scale EC2 capacity _before_ the spike?  
A5: Enable **Predictive Auto Scaling** on the Auto Scaling group.

Q6: A start-up wants to deploy a stateless REST service quickly and later add GPU inference without managing ECS/Fargate. What AWS service fits?  
A6: **AWS App Runner** with the new GPU-enabled configuration.

Q7: A smart-factory control loop requires <10 ms round-trip latency to on-prem machines. Which compute option meets this?  
A7: **AWS Outposts Rack Gen 2** (or a nearby **AWS Local Zone**) for sub-10 ms latency.

Q8: Licensing rules force Windows Server Datacenter cores; execs want to minimise cost. Which EC2 generation should you choose?  
A8: **M7i** (Intel Sapphire Rapids) for high GHz and licence efficiency.

### 2. Container Hosting Platform Selection

Choosing the best AWS landing zone for containerized workloads—balancing **operational overhead, API flexibility, hybrid reach, and cost efficiency.**

- **Amazon ECS Anywhere:** extends ECS control plane to on-prem/bare-metal hosts for a single-pane hybrid cluster;
- **Amazon EKS v1.31 + Pod Identity:** upstream Kubernetes with IAM-for-Pod support—assigns fine-grained roles per pod without kube-iam sidecars;
- **Karpenter 2025:** cluster-autoscaler replacement that launches right-sized, Spot-aware nodes in <60 s; supports Graviton & GPU instance weightings;
- **AWS Fargate v2:** serverless data-plane up to **16 vCPU / 120 GB**, now with Windows containers and GPU inference tasks—no node management;
- **AWS App Runner:** push-to-deploy PaaS for HTTP micro-services—auto-builds from ECR/Git, TLS & autoscaling out of the box;
- **Amazon ECR Pull-Through Cache:** mirrors public Docker Hub / Quay images locally to cut latency and avoid rate limits;

**AWS-Native Simplicity ↔ ECS**

“Team wants AWS-managed scheduler, no Kubernetes complexity” → **Amazon ECS** (on Fargate or EC2).

**Kubernetes API / Helm Charts ↔ EKS**

“Needs CRDs, helm, service mesh” → **Amazon EKS v1.31** with **Pod Identity**.

**Serverless, No Nodes ↔ Fargate v2**

“Don’t want to patch AMIs; tasks burst briefly” → Run on **AWS Fargate v2**.

**Push-to-Deploy PaaS ↔ App Runner**

“Developers just git push and get HTTPS URL” → Use **AWS App Runner**.

**Hybrid / Edge Cluster ↔ ECS Anywhere**

“Must run tasks on factory servers but control from AWS” → **ECS Anywhere**.

**Just-in-Time Capacity ↔ Karpenter 2025**

“Cost-optimise Spot pools, scale in 30 seconds” → Enable **Karpenter** in EKS.

**Image Rate-Limit Mitigation ↔ ECR Cache**

“CI pipeline throttled by Docker Hub” → Use **ECR Pull-Through Cache**.

Q1: Developers need helm charts and Istio sidecars. Which AWS container platform should you pick?  
A1: **Amazon EKS** (Kubernetes).

Q2: A stateless API spikes for 30 seconds every 5 minutes; ops refuses to manage EC2 nodes. Best runtime?  
A2: **AWS Fargate v2**.

Q3: A media company must deploy the same container stack in on-prem racks and the cloud under one control plane. Which service enables this?  
A3: **Amazon ECS Anywhere**.

Q4: The security team demands IAM roles scoped per pod, not per node. What 2025 EKS feature fulfills this?  
A4: **Pod Identity** in **EKS v1.31**.

Q5: Overnight load varies and pods often wait for nodes; you want sub-minute scaling using Spot where possible. What should you enable?  
A5: **Karpenter 2025** autoscaling for the EKS cluster.

Q6: Engineers want an HTTPS endpoint auto-generated after each push, with no ingress setup. Which AWS service fits?  
A6: **AWS App Runner**.

Q7: Builds fail due to Docker Hub pull limits; latency is also high in APAC. How do you resolve this?  
A7: Configure **ECR Pull-Through Cache** for the public images.

Q8: Licensing rules bind Windows Server containers; the team needs 12 vCPU tasks without managing hosts. Which option meets this?  
A8: **AWS Fargate v2** (Windows container support up to 16 vCPU / 120 GB).

### 3. Storage Service Selection

Matching **I/O, durability, latency, and compliance** needs to the most cost-effective AWS storage option—whether that means sub-millisecond block for a database, immutable NAS volumes for legal hold, or ultra-low-latency object reads for millions of tiny files.

- **EBS io2 Block Express (and gp4 preview):** delivers up to **4 000 MB/s** throughput and 256 000 IOPS per volume—purpose-built for high-performance relational/OLTP databases and log-heavy analytics.
- **EFS One Zone-IA + Cross-Region Replication:** low-cost, single-AZ file storage paired with EFS replication to a second Region for DR; ideal for infrequently accessed POSIX data that still needs remote copies.
- **FSx for ONTAP SnapLock:** provides WORM (write-once-read-many) volumes with _no added licence fee_ (Mar 2025), meeting ransomware-protection and compliance retention mandates.
- **FSx for OpenZFS Multi-AZ:** fully managed ZFS file system with up to **10 240 MB/s** throughput and automatic fail-over across AZs—great for build farms and media workloads requiring consistent sub-millisecond latency.
- **S3 Express One Zone:** low-latency (<10 ms) object store in a single AZ for workloads with millions of small objects and high request rates (e.g., ad-tech bidding caches).
- **S3 Glacier Instant Retrieval:** archive tier that cuts storage cost by ~68 % yet keeps **millisecond-level** access, perfect when data is rarely read but must return fast.
- **AWS Storage Gateway – Volume & Tape modes:** offers cached volumes for on-prem apps needing cloud-backed iSCSI block and VTL tape libraries for hybrid backups to S3/Glacier.

**Ultra-High IOPS / Throughput ↔ io2 Block Express**

“Monolithic Oracle DB needs 4 GB/s per node” → Attach **io2 Block Express** (or gp4 preview) volumes.

**Cost-Efficient Shared POSIX ↔ EFS One Zone-IA**

“Analytics scripts read shared data weekly, must replicate off-Region” → Use **EFS One Zone-IA** with **cross-Region replication**.

**Immutable Compliance NAS ↔ FSx SnapLock**

“Financial records require 7-year WORM & ransomware protection” → Create **FSx for ONTAP SnapLock** volumes.

**High-Availability POSIX ↔ FSx OpenZFS Multi-AZ**

“Render farm needs multi-AZ fail-over and sub-ms latency” → Deploy **FSx for OpenZFS Multi-AZ**.

**Millions of Tiny Objects, <10 ms Reads ↔ S3 Express**

“Ad server fetches 2 KB creatives at 5 k RPS” → Store in **S3 Express One Zone**.

**Instant Archive Access ↔ Glacier Instant**

“Medical images accessed quarterly but SLA < 50 ms” → Migrate to **S3 Glacier Instant Retrieval**.

**Hybrid Backup ↔ Storage Gateway Tape**

“Keep existing Veeam tapes while ditching tape robots” → Use **Storage Gateway Tape Gateway** (VTL).

Q1: A 60 TB PostgreSQL cluster needs 4 000 MB/s disk throughput with <1 ms latency. Which EBS option satisfies this?  
A1: **io2 Block Express** volumes.

Q2: Weekly reporting jobs share files that rarely change; management wants the lowest-cost NFS storage with a replica in another Region. What’s the best service combo?  
A2: **EFS One Zone-IA** plus **EFS cross-Region replication**.

Q3: Regulators require financial data be immutable for seven years and protected from ransomware without third-party licences. Which AWS storage fits?  
A3: **FSx for NetApp ONTAP SnapLock** volumes.

Q4: A VFX studio’s render nodes demand multi-AZ, ultra-high-throughput POSIX file storage. Which service delivers?  
A4: **FSx for OpenZFS Multi-AZ**.

Q5: An ad-tech platform stores billions of 1–5 KB creatives and needs sub-10 ms GET latency. Which storage class should they adopt?  
A5: **S3 Express One Zone**.

Q6: A compliance archive currently in S3 Standard-IA must cut cost but still return files in milliseconds. Which alternative meets both goals?  
A6: **S3 Glacier Instant Retrieval**.

Q7: A datacenter keeps LTO backups but wants to eliminate tape hardware while preserving the tape workflow. What AWS service enables this?  
A7: **AWS Storage Gateway Tape Gateway** in cached/VTL mode.

### 4. Database Platform Selection

Matching **access patterns, licensing needs, and burst behavior** to the optimal managed engine—whether that is ultra-fast relational I/O, petabyte-scale JSON, sub-second search, or a serverless graph that idles at zero.

- **Aurora I/O-Optimized:** pay-for-I/O variant that cuts costs by up to 90 % on write-heavy workloads while keeping the same latency and failover SLA.
- **RDS Blue/Green Deployments v2:** spins up a fully-synced “green” environment and swaps it in under a minute for near-zero-downtime upgrades.
- **RDS Custom (Oracle / SQL Server):** gives OS-level access for third-party agents, file systems, or kernel extensions while keeping RDS backups & monitoring.
- **DynamoDB adaptive capacity v3 + Standard-IA class:** auto-rebalances hot partitions and lets rarely‐read tables drop storage cost by ~60 %.
- **OpenSearch Serverless:** fully managed search/analytics that auto-scales shards and compute; no cluster tuning required.
- **DocumentDB Elastic Clusters:** MongoDB-compatible sharding API that scales JSON collections to **petabyte** size with horizontal autoscale.
- **Neptune Serverless v2:** graph database that scales from zero to hundreds of thousands of queries/sec—ideal for spiky knowledge-graph workloads.
- **Timestream for InfluxDB:** managed time-series service exposing the InfluxDB API; single-digit-ms queries, built-in retention tiers.
- **ElastiCache Serverless & MemoryDB:** Redis-compatible caches that auto-scale, offer micro-second reads, and (with MemoryDB) durable multi-AZ persistence.

**Write-Heavy Relational ↔ Aurora I/O-Optimized**  
“Payment gateway runs 5 000 IOPS per GB—cut storage cost.” → Switch to **Aurora I/O-Optimized**.

**Zero-Downtime Upgrade ↔ RDS Blue/Green v2**  
“Need PostgreSQL minor upgrade with <60 s outage.” → Use **Blue/Green Deployments v2**.

**OS-Level Agent Needed ↔ RDS Custom**  
“Third-party backup agent must run inside DB host.” → Migrate to **RDS Custom for Oracle/SQL Server**.

**Unpredictable Key/Value Burst ↔ DynamoDB**  
“Gaming leaderboard spikes nightly; cost matters off-peak.” → **DynamoDB** with **adaptive capacity v3** + **Standard-IA**.

**Full-Text + Aggregations ↔ OpenSearch Serverless**  
“Product catalog needs fuzzy search and Kibana dashboards.” → Store in **OpenSearch Serverless**.

**Petabyte JSON Store ↔ DocumentDB Elastic Clusters**  
“IoT telemetry collection will hit 1 PB in a year.” → Use **DocumentDB Elastic Clusters**.

**Graph Traversals ↔ Neptune Serverless**  
“Fraud-detection traverses 10 hops, bursts on Black Friday.” → Deploy **Neptune Serverless v2**.

**High-Write Time-Series ↔ Timestream for InfluxDB**  
“Log 5 M metrics/s, query last 30 min at ms latency.” → **Amazon Timestream for InfluxDB**.

**Durable, Auto-Scaling Cache ↔ ElastiCache Serverless / MemoryDB**  
“Session cache must survive AZ fail-over, zero admin.” → Choose **MemoryDB** (durable) or **ElastiCache Serverless** (ephemeral).

Q1: A fintech OLTP system pushes >3 GB/s write traffic and spends most of its bill on I/O. Which engine slashes storage cost while preserving Aurora features?  
A1: **Aurora I/O-Optimized**.

Q2: Ops must patch an RDS MySQL instance with <1 minute downtime. What AWS feature meets this SLA?  
A2: **RDS Blue/Green Deployments v2**.

Q3: A vendor requires installing a kernel module on the database host. Which managed service allows this yet keeps automated backups?  
A3: **RDS Custom for Oracle/SQL Server**.

Q4: A mobile game’s scores table is hot for two hours nightly and idle otherwise. How can you minimise cost without throttling?  
A4: Use **DynamoDB adaptive capacity v3** plus the **Standard-IA** table class.

Q5: Marketing needs Kibana-style dashboards and fuzzy product search without managing clusters. What database fits?  
A5: **Amazon OpenSearch Serverless**.

Q6: Engineers expect their MongoDB-compatible dataset to reach 800 TB in 18 months. Which AWS database will scale horizontally with no sharding code change?  
A6: **DocumentDB Elastic Clusters**.

Q7: Fraud detection occasionally spikes to 200 K queries/s on a multi-hop social graph. Which engine offers pay-per-request elasticity?  
A7: **Neptune Serverless v2**.

Q8: A time-series application already uses open-source InfluxDB and wants a managed drop-in replacement. Which AWS service is designed for this?  
A8: **Amazon Timestream for InfluxDB**.

Q9: A stateless web tier needs a Redis-compatible cache that scales automatically and survives AZ failure without manual sharding. Which option?  
A9: **Amazon MemoryDB** (durable, Redis-compatible) or **ElastiCache Serverless** if durability is not required.

## Task 4.4: Determine opportunities for modernization and enhancements

### 1. Decouple Application Components

Loosely coupling producers, consumers, and schedulers makes systems **burst-tolerant, easier to evolve, and simpler to observe**. This module shows how the newest AWS messaging and orchestration features remove glue-code, smooth traffic spikes, and guarantee ordering at scale.

- **Amazon EventBridge Pipes:** point-and-click pipelines that read from SQS, Kinesis, DynamoDB Streams, etc., enrich events, and invoke Lambda/SNS/Step Functions with no custom code.
- **EventBridge Scheduler (universal targets, 7 000 + API actions):** invoke any AWS API on a cron/rate/one-off schedule—no Lambda wrapper needed.
- **SNS FIFO with message-group sharding:** preserves order **per group** while delivering **300 TPS per group**; parallel groups raise overall throughput.
- **SQS High-Throughput FIFO mode:** scales ordered queues to **hundreds of thousands of msgs/s** (regional quota up to 18 000 TPS per API op).
- **Step Functions Distributed Map:** orchestrates millions of parallel tasks with automatic sharding and progress tracking—ideal for bursty fan-outs.

**Remove Glue Code ↔ EventBridge Pipes**  
“Replace custom poller that reads SQS and calls Lambda” → configure **Pipes** for SQS → Lambda flow.

**Centralised Scheduling ↔ EventBridge Scheduler**  
“Kick off 50+ AWS APIs nightly—no Lambda wanted” → create **Scheduler** jobs with _universal target_ JSON.

**Guaranteed Order + High TPS ↔ SNS FIFO Shards**  
“Stock trades need strict order at 10 000 TPS” → shard by `MessageGroupId`; each group handles 300 TPS.

**Absorb Traffic Spikes ↔ SQS High-Throughput**  
“Flash-sale bursts at 350 K msgs/s” → enable **High-Throughput FIFO** on the queue.

**Massive Fan-Out Workflows ↔ Distributed Map**  
“Resize 1 M images in parallel” → wrap image task in **Step Functions Distributed Map**.

Q1: A legacy service polls order events every second and calls a Lambda to process them, causing high CPU load. Which feature removes the polling code?  
A1: **Amazon EventBridge Pipes** connecting the SQS queue directly to the Lambda function.

Q2: You must start a SageMaker batch job and a Glue crawler at 02:00 daily without writing Lambda wrappers. What’s the best option?  
A2: **EventBridge Scheduler universal targets**—one schedule invoking both API actions.

Q3: An equities-trading app requires ordered, exactly-once delivery at 9 000 TPS per ticker symbol. Which messaging service and setting satisfy this?  
A3: **SNS FIFO topic** using distinct _message-group IDs_ for each ticker symbol.

Q4: Black-Friday checkout spikes will push one queue to ~300 K messages per second while still needing FIFO semantics. What should you enable?  
A4: **High-Throughput FIFO mode** on the Amazon SQS queue.

Q5: A data-processing pipeline must run the same Lambda against 500 000 S3 objects in minutes and report progress. Which AWS service fits?  
A5: **AWS Step Functions Distributed Map** state to fan-out and track the Lambda invocations.

### 2. Serverless Solutions

Modernising workloads by **removing servers altogether**—shrinking cold-starts, streaming large payloads, serving HTTPS with zero infra, and caching without clusters.

- **AWS Lambda SnapStart:** takes a snapshot of a warmed JVM, restoring it in ~200 ms; cuts Java cold-starts by up to 90 %.
- **Lambda Response Streaming:** returns bytes as soon as they’re ready and raises the max payload to **20 MB**, improving time-to-first-byte for large results.
- **Lambda Node.js 20 Runtime + ESM:** latest runtime adds native ECMAScript-modules and modern Node features for Lambda functions.
- **Lambda Function URLs:** built-in HTTPS endpoints with optional CORS—perfect for single-function micro-services or signed-URL callbacks.
- **AWS App Runner (2025 update – GPU preview):** push-to-deploy container PaaS that now offers GPU sizes for serverless ML inference—no cluster ops.
- **Amazon ElastiCache Serverless:** connection-less Redis/Valkey endpoint that auto-scales and removes node management.

**Millisecond Cold-Start ↔ SnapStart**  
“Java API must respond in <300 ms even on first hit.” → Enable **Lambda SnapStart**.

**Progressive Large Payloads ↔ Response Streaming**  
“Need to start sending a 15 MB report while it’s generated.” → Use **Lambda Response Streaming**.

**Zero-Ops HTTPS Endpoint ↔ Function URL**  
“Webhook needs quick HTTPS callback; ALB is overkill.” → Attach a **Lambda Function URL**.

**Serverless ML Inference ↔ App Runner GPU**  
“Run a small LLM for sporadic requests without managing ECS/EKS.” → Deploy on **App Runner GPU** configuration.

**Auto-Scaling Cache ↔ ElastiCache Serverless**  
“Session cache must survive bursts without shard juggling.” → Point to **ElastiCache Serverless** endpoint.

**Sample Exam Questions**

Q1: A Java-based Lambda occasionally cold-starts at 1.2 s—SLA demands 250 ms. What AWS feature fixes this?  
A1: **Lambda SnapStart**.

Q2: An async report generator returns up to 18 MB JSON that users should start downloading immediately. Which Lambda feature should you enable?  
A2: **Lambda Response Streaming**.

Q3: Devs need a quick HTTPS endpoint for a Slack slash-command and don’t want API Gateway. What’s the lightest option?  
A3: **Lambda Function URL**.

Q4: A Node.js service wants top-level await and native ESM. Which runtime must be selected?  
A4: **nodejs20.x** Lambda runtime.

Q5: Data-science teams need on-demand GPU inference without managing clusters. Which serverless service is appropriate?  
A5: **AWS App Runner** with the GPU preview configuration.

Q6: A high-traffic shopping cart requires a Redis cache that auto-scales and eliminates node patching. What should you choose?  
A6: **Amazon ElastiCache Serverless**.

### 3. Container Service Selection

Modernising container workloads by **matching operational effort, API flexibility, and runtime elasticity** to the most suitable AWS service—whether that’s a fully managed PaaS, node-free serverless tasks, or a hybrid cluster that spans edge sites.

- **Amazon ECS:** AWS-native scheduler with the simplest control plane; runs on EC2, Fargate, or on-prem via ECS Anywhere;
- **Amazon EKS + Pod Identity (v1.31):** upstream Kubernetes with IAM roles at pod scope—ideal for Helm charts, CRDs, and fine-grained IAM;
- **Karpenter 2025:** just-in-time autoscaler launching Spot or On-Demand nodes in <60 s and right-sizes GPU/Graviton fleets automatically;
- **AWS Fargate v2 (16 vCPU / 120 GB + GPU):** serverless data plane—no AMIs to patch; supports Windows containers and GPU inference tasks;
- **AWS App Runner:** “git-push-deploy” micro-PaaS that builds from ECR/Git, provides HTTPS endpoints, autoscaling, and optional GPU sizes;
- **Amazon ECR Pull-Through Cache:** local mirror of public registries (Docker Hub, Quay) to cut latency and avoid rate limits;
- **ECS Anywhere:** extends ECS control to on-prem/edge servers for a single hybrid cluster without Kubernetes complexity;

**AWS-Native Simplicity ↔ ECS**  
“Team wants the easiest AWS scheduler, no k8s required.” → Choose **Amazon ECS**.

**Kubernetes APIs / Pod-Level IAM ↔ EKS**  
“Helm, CRDs, and per-pod IAM roles are mandatory.” → Deploy to **Amazon EKS** with **Pod Identity**.

**Zero Node Ops ↔ Fargate v2**  
“Ops won’t manage EC2 nodes; tasks burst briefly.” → Run containers on **AWS Fargate v2**.

**Developer PaaS ↔ App Runner**  
“Need HTTPS URL after each push, no load balancer setup.” → Use **AWS App Runner**.

**Hybrid / Edge ↔ ECS Anywhere**  
“Run workloads on factory floor servers under one control plane.” → Adopt **ECS Anywhere**.

**Rapid Scaling ↔ Karpenter 2025**  
“Pods wait for capacity; need sub-minute scaling.” → Enable **Karpenter** in EKS.

**Image Throttling Fix ↔ ECR Cache**  
“CI jobs hit Docker Hub rate limits.” → Configure **ECR Pull-Through Cache**.

Q1: Developers insist on Helm charts and service mesh support with IAM roles scoped per pod. Which AWS container service meets all requirements?  
A1: **Amazon EKS** with **Pod Identity**.

Q2: A stateless API spikes for 45 seconds every 10 minutes; the team refuses to manage EC2 nodes. Which runtime is most appropriate?  
A2: **AWS Fargate v2**.

Q3: A retailer needs to deploy the same container stack in on-prem stores and AWS without learning Kubernetes. What service enables this?  
A3: **Amazon ECS Anywhere**.

Q4: Build pipelines keep failing due to Docker Hub pull limits. What AWS feature resolves this without changing Dockerfiles?  
A4: **Amazon ECR Pull-Through Cache**.

Q5: Over-night batch pods often wait >2 minutes for nodes in EKS. Which 2025 feature shrinks this to seconds while minimising cost?  
A5: **Karpenter 2025** just-in-time node provisioning.

Q6: A start-up wants a fully managed HTTPS endpoint that scales from zero to thousands of requests without any cluster knowledge. Which service fits?  
A6: **AWS App Runner**.

### 4. Purpose-Built Database Opportunities

Replacing one-size-fits-all engines with **specialised, cost-efficient services**—so each workload gets optimal latency, elasticity, and pricing.

- **Aurora I/O-Optimized:** removes per-I/O charges, charging only for compute & storage—cuts costs up to 90 % on write-heavy clusters.
- **DynamoDB Standard-IA table class:** drops storage price ~60 % for infrequently accessed key/value data while keeping the same performance SLAs.
- **OpenSearch Serverless:** auto-scales shards & compute for search/analytics—no cluster sizing or patching.
- **ElastiCache Serverless (Redis/Valkey):** spin-up caches in one minute, auto-scale capacity, and pay only for memory used—no node management.
- **Timestream for InfluxDB:** managed InfluxDB API with single-digit-millisecond queries and tiered retention for high-write time-series telemetry.
- **DocumentDB Elastic Clusters:** MongoDB-compatible sharding that elastically scales JSON collections to petabyte size and millions of ops/s.

**Write-Heavy Relational ↔ Aurora I/O-Optimized**  
“Payment-gateway SQL writes 5 GB/day; storage I/O dominates bill.” → **Aurora I/O-Optimized** trims I/O charges.

**Cool KV Tables ↔ DynamoDB Standard-IA**  
“Feature-flag table reads once per deploy, must stay online.” → Move to **Standard-IA** class for 60 % lower cost.

**Search / Log Analytics ↔ OpenSearch Serverless**  
“Ops wants Kibana and fuzzy search, not clusters.” → Use **OpenSearch Serverless**.

**Hot Session / Leaderboard Cache ↔ ElastiCache Serverless**  
“Traffic spikes x10 on game launches; ops hates re-sharding.” → Point to **ElastiCache Serverless** endpoint.

**High-Write Telemetry ↔ Timestream for InfluxDB**  
“IoT sensors push 4 M metrics/s; must query last 30 min in <10 ms.” → Store in **Timestream for InfluxDB**.

**Petabyte JSON ↔ DocumentDB Elastic Clusters**  
“E-commerce catalog expected to hit 1 PB; devs need MongoDB API.” → Migrate to **DocumentDB Elastic Clusters**.

Q1: A social-media feed store pushes millions of writes per day and the Aurora bill is 70 % I/O. Which Aurora configuration slashes cost without throttling?  
A1: **Aurora I/O-Optimized**.

Q2: A rarely read DynamoDB table stores archival licence keys and costs \$2 k/month in storage. How can you cut that by roughly 60 %?  
A2: Switch the table to **DynamoDB Standard-IA**.

Q3: Engineers want Kibana dashboards and full-text product search but refuse to manage OpenSearch clusters. What should you adopt?  
A3: **Amazon OpenSearch Serverless**.

Q4: A gaming studio’s Redis cache must scale from 1 GB to 200 GB during launch weekend with no node patching. Which AWS service fits?  
A4: **ElastiCache Serverless** (Redis or Valkey).

Q5: An IoT analytics team already uses open-source InfluxDB and needs a managed drop-in with millisecond queries. Which service matches?  
A5: **Amazon Timestream for InfluxDB**.

Q6: Product data is expected to exceed 800 TB next year, and developers insist on MongoDB compatibility and automatic sharding. What AWS database meets this?  
A6: **DocumentDB Elastic Clusters**.

### 5. Integration Service Choice

Selecting the **right messaging / orchestration pattern** so integrations stay ordered, retry safely, evolve schemas, and minimise custom glue-code.

- **Amazon EventBridge Pipes:** point-to-point pipelines that connect sources (SQS, Kinesis, DynamoDB Streams, etc.) to targets (Lambda, Step Functions, SNS) with optional transforms and enrichments—no code.
- **EventBridge Bus + API Destinations:** pub/sub event bus for loose coupling; API Destinations push events to any SaaS/HTTP endpoint with built-in auth throttling.
- **SNS ➞ SQS Dead-Letter Queues:** SNS topics publish to SQS DLQs that quarantine “poison” messages for later analysis or re-drive, improving resilience without code.
- **AWS Step Functions Retry / Backoff Policies:** declarative `Retry` blocks with exponential back-off, jitter, and max attempts—ideal for complex workflows needing resumable state.
- **EventBridge Schema Registry:** captures event schemas automatically, versions them, and generates code bindings—simplifies contract evolution across teams.

**Low-Latency, Point-to-Point ↔ EventBridge Pipes**  
“Replace custom poller that reads SQS and invokes Lambda.” → Configure a **Pipe** (SQS → Lambda) with filtering & transform.

**Loose Coupling / Fan-Out ↔ EventBridge Bus**  
“Multiple micro-services must consume the same event asynchronously.” → Publish on **EventBridge Bus**; each service has its own rule.

**Push to SaaS ↔ API Destinations**  
“Send order events to ServiceNow via HTTPS, with rate limits.” → Use **API Destinations** target on the bus rule.

**Poison-Message Isolation ↔ SNS➞SQS DLQ**  
“Undeliverable notifications must not block the topic.” → Configure **SNS** subscription to **SQS DLQ** for failures.

**Complex Retry Logic ↔ Step Functions**  
“Call third-party API with exponential back-off up to 5 tries.” → Wrap call in **Step Functions** state with `Retry` + back-off.

**Schema Governance ↔ EventBridge Registry**  
“Producers evolve event JSON; consumers need typed binding.” → Store versions in **Schema Registry** and auto-generate SDKs.

Q1: An SQS queue feeds a Lambda; the team wants to remove the polling code and apply a transform before invoke. Which service solves this?  
A1: **Amazon EventBridge Pipes**.

Q2: Multiple micro-services must consume ‘OrderCreated’ events and an external SaaS must also be notified by HTTPS POST. What combination fits?  
A2: Publish to an **EventBridge Bus** with one rule targeting internal consumers and another **API Destination** to the SaaS endpoint.

Q3: A notification topic occasionally receives malformed messages that break all subscribers. How do you quarantine these without losing them?  
A3: Attach an **SQS dead-letter queue** to the **SNS** subscription.

Q4: A batch workflow must call a flaky partner API with exponential back-off and bail after three failures. Which AWS feature requires no extra code?  
A4: **AWS Step Functions** `Retry` with back-off policy.

Q5: Developers keep changing the event JSON structure, breaking downstream TypeScript code. What AWS capability enforces versioned contracts and codegen?  
A5: **EventBridge Schema Registry** with generated SDK bindings.
