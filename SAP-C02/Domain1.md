# Content Domain 1: Design Solutions for Organizational Complexity

## Task 1.1: Architect network connectivity strategies

### 1. Connectivity options for multiple VPCs

Modern AWS estates rarely live inside one VPC. As workloads multiply across accounts and Regions, you need a toolbox that scales from simple point-to-point peering to global SD-WAN overlays—while keeping routing tables, overlapping CIDRs, and security boundaries sane. This module explains **when** to pick VPC Peering, Transit Gateway, PrivateLink, Cloud WAN, or the new VPC Lattice layer-7 mesh, and how the exam tests those decisions under cost, scale, and operational-simplicity constraints.

- **VPC Peering (Regional / Cross-Region)** — private, one-to-one routing between two VPCs; no transitive hops; pays inter-AZ data charges on each side.
- **AWS Transit Gateway (TGW)** — hub-and-spoke L3 router that scales to 5,000 attachments per Region; supports route-propagation, multicast, and bandwidth quotas (20 Gbps/attachment).
- **Transit Gateway Peering** — inter-Region federation of TGWs creating a multi-hub mesh without VPN tunnels.
- **TGW Connect (GRE/BGP)** — lets SD-WAN or on-prem routers connect to a TGW via high-bandwidth GRE/BGP instead of IPsec.
- **AWS Cloud WAN** — managed global SD-WAN overlay that stitches multiple TGWs/Direct Connects, now with Security-Group referencing and native DNS mapping for segmentation (2025 update).
- **AWS PrivateLink (Interface Endpoints)** — exposes a service in one VPC as elastic network interfaces in consumers’ VPCs; no need for full VPC routing.
- **VPC Lattice** — layer-7 service-to-service mesh offering auth, routing, and observability across VPC boundaries; ideal for micro-service to micro-service calls.
- **AWS Resource Access Manager (RAM)** — shares TGWs, subnets, and VPC Lattice service networks across accounts in an Org.
- **CIDR overlap-avoidance / IPAM** — planning CIDRs with AWS IP Address Manager to prevent route-black-holes.
- **Route Tables & Propagation** — TGW route-tables, static propagation flags, and appliance-mode for inspection hops.

**Full-Mesh vs. Hub-and-Spoke ↔ VPC Peering vs TGW**  
“Connect three test VPCs today, but hundreds later” → choose **Transit Gateway** for transitive routing; VPC Peering doesn’t scale and lacks route-propagation.

**Cross-Region Hub ↔ TGW Peering**  
“Low-latency private traffic between ap-southeast-2 and us-west-2 TGWs” → establish **TGW Peering**; cheaper than VPN, avoids NAT, supports up to 5 Gbps per connection.

**Global Segmentation & Central Egress ↔ Cloud WAN**  
“Need one policy engine to isolate prod/dev across Regions and direct all Internet egress through a firewall VPC” → build **Cloud WAN** core network with SG referencing; simplifies route-propagation.

**Service-to-Service Calls Only ↔ PrivateLink / VPC Lattice**  
“Expose an internal payment API to five consumer VPCs with no CIDR management” → use **AWS PrivateLink**.  
“Modern micro-services need auth + path-based routing across VPCs” → stand up **VPC Lattice** for L7 controls.

**Overlapping CIDRs ↔ TGW Connect + NAT / Cloud WAN Service Insertion**  
“Acquired company uses 10.0.0.0/16 everywhere” → attach via **TGW Connect** with NAT or place an appliance via **Cloud WAN Service Insertion** to translate addresses.

Q1: A startup has 200 VPCs today and projects 1,000 within a year. They want transitive routing and a single point to monitor attachments. Which service best meets the requirement?  
A1: **AWS Transit Gateway**.

Q2: You must link TGWs in eu-central-1 and us-east-1 without VPN tunnels while keeping traffic on the AWS backbone. What feature do you use?  
A2: **Transit Gateway Peering**.

Q3: A security team mandates that all VPCs, regardless of Region, reference centralized security groups for segmentation. Which 2025 service/update enables this?  
A3: **AWS Cloud WAN with Security-Group referencing**.

Q4: Two VPCs need to share a payments API; they do **not** require full network connectivity. Which option minimizes CIDR overlap risk and route-table entries?  
A4: **AWS PrivateLink Interface Endpoints**.

Q5: A legacy SD-WAN appliance must attach to a TGW at 50 Gbps using GRE/BGP. Which attachment type is required?  
A5: **TGW Connect** attachment.

Q6: You need layer-7 routing, authentication, and built-in observability for micro-services that span multiple VPCs. Which newer AWS service provides this?  
A6: **Amazon VPC Lattice**.

Q7: Finance complains about rising inter-AZ peering costs across dozens of peerings. What change lowers cost and simplifies routing?  
A7: Migrate to a **hub-and-spoke Transit Gateway** architecture.

Q8: During an M&A, two VPCs have overlapping CIDRs but must exchange traffic temporarily. Which approach avoids renumbering?  
A8: Deploy **NAT appliances via TGW Connect or Cloud WAN Service Insertion** to perform address translation.

Q9: Compliance requires that all VPC traffic exit through a centralized firewall fleet that inspects both inbound and outbound flows at line-rate. Which design pattern satisfies this?  
A9: **Appliance mode VPC attachments in Cloud WAN** or **TGW inspection VPC** using route-tables to steer via firewalls.

Q10: What is the hard quota for VPC attachments per Transit Gateway (before you request an increase)?  
A10: **5,000 attachments per TGW (soft limit, can be increased).**

### 2. Connectivity options for on-premises co-location and cloud integration

### 2. Connectivity options for on-premises, co-location, and cloud integration

Enterprises rarely live only in AWS—data centers, edge cages, and branch offices must all tie into the cloud with the right mix of **bandwidth, latency, encryption, and high availability**. This module walks through Direct Connect, VPN, SD-WAN, and Cloud WAN patterns so you can choose the lowest-cost, most resilient path for hybrid workloads—and recognize distractors around BGP timers, MACsec vs. IPsec, and multi-Region reach.

- **AWS Direct Connect (DX)** — dedicated 1/10/100 Gbps circuits from on-prem to AWS; private routing, predictable latency, optional **MACsec** L2 encryption. :contentReference[oaicite:0]{index=0}
- **Direct Connect Gateway (DX-GW)** — globally routes multiple VPCs/TGWs across Regions from a single DX; avoids per-Region VGWs.
- **Direct Connect SiteLink** — lets two DX locations exchange traffic over AWS’s backbone without crossing a VPC; ideal for DC-to-DC replication.
- **Link Aggregation Group (LAG)** — bonds 2–4 DX links (same speed, same LOA) as one, delivering up to 400 Gbps and sub-second fail-over.
- **Site-to-Site VPN** — IPsec tunnels (1.25 Gbps soft cap each) terminated on VGW or TGW; rapid setup, pay-as-you-go backup.
- **VPN CloudHub** — hub-and-spoke overlay that lets multiple on-prem sites communicate via VPN endpoints on the same VGW.
- **TGW Connect (GRE/BGP)** — 5–50 Gbps GRE pipes into a Transit Gateway for SD-WAN appliances; preserves BGP metrics.
- **SD-WAN (vendor)** — third-party edge devices that can dial TGW Connect or run over DX for dynamic path-selection.
- **MACsec / IPsec encryption** — L2 vs. L3 encryption: MACsec now supported on Partner interconnects (2025), IPsec native to VPN. :contentReference[oaicite:1]{index=1}
- **AWS Cloud WAN** — managed global SD-WAN with segments, policy-based routing, service insertion, and security-group referencing. :contentReference[oaicite:2]{index=2}
- **Local Zones / Edge Locations** — metro-AZs or PoPs where DX can terminate closer to users, reducing first-mile latency.

**Dual DX with VPN Backup ↔ HA Hybrid**  
“Need 99.9 % SLA, 10 Gbps, and encrypted fail-over” → two **Direct Connect** links (different devices + fibers) in a **LAG**, plus **Site-to-Site VPN** as standby (longer BGP AS-PATH).

**Multi-Region Reach ↔ DX-Gateway**  
“One DX in Sydney must access VPCs in ap-southeast-2 and us-west-2” → attach both to a **Direct Connect Gateway**; avoids extra circuits.

**Data-Center-to-Data-Center Traffic ↔ SiteLink**  
“Replicate 5 Gbps between two collocation cages, no internet hop” → enable **DX SiteLink** for backbone routing—cheaper than MPLS.

**SD-WAN High Throughput ↔ TGW Connect (GRE/BGP)**  
“Vendor edge box needs 20 Gbps with dynamic routing into AWS” → deploy **TGW Connect** attachment; GRE avoids IPsec overhead.

**Link Encryption Choice ↔ MACsec vs. IPsec**  
“Compliance wants line-rate encryption on a 100 Gbps DX” → enable **MACsec** on the dedicated DX (now available on Partner interconnects). :contentReference[oaicite:3]{index=3}  
“Same requirement but over VPN” → use **IPsec** tunnels (1.25 Gbps each, scale with ECMP).

**Global Segmentation & Inspection ↔ Cloud WAN**  
“Need centralized firewall and prod/dev separation across Regions” → build **Cloud WAN** with segments + service insertion. :contentReference[oaicite:4]{index=4}

Q1: An enterprise needs a single 10 Gbps link that can burst to 40 Gbps and fail over sub-second if a fiber is cut. Which DX feature satisfies this?  
A1: **Link Aggregation Group (LAG)**.

Q2: You have one DX in Tokyo that must privately reach VPCs in three Regions without additional circuits. What should you deploy?  
A2: **Direct Connect Gateway**.

Q3: Two on-prem data centers connected via DX want to exchange 3 Gbps of replication traffic without sending it through any VPC. Which capability is designed for this?  
A3: **AWS Direct Connect SiteLink**.

Q4: A security mandate requires 100 Gbps encrypted traffic over DX links without IPsec overhead. Which option meets this?  
A4: **Enable MACsec on the dedicated DX**. :contentReference[oaicite:5]{index=5}

Q5: A branch SD-WAN appliance needs a 25 Gbps GRE tunnel into AWS with dynamic route updates. Which AWS feature enables this?  
A5: **Transit Gateway Connect**.

Q6: For a proof-of-concept, you need sub-1 Gbps encrypted connectivity from HQ to AWS in under one hour, at the lowest cost. What do you choose?  
A6: **Site-to-Site VPN** only.

Q7: During fail-over testing, your VPN backup takes 30 seconds to become active when the primary DX drops. Which BGP setting can you tune to reduce detection time?  
A7: **Hold/Keepalive timers (BGP Dead-Peer Detection)**—lower hold-time to speed convergence.

Q8: Compliance states that prod and dev traffic must be isolated globally and inspected by a third-party firewall cluster. Which 2025 service pattern solves this?  
A8: **AWS Cloud WAN segments with service insertion**. :contentReference[oaicite:6]{index=6}

Q9: A startup has one DX into ap-southeast-2 but only an Internet connection in us-west-2. They need private, low-latency replication from on-prem to both Regions. What hybrid design meets cost and performance?  
A9: **Single DX + DX-GW for ap-southeast-2** and **Site-to-Site VPN to us-west-2** (cheaper than second DX).

Q10: What is the maximum number of BGP sessions supported on a 100 Gbps dedicated Direct Connect link before requesting a quota increase?  
A10: **50 BGP sessions per dedicated DX** (soft limit).

### 3. Region and Availability Zone selection based on network and latency

Choosing the _right_ Region, Availability Zones (AZs), and edge extensions is often the first design decision you make—and the costliest one to undo. You must balance **end-user latency, data-residency laws, disaster-recovery (RPO/RTO) goals, and inter-Region transfer fees**, while ensuring micro-services and databases stay within their single-digit-millisecond latency budgets. This module shows how to mix Regions, Local Zones, Wavelength, and Global Accelerator to hit sub-10 ms targets and pass the exam’s tricky distractors.

- **AWS Region** — a geographic cluster of multiple, isolated AZs; pick for latency, residency, and service availability.
- **Multi-AZ** — running across ≥2 AZs in one Region for HA; automatic fail-over keeps RPO≈0 s, RTO < 60 s for managed services.
- **Placement Group** — logical grouping for low-latency, high-bandwidth EC2 traffic: _Cluster_ (<10 µs), _Partition_, _Spread_.
- **Local Zone** — metro extension of a Region (<10 ms RTT to end-users) running core compute/storage services.
- **Wavelength Zone** — 5G carrier edge zone (<5 ms RTT) for ultra-low-latency mobile workloads.
- **AWS Global Accelerator** — Anycast ingress; routes users to the optimal Region/AZ, improving cross-Region fail-over and TCP handshake time.
- **Latency-Based Routing (Route 53)** — DNS policy that returns the lowest-latency Region for each requester at resolution time.
- **Cross-Region Replication (CRR)** — asynchronous copy (S3, DynamoDB global tables, RDS read replica) used to meet RPO targets.
- **RPO / RTO** — Recovery Point / Time Objective; drives sync vs. async replication and choice of multi-AZ vs. multi-Region.
- **Data-Residency** — legal requirement to keep data inside specific countries; limits Region choice.
- **Network RTT baselines** — typical inter-AZ (<2 ms), intra-Region (<100 µs within placement group), inter-Region (30-200 ms) latencies.

**User Latency SLA ↔ Local / Wavelength Zones**  
“Gaming app needs <10 ms latency to Sydney players” → deploy compute in **ap-southeast-2 Local Zone**; for 5 ms mobile, add a **Wavelength Zone**.

**Global Ingress ↔ AWS Global Accelerator**  
“E-commerce site must route users to the fasted healthy Region and fail over in <1 min” → front with **Global Accelerator**; BGP Anycast beats Route 53 TTLs.

**Low-Latency Micro-services ↔ Placement Group (Cluster)**  
“AI inference fleet requires sub-100 µs EC2-to-EC2 latency” → place instances in a **cluster placement group** within one AZ.

**Disaster Recovery ↔ Cross-Region Multi-AZ**  
“Financial DB requires RPO 0 s, RTO < 1 min” → **Multi-AZ synchronous** in primary + **Cross-Region read replica** for DR.

**Data Residency ↔ Region Selection**  
“Personally identifiable info must stay in Germany” → use **eu-central-1** only, ensure logs/S3 CRR stay within EU.

**Cost vs. Performance ↔ Inter-Region DT Charges**  
“Analytics copies 5 TB daily between Regions” → consider **same-Region multi-AZ** or **bucket replication with replica-modification sync disabled** to cut egress.

Q1: Users in Los Angeles need sub-10 ms latency to a backend running in us-west-2. Which AWS feature gets you closest without adding a new Region?  
A1: **Deploy to the us-west-2 Los Angeles Local Zone**.

Q2: Mobile AR streaming must deliver <5 ms RTT to 5G customers in Tokyo. What AWS edge option is purpose-built for this?  
A2: **Wavelength Zone (carrier edge)**.

Q3: A SaaS platform wants automatic, global traffic fail-over with the fastest possible TCP handshake from any continent. Which service fulfills this?  
A3: **AWS Global Accelerator**.

Q4: Two Regions are 80 ms apart. The database requires RPO 0 s. Which replication mode is mandatory?  
A4: **Synchronous multi-AZ within one Region**; inter-Region can’t guarantee RPO 0 s at 80 ms.

Q5: A compliance policy mandates that health-care records remain inside Canada. Which Regions are valid targets?  
A5: **ca-central-1 only** (plus any localized Local/Wavelength Zones attached to it).

Q6: You need <100 µs EC2-to-EC2 latency for an HFT engine. Which placement strategy meets this?  
A6: **Cluster placement group** in a single AZ.

Q7: CRR replicates 2 TB nightly to a secondary Region and costs are rising. What design change reduces transfer fees while meeting RPO < 24 h?  
A7: **Use S3 Replication Time Control only on critical prefixes / enable S3 Intelligent-Tiering in the target bucket** (less data moved & stored).

Q8: A multi-tenant app spans three AZs in us-east-1; latency between micro-service tiers must stay below 2 ms. Is the current design sufficient?  
A8: **Yes—inter-AZ RTT inside a Region is typically <2 ms**.

Q9: Route 53 latency-based routing sometimes directs EU users to us-east-1. What mis-configuration causes this?  
A9: **Health checks failing in eu-west-1, making us-east-1 the next-best latency target**.

Q10: What is the typical round-trip latency of Global Accelerator from an end-user to the nearest AWS edge PoP?  
A10: **Single-digit milliseconds (typically 1–3 ms)**.

### 4. Traffic flow troubleshooting using AWS tools

When packets disappear or latency mysteriously spikes, you need to prove—fast—**where** they were dropped and **why**. AWS offers a layered tool-set, from flow records and packet mirrors to path simulations and managed detectors, each with its own scope (ENI, VPC, TGW, cross-account) and enablement cost. Mastering _which_ tool to run first—and _where_ it can or cannot see—lets you isolate root cause in minutes and ace exam scenarios that blend multiple options.

- **VPC Flow Logs** — ENI-level traffic metadata (accept, reject, all); delivered to CloudWatch Logs or S3 for SG/NACL analysis.
- **Transit Gateway Flow Logs** — captures source-dest, protocol, and action for every TGW attachment to debug hub traffic and capacity planning.
- **VPC Traffic Mirroring** — packet-level copies from ENIs to out-of-band analyzers (IDS, Wireshark).
- **Reachability Analyzer** — builds a hop-by-hop path graph between two resources; now supports cross-account analysis with AWS Organizations.
- **Network Access Analyzer** — policy-based audits that flag unintended network paths (e.g., Internet-exposed RDS) across the entire VPC estate. Updated regularly with new managed rules.
- **AWS Network Manager Route Analyzer** — real-time BGP/route-table visualization for TGW, Cloud WAN, and on-prem attachments.
- **CloudWatch Logs Insights** — interactive SQL-style queries over Flow Logs, ELB/NAT logs for rapid pattern hunting.
- **CloudTrail** — records API calls; spot unintended SG/NACL or route changes that preceded an outage.
- **GuardDuty Network Findings** — ML-driven alerts on anomalous traffic (e.g., port scans, brute force) sourced from VPC Flow Logs.
- **ELB & NAT Gateway Access Logs** — per-connection logs to trace HTTP codes, bytes, and NAT translations.

**Path Mis-config ↔ Reachability Analyzer**  
“Two EC2 instances in peered VPCs can’t connect” → run **Reachability Analyzer** to reveal missing route or SG rule.

**SG/NACL Rejects ↔ VPC Flow Logs**  
“Why is HTTPS traffic returning ‘REJECT’ action?” → enable **VPC Flow Logs** on the ENI—look for `action = REJECT`.

**TGW Black-Hole ↔ Transit Gateway Flow Logs**  
“Packets never exit the inspection VPC” → inspect **TGW Flow Logs** for attachment ID drops.

**Packet-Level Debug ↔ Traffic Mirroring**  
“TLS handshake fails intermittently” → mirror packets from the ENI to a **Traffic Mirroring** target for deep inspection.

**Organization-Wide Exposure ↔ Network Access Analyzer**  
“Security wants a report of any subnet that can reach the public Internet” → run **Network Access Analyzer** with the `internet-access` preset.

**Route Convergence ↔ Network Manager Route Analyzer**  
“After BGP change, users in branch A lost access” → visualize routes in **AWS Network Manager**.

**Historical Change Audit ↔ CloudTrail**  
“Latency spike started after 14:03” → search **CloudTrail** for modified SGs or route-tables at that timestamp.

Q1: A developer cannot SSH into an EC2 instance; `tcpdump` shows no SYN packets arriving. Which AWS tool gives packet-level visibility?  
A1: **VPC Traffic Mirroring**.

Q2: After deploying a new TGW security VPC, some flows show `DROP_NO_ROUTE`. Where can you confirm this?  
A2: **Transit Gateway Flow Logs**.

Q3: You need to verify, _before_ deployment, that a Lambda in Account A can reach an Aurora cluster in Account B over VPC peering. Which tool performs this simulation?  
A3: **Reachability Analyzer (cross-account analysis)**.

Q4: Compliance asks for a one-click report listing any subnet that can reach the public Internet across 50 accounts. Which service delivers this?  
A4: **Network Access Analyzer**.

Q5: An incident occurs at 02:17 UTC and engineers suspect a security-group change. Where do you confirm the exact API call and who made it?  
A5: **AWS CloudTrail**.

Q6: Web users report 500 ms latency spikes every five minutes. Which log source helps correlate spikes to NAT translations?  
A6: **NAT Gateway Access Logs** (analyze in CloudWatch Logs Insights).

Q7: GuardDuty raises a `Recon:PortSweep` finding. Which underlying data source triggered this?  
A7: **VPC Flow Logs** analyzed by GuardDuty.

Q8: During packet capture, you discover TLS resets but need to know whether they came from the ALB or the app. Which log pinpoints it?  
A8: **ELB Access Logs** (ALB).

Q9: A new firewall route propagates incorrectly, black-holing branch traffic. Which console gives real-time BGP and TGW route views?  
A9: **AWS Network Manager Route Analyzer**.

Q10: What is the minimal log aggregation interval supported by VPC Flow Logs when delivered to CloudWatch Logs?  
A10: **One-minute aggregation interval**.

### 5. Service endpoints for service integrations

Service endpoints let you **talk to AWS services—or your own micro-services—without ever touching the public Internet**. By swapping NAT gateways for Gateway or Interface Endpoints, publishing a SaaS over PrivateLink, or inserting inspection appliances via Gateway Load Balancer (GLB) endpoints, you slash egress costs, tighten security, and stay on the AWS backbone. Newer options such as **VPC Lattice service-network endpoints** and **ECS Service Connect** extend the pattern to layer-7 micro-service traffic, while Lambda interface endpoints eliminate the last public IPs in serverless stacks.

- **VPC Gateway Endpoints (S3 / DynamoDB)** — route-table targets that keep S3 / DynamoDB traffic inside AWS; no hourly or data processing fees.
- **Interface Endpoints (AWS PrivateLink)** — elastic network interfaces that expose AWS APIs or third-party services privately in your VPC; billed hourly + data-processing.
- **Gateway Load Balancer Endpoint (GLB-EP)** — layer-4 endpoint that forwards traffic to centralized inspection appliances via PrivateLink, auto-scaling to 100 Gbps per AZ.
- **Endpoint Service & Policy** — provider-side construct that fronts an NLB (or GWLB) and lets you publish cross-account services; policies enforce least-privilege actions.
- **Private DNS** — automatically maps the public service hostname (e.g., `s3.amazonaws.com`) to the endpoint’s private IPs when enabled.
- **VPC Lattice Service Network Endpoint** — gives a VPC private, layer-7 access to a Lattice service network spanning multiple accounts/Regions.
- **NAT Gateway vs. Endpoint Cost** — NATs charge per GB + per-hour; Gateway Endpoints are free, Interface Endpoints are cheaper than NAT at scale (< $0.01/GB).
- **Cross-Account PrivateLink** — SaaS providers expose an Endpoint Service; consumers create Interface Endpoints in their own VPCs.
- **AWS Service Connect (ECS)** — simplifies service discovery and traffic inside/between ECS clusters without public load balancers.
- **Lambda Interface Endpoint** — invoke Lambda APIs privately; no IGW, VPN, or NAT required.

**Replace NAT with Gateway Endpoints**  
“Private subnet needs S3 access with zero data-processing fees” → **Gateway VPC Endpoint (S3)**; removes NAT charges.

**Least-Privilege over PrivateLink**  
“SaaS provider must let customers call only `/submitOrder` API” → publish an **Endpoint Service** backed by an NLB and attach a restrictive **endpoint policy**.

**Cross-Account Micro-service Consumption**  
“Dev account VPC must call an internal billing API in Prod without CIDR overlap” → use **Interface Endpoint + Private DNS** across accounts.

**Inspection Appliance Insertion**  
“All egress traffic must be scanned by IDS before leaving the VPC” → route through a **Gateway Load Balancer Endpoint** to the IDS fleet.

**Layer-7 Mesh without NAT**  
“Micro-services across five accounts need auth and L7 routing, no NAT fees” → create a **VPC Lattice service network** and associate VPCs via service-network endpoints.

**Serverless without Public IPs**  
“Invoke Lambda from private subnets that lack IGW” → create an **Interface Endpoint for Lambda**; traffic stays on AWS backbone.

**ECS Service Discovery**  
“Containers in two VPCs must discover each other by short names” → enable **ECS Service Connect**; no extra load balancer needed.

Q1: A data-lake VPC moves 20 TB/day to S3 using a NAT Gateway. Costs are high. Which change cuts transfer fees to $0 and keeps traffic private?  
A1: **Create a Gateway VPC Endpoint for S3 and remove the NAT path.**

Q2: Security requires that only the `PutObject` action be allowed when applications access S3 via the endpoint. How is this enforced?  
A2: **Attach an endpoint policy restricting the allowed S3 actions.**

Q3: Your company offers an internal order-processing API to all business units via PrivateLink. What must the consumer teams create in their VPCs?  
A3: **Interface VPC Endpoints that connect to the provider’s Endpoint Service.**

Q4: To centralize TLS inspection, all outbound traffic from multiple VPCs must traverse inspection appliances without IGWs. Which endpoint type do you deploy?  
A4: **Gateway Load Balancer Endpoints**.

Q5: A micro-service in Account A (VPC 1) needs authenticated, sub-10 ms calls to a service in Account B (VPC 2) without managing NLBs or SG rules. Which 2025 feature solves this?  
A5: **Associate both VPCs to a VPC Lattice service network and use its service-network endpoints.**

Q6: Branch developers complain that `aws lambda invoke` requires an Internet proxy. What AWS networking feature removes that dependency?  
A6: **Lambda Interface VPC Endpoint (AWS PrivateLink).**

Q7: A start-up runs ECS tasks in private subnets and wants secure service discovery without ALBs. Which built-in capability should they enable?  
A7: **ECS Service Connect**.

Q8: Why might replacing a NAT Gateway with multiple Interface Endpoints **increase** cost for low-volume traffic patterns?  
A8: **Interface Endpoints incur hourly and per-GB PrivateLink charges, which can exceed NAT fees for small data volumes.**

Q9: During an audit, you need proof that traffic to DynamoDB never leaves AWS’s backbone. Which architectural element provides this guarantee?  
A9: **VPC Gateway Endpoint for DynamoDB.**

Q10: Which PrivateLink construct must a SaaS provider configure to make an NLB-fronted service available to customers?  
A10: **An Endpoint Service (service provider side).**

## Task 1.2: Prescribe security controls

### 1. Cross-account access management

Large AWS estates split workloads into **hundreds of accounts** to isolate blast radius, billing, and compliance domains. Cross-account access lets people, pipelines, or third-party tools reach only the resources they need—without sharing long-term secrets. Mastering **Organizations guardrails, IAM role trusts, and temporary STS sessions** ensures least-privilege at scale and is a favorite exam topic.

- **AWS Organizations & Service Control Policies (SCPs)** — central “deny-by-default” guardrails that apply to entire OUs; override any allow in child accounts.
- **Delegated Admin** — lets a member account manage specific Org features (e.g., IAM Access Analyzer) instead of the management account.
- **AWS Resource Access Manager (RAM)** — shares subnets, TGWs, snapshots across accounts without IAM roles.
- **IAM Roles (assume-role)** — identity with no credentials until assumed; provides scoped, temporary access.
- **AWS STS temporary credentials** — short-lived keys (15 min–12 h) returned by `AssumeRole`.
- **IAM Identity Center (formerly AWS SSO)** — centralizes workforce identities and issues _permission-set_-backed STS sessions to any account.
- **Permission Boundaries** — restrict the maximum permissions a role or user can receive.
- **External ID** — unique string in the trust policy that blocks confused-deputy attacks from third-party vendors.
- **Session Tags / ABAC** — key-value tags passed in the STS call; policies reference them for attribute-based control.
- **IAM Access Analyzer** — proves what a new policy _will_ expose before you deploy (“policy preview”).
- **Role Chaining** — one role assumes a second role; max session chain = 1 hour by default.
- **Condition keys** — `aws:PrincipalOrgID`, `aws:PrincipalArn`, etc., narrow who can assume or access resources.

**Org-wide Guardrails ↔ SCPs**  
“Block all member accounts from disabling GuardDuty” → attach an **SCP Deny** to the OU; IAM role denies won’t override it.

**Vendor Access ↔ External ID + Role Trust**  
“Billing SaaS needs read-only access to 300 accounts” → create an **assumable role with External ID** and enable **IAM Identity Center permission sets** for internal admins.

**Least-Privilege Sharing ↔ RAM vs. Cross-Account Role**  
“Share a subnet with a network team in another account, no IAM changes” → use **Resource Access Manager** instead of a role.

**Audit Exposure ↔ Access Analyzer**  
“Show what a proposed S3 bucket policy will expose before merging” → run **IAM Access Analyzer policy preview**.

**Attribute-Based Control ↔ Session Tags**  
“Developers in Team A can assume `DevRole` but only tag `Environment=Dev` on resources” → pass **session tags** and enforce with ABAC.

**Delegated Administration**  
“Security account must manage SCPs so the root account can stay locked down” → assign **Delegated Admin** for AWS Organizations.

Q1: A third-party CI/CD tool needs write access to one CodeCommit repo in Account B. Which two trust-policy elements ensure least-privilege and prevent confused-deputy attacks?  
A1: **Specify the tool’s AWS account as the principal and require a unique `ExternalId` condition.**

Q2: You attach an SCP that denies `ec2:*`. An admin in a child account tries to add an IAM policy that allows `ec2:StartInstances`. What is the net effect?  
A2: **The action is denied—SCPs override any allow in the account.**

Q3: Finance requires proof that a new KMS key policy will not grant public or cross-account access. Which service provides this before deployment?  
A3: **IAM Access Analyzer (policy preview).**

Q4: A DevOps engineer assumes **Role A**, then uses it to assume **Role B**. The original session was 45 minutes old. What is the maximum remaining duration for Role B?  
A4: **15 minutes** (role chaining cannot exceed 1 hour from the original session).

Q5: You need to share a TGW with five VPCs in different accounts without creating IAM roles. Which service do you use?  
A5: **AWS Resource Access Manager (RAM).**

Q6: A new OU must allow only `ReadOnlyAccess` except in one sandbox account. How can you enforce this?  
A6: **Attach an SCP that denies `*:*` except `iam:PassRole` & `readonly` actions, then add a _Service-Control Policy exception_ for the sandbox account.**

Q7: A script in Account A calls `AssumeRole` in Account B but fails with _Access Denied_. Which missing trust-policy element causes this if the role is for a SaaS provider?  
A7: **The required `sts:ExternalId` condition key.**

Q8: Your org wants to restrict role assume operations to requests originating inside the organization only. Which global condition key meets this?  
A8: **`aws:PrincipalOrgID` in the trust policy.**

Q9: Analysts must switch between hundreds of accounts using a central identity provider and MFA. Which AWS capability delivers this with the lowest operational overhead?  
A9: **IAM Identity Center permission sets plus MFA-backed SAML federation.**

Q10: What is the default maximum session duration for an STS token issued by `AssumeRole` when no `DurationSeconds` is specified?  
A10: **1 hour (3,600 seconds).**

### 2. Integration with third-party identity providers

Corporate users already sign in with Okta, Microsoft Entra ID (Azure AD), Ping, or Google—so AWS must trust those identities without creating long-lived IAM users. This module shows how **SAML 2.0 or OIDC federation, IAM Identity Center connectors, and SCIM provisioning** give admins single-sign-on (SSO) to _every_ AWS account, pass ABAC attributes as session tags, and avoid confused-deputy risks when onboarding external vendors.

- **SAML 2.0 federation** — XML assertions exchanged between IdP and AWS for browser-based or CLI access.
- **OIDC federation** — JSON-web-token based flow; IAM now auto-trusts public CAs, removing thumbprint hassles.
- **IAM Identity Center connectors** — out-of-the-box integrations (Okta, Entra ID, Ping) that supply SAML SSO plus **SCIM 2.0** user & group sync.
- **IdP-initiated vs. SP-initiated SSO** — whether the sign-on starts at the IdP or the AWS console (service provider).
- **Attribute-based access control (ABAC) with Session Tags** — IdP passes attributes (cost-center, project) in the assertion; policies reference them.
- **SCIM provisioning** — pushes user & group objects into Identity Center, eliminating separate HR scripts.
- **MFA enforcement** — IdP-side factor satisfies AWS MFA requirements if `MultiFactorAuthPresent` is in the SAML/OIDC claim.
- **Trust Provider ARN** — IAM resource that represents the external IdP (`arn:aws:iam::<acct>:saml-provider/Okta`).
- **AD FS, Okta, Azure AD (Entra), Auth0, Ping Federate** — common enterprise IdPs supported via SAML/OIDC.
- **Session Tags** — key-value pairs (e.g., `Department=FinOps`) passed in STS tokens for ABAC.
- **IAM Identity Center vs. legacy IAM federation** — Identity Center centralizes user assignments and MFA; legacy IAM federation requires a role per account.

**Central SSO Across 200 Accounts ↔ IAM Identity Center + SAML IdP**  
“Use existing Azure AD, no long-lived IAM users” → connect **Entra ID** to **IAM Identity Center**, enable SCIM and SAML SSO.

**CLI Access with ABAC ↔ Session Tags**  
“Developers need project-based CLI sessions” → configure IdP to include `Project` attribute; attach ABAC policies referencing `aws:PrincipalTag/Project`.

**Third-Party Vendor ↔ External Trust Provider Role**  
“Security scanner SaaS must assume a role in each account” → create a **SAML/OIDC provider ARN** + role trust that requires an **ExternalId** and restricts `aws:PrincipalOrgID`.

**Broken Logins ↔ Missing Audience or Session Tags**  
“Users receive `AccessDenied` after IdP cut-over” → verify SAML `Audience` equals `https://signin.aws.amazon.com/saml` and required tags are present.

**Fastest Deployment ↔ OIDC Thumbprint Automation**  
“Startup wants Google federation today; no cert thumbprints” → use **IAM OIDC provider** (thumbprint auto-retrieved).

Q1: A company uses Okta and wants Just-in-Time user creation in AWS without scripts. Which protocol/service pairing enables this?  
A1: **SAML 2.0 for SSO + SCIM 2.0 provisioning via IAM Identity Center**.

Q2: Your IdP assertion lacks the attribute `Department`, but ABAC policies reference `aws:PrincipalTag/Department`. What is the runtime effect?  
A2: **All requests that rely on that tag evaluate to “Deny” because the session tag is absent.**

Q3: An OIDC federation setup fails when the provider rotates its TLS cert. Which July 2024 IAM improvement prevents this outage?  
A3: **IAM now trusts the IdP’s public root CA automatically—no thumbprint rotation required.**

Q4: Security requires that the SSO token include MFA status. Which SAML element must the IdP send?  
A4: **`<saml:Attribute Name="https://aws.amazon.com/SAML/Attributes/PrincipalTag:MultiFactorAuthPresent">true</saml:Attribute>`** (or equivalent OIDC claim).

Q5: A developer portal must let contractors log in to a single AWS account only. Which flow meets least-privilege without Organizations?  
A5: **Create an IAM SAML provider and per-contractor assumable role scoped to that account.**

Q6: Identity Center users need programmatic access through the AWS CLI v2. Which credential process delivers short-lived keys?  
A6: **`aws sso login` (uses the Identity Center credential helper with STS tokens).**

Q7: A SAML assertion’s `Audience` is set to `sts.amazonaws.com` but users are signing in to the console. What error occurs?  
A7: **`AccessDenied` because the Audience does not match `https://signin.aws.amazon.com/saml`.**

Q8: How can you limit a vendor role so it can only be assumed from your organization’s accounts?  
A8: **Add `StringEquals {"aws:PrincipalOrgID":"o-abc123"} ` to the role’s trust policy.**

Q9: An admin chains roles: IdP → `RoleA` → `RoleB`. The original session was 50 minutes. What is the maximum time left in `RoleB`?  
A9: **10 minutes (role chaining cannot exceed 60 minutes from the initial STS issue).**

Q10: Which Identity Center feature lets you map projects in the IdP to permission sets automatically?  
A10: **SCIM group synchronization combined with permission-set assignments.**

### 3. Encryption strategies for data at rest and in transit

AWS gives you multiple layers of cryptography—from **hardware-isolated HSM keys** to **TLS 1.3 endpoints**—so you can meet GDPR, HIPAA, and PCI while still hitting performance SLAs. The exam loves “trade-off” puzzles: _Bring-your-own-key vs. AWS-managed_, _single-Region vs. multi-Region keys_, _CloudHSM vs. KMS_, or _ACM automation vs. self-signed certs_. Know **where** to encrypt (application, service, network), **how** to rotate keys with zero downtime, and **which compliance level** (FIPS 140-2) each option satisfies.

- **AWS KMS (customer-managed, AWS-managed, multi-Region keys)** — fully managed key service; multi-Region keys replicate with single-digit-second latency for DR.
- **AWS KMS External Key Store (XKS)** — lets you keep encryption keys in an on-prem or partner HSM while still using KMS APIs.
- **CloudHSM custom key store** — dedicated, FIPS 140-2 Level 3 HSM cluster that KMS treats as a backing key store.
- **Envelope Encryption** — data encrypted with a data key, which is itself encrypted by a KMS CMK; minimizes KMS calls.
- **Client-side encryption SDK** — libs that encrypt before upload (S3, DynamoDB) so AWS never sees plaintext.
- **TLS 1.3 endpoints** — ALB, CloudFront, API Gateway, and Global Accelerator now negotiate TLS 1.3 for faster handshakes.
- **ACM / ACM Private CA** — issues and renews public or private certificates; integrates with ELB, CloudFront, API GW.
- **Default encryption at rest (EBS, S3, EFS, FSx)** — turned on by default in new Regions; uses AWS-managed KMS keys.
- **Server-Side Encryption** — SSE-KMS, SSE-S3, SSE-C variants for S3; SSE-KMS offers audit and rotation.
- **Database TLS** — RDS, Aurora, and Redshift support TLS 1.2+/SSL for client connections.
- **Private CA certificate rotation** — ACM PCA automates rotation via Lifecycle events.
- **AWS Nitro encryption in transit** — Nitro cards encrypt VPC data plane traffic between instances transparently.
- **MACsec for Direct Connect** — layer-2 802.1AE encryption at up to 100 Gbps on dedicated or hosted DX links.

**Disaster Recovery Key Strategy ↔ Multi-Region KMS Keys**  
“Backup apps must decrypt data in us-east-1 and eu-central-1 during fail-over” → use **multi-Region KMS keys** to avoid copy-and-re-encrypt overhead.

**FIPS 140-2 Level 3 Requirement ↔ CloudHSM Custom Key Store**  
“Regulated workload needs Level 3 HSM with customer control” → create a **CloudHSM cluster** and configure **KMS custom key store**.

**External Compliance Key Ownership ↔ XKS**  
“Bank must keep root keys in their data center” → integrate **KMS External Key Store**; KMS makes API calls but key material never leaves on-prem.

**Network-Layer Encryption ↔ MACsec vs. TLS**  
“100 Gbps DX link must be line-rate encrypted without IPsec overhead” → enable **MACsec on Direct Connect**.

**TLS Handshake Latency ↔ TLS 1.3 Endpoints**  
“Global users see slow first-byte during handshake” → switch ALB/CloudFront listeners to **TLS 1.3** for 1-RTT setup.

**Compute Traffic Confidentiality ↔ Nitro Encryption**  
“Inter-AZ traffic between EC2 instances must meet ‘encryption in transit’ audit” → rely on **Nitro–based transparent encryption**; no app changes.

Q1: A healthcare app needs cross-Region disaster recovery with RTO < 1 h and must avoid re-encrypting 10 TB of S3 data. What key strategy meets this?  
A1: **Use multi-Region KMS customer-managed keys; replicate data and key together.**

Q2: Your security policy mandates FIPS 140-2 Level 3 hardware protection for keys. Which AWS option satisfies this?  
A2: **Create a CloudHSM cluster and set it as a custom key store for AWS KMS.**

Q3: A financial institution must hold its master keys on-prem but still use S3 SSE-KMS. Which KMS feature enables this?  
A3: **AWS KMS External Key Store (XKS).**

Q4: Developers propose client-side encryption for objects, but compliance needs AWS-managed rotation and audit logs. Which server-side mode meets both?  
A4: **SSE-KMS** (server-side, KMS-backed, auditable).

Q5: A Direct Connect 100 Gbps link must be encrypted without affecting throughput. Which technology do you choose?  
A5: **MACsec on the DX circuit.**

Q6: An app uses ACM-issued certs on ALB but handshake time is high. What config change reduces latency with zero code change?  
A6: **Enable TLS 1.3 on the ALB listener.**

Q7: S3 buckets use SSE-S3 today; audit demands per-object key rotation via KMS. What migration is required?  
A7: **Switch from SSE-S3 to SSE-KMS and specify a customer-managed CMK.**

Q8: How often can you rotate a customer-managed KMS key without re-encrypting data?  
A8: **Automatically every 365 days via KMS key rotation (creates a new backing key).**

Q9: An IoT device fleet uses MQTT with TLS 1.2; you need forward-secrecy and faster handshakes. What protocol upgrade meets this?  
A9: **Upgrade to TLS 1.3 endpoints on IoT Core / ALB.**

Q10: Which AWS service automatically applies encryption _both_ at rest and in transit using the Nitro system with no user action?  
A10: **Amazon FSx for ONTAP (and other Nitro-based services inherit this).**

### 4. Centralized security event notifications and auditing

Modern AWS estates funnel **all API activity, threat findings, and compliance drift** into a few _delegated admin_ accounts (“Audit” and “SecOps”) so teams get one source of truth and on-call pagers fire only for actionable issues. The key is to normalize data (ASFF), auto-enable services as new accounts arrive, and wire outputs to EventBridge → SNS/ChatOps without brittle Lambda ETL. This module shows which service is _authoritative_ for each log or finding type and how Control Tower guardrails plus Organizations hooks keep coverage automatic.

- **AWS Security Hub (CSPM)** — aggregates & normalizes findings into **AWS Security Finding Format (ASFF)**; computes compliance scores across accounts.
- **Amazon GuardDuty** — near-real-time threat intel; **delegated admin** auto-enables GuardDuty in new Org accounts.
- **CloudTrail organization trails** — authoritative record of every API call across all accounts, delivered to a central S3 bucket.
- **CloudWatch Logs & Insights** — stores/query flow logs, Network Firewall logs, and custom app logs for incident triage.
- **AWS Control Tower detective guardrails** — Org-wide AWS Config rules that monitor drift (e.g., S3 public access) and surface violations in Security Hub.
- **AWS Config aggregators** — pull Config snapshots & compliance state from all Regions/accounts into one view.
- **AWS Audit Manager** — maps evidence (CloudTrail, Config) to frameworks (PCI DSS, CIS) and auto-generates reports.
- **Amazon EventBridge rule “Security Hub Findings – Imported”** — catches every new/updated Security Hub finding for routing to SOAR, Slack, or PagerDuty.
- **SNS topics for alerting** — fan-out findings to e-mail, SMS, or ChatOps.
- **Amazon Detective** — interactive graph that reconstructs entities & timelines from GuardDuty + CloudTrail for investigations.
- **Amazon Macie** — PII/PCI discovery and DLP; sends findings to Security Hub for unified triage.
- **Network Firewall log delivery** — sends flow & alert logs to CloudWatch/S3 for central analysis.
- **S3 Security Lake / custom data lake** — long-term, queryable store (Athena, SIEM) for multi-source security logs.
- **Delegated Admin accounts** — Org roles that own Security Hub (“SecOps”) and CloudTrail/Config (“Audit”) so root stays locked.

**Unified Findings ↔ Security Hub ASFF**  
“CISO wants one dashboard for GuardDuty, Inspector, and Config findings” → enable **Security Hub** across Org; ASFF normalizes feeds.

**Auto-Enable Threat Intel ↔ GuardDuty Delegated Admin**  
“New accounts must have threat detection on Day-0” → set a **GuardDuty delegated admin** & `AUTO-ENABLE = ALL`.

**Authoritative API Logs ↔ CloudTrail Org Trail**  
“Forensic team needs every API call across 200 accounts” → create a **CloudTrail organization trail** to a central S3 bucket.

**Drift Detection ↔ Control Tower Detective Guardrails**  
“Flag if S3 buckets become public in any child OU” → rely on **Control Tower detective guardrail** (backed by Config).

**Real-Time Routing ↔ EventBridge Rule**  
“High-severity findings must page Slack instantly” → build **EventBridge rule** matching `Security Hub Findings – Imported` → SNS → Lambda/Slack.

Q1: Which service is the **single authoritative source** for compliance scores and normalizes all findings into ASFF?  
A1: **AWS Security Hub**.

Q2: How do you ensure GuardDuty is enabled automatically in every new AWS account created in the organization?  
A2: **Designate a GuardDuty delegated admin and set AUTO-ENABLE = ALL**.

Q3: Where do you configure an EventBridge pattern that matches `source:"aws.securityhub"  detail-type:"Security Hub Findings – Imported"`?  
A3: **In Amazon EventBridge (rule targeting Security Hub findings)**.

Q4: A SOC analyst needs to trace an attacker’s IAM role pivot across multiple accounts and Regions. Which AWS service builds entity timelines automatically?  
A4: **Amazon Detective**.

Q5: Compliance requires immutable, five-year retention of all API activity for every Region. Which log solution meets this?  
A5: **CloudTrail organization trail → S3 with object-lock & replication**.

Q6: Your architecture team wants a single dashboard of Config rule compliance across 50 accounts. What construct delivers this?  
A6: **AWS Config aggregator**.

Q7: A critical S3 bucket goes public, but Security Hub did **not** raise a finding. Which control is missing?  
A7: **Enable the Control Tower detective guardrail / Config rule for S3 public access**.

Q8: To route “High” or “Critical” findings only, which Security Hub integration pattern do you filter on in EventBridge?  
A8: **Filter the `detail.findings[0].Severity.Label` field in the `Security Hub Findings – Imported` event**.

Q9: What format must third-party products use to import findings into Security Hub?  
A9: **AWS Security Finding Format (ASFF)**.

Q10: In a multi-account landing zone, which two _delegated_ accounts typically own (a) CloudTrail/Config logs and (b) Security Hub/GuardDuty operations?  
A10: **“Audit” account for CloudTrail/Config and “SecOps” account for Security Hub & GuardDuty**.

## Task 1.3: Design reliable and resilient architectures

### 1. Disaster recovery based on RTO and RPO

Disaster-recovery (DR) architecture is the balancing act between **downtime (RTO), data loss (RPO), and cost**. AWS offers everything from inexpensive cross-Region backups to sub-second active/active databases, but you must match the pattern—**Backup & Restore, Pilot Light, Warm Standby, or Multi-Site Active/Active**—to the exact SLA the business commits to. The exam loves numeric targets (“≤ 15 min RTO, < 5 min RPO”) and will penalize designs that miss cross-Region DNS health checks, forget to replicate KMS keys, or overspend on always-on capacity.

- **Recovery Time Objective (RTO)** — maximum tolerable downtime before service must be restored.
- **Recovery Point Objective (RPO)** — maximum tolerable data loss measured in time.
- **AWS Elastic Disaster Recovery (AWS DRS)** — block-level replication service that spins up target EC2 instances in minutes.
- **Pilot Light** — minimal core services (DB + infra templates) always running; rest launched on demand at failover.
- **Warm Standby** — scaled-down but fully functional stack running in secondary Region; scaled out on failover.
- **Multi-Site Active/Active** — all Regions serve traffic simultaneously; near-zero RTO/RPO but highest cost.
- **Route 53 Application Recovery Controller (ARC)** — safe-switch tool that monitors readiness & issues failover DNS updates or cell-based zoning changes.
- **Cross-Region Replication** — S3 CRR, DynamoDB global tables, EFS/FSx replication; async unless otherwise noted.
- **Aurora Global Database** — primary Region writes asynchronously (< 1 s typical lag) to up to five read-only secondaries; promotes in < 1 min.
- **Multi-Region KMS keys** — replica keys that avoid re-encrypting data during Region failover.
- **S3 Replication & Versioning** — ensures immutable, point-in-time object copies; versioning supports accidental-delete rollback.
- **Route 53 fail-over routing** — health-check-driven DNS records that shift traffic to standby endpoints.
- **Amazon Backup Vault Copy** — scheduled cross-Region copy of backups with separate retention policies.
- **CloudFront Regional Fail-over** — origin-failover and multi-origin policies to shift edge traffic on outage.
- **CloudEndure Migration (legacy)** — predecessor to AWS DRS; still referenced in older docs/exams.

**Numeric SLA Matching**  
“≤ 15 min RTO & < 5 min RPO, tight budget” → choose **Warm Standby with AWS DRS** (replication < sec, minimal always-on capacity).

**Pilot Light vs. Warm Standby**  
“Only the database must stay warm; app servers can launch at failover” → **Pilot Light**, not Warm Standby.

**Active/Active Cost Trade-off**  
“Zero downtime, global users” → **Multi-Site Active/Active** with Aurora Global Database + Route 53 latency routing; accept egress fees.

**KMS Replication Gotcha**  
“Encrypted backups must be readable after failover” → enable **multi-Region KMS keys**; single-Region CMKs break restore.

**Route 53 Health Checks**  
“Need automatic DNS fail-over” → attach **Route 53 fail-over routing** or **ARC readiness checks** to Route 53 records.

Q1: A workload must recover in under 1 hour with < 15 minutes of data loss. Which DR pattern meets this at the lowest ongoing cost?  
A1: **Warm Standby** (minimal running capacity + continuous replication).

Q2: Your database writes cannot tolerate more than 5 seconds of data loss. Which AWS database feature delivers this?  
A2: **Aurora Global Database with < 1 s async lag and < 1 min promotion.**

Q3: S3 buckets replicate cross-Region, but restores fail due to key-access errors. What’s missing?  
A3: **Multi-Region replicas of the KMS customer-managed key.**

Q4: Compliance dictates FIPS 140-2 L3 keys and RPO 0 s. Which combo satisfies both?  
A4: **CloudHSM-backed custom key store + synchronous multi-AZ Aurora cluster** (RPO 0 s within Region).

Q5: An e-commerce site must fail over global users automatically when the primary Region goes down, with no code changes. Which two AWS services achieve this?  
A5: **Route 53 Application Recovery Controller (ARC) + Route 53 fail-over DNS records.**

Q6: Pilot-Light DR is chosen. Which components are _always_ running in the DR Region?  
A6: **Core databases, replicated storage, and minimal IAM/KMS infrastructure; app tiers launch only at failover.**

Q7: AWS DRS continuous replication copies 5 TB/day; costs spike. Which setting reduces egress fees without raising RPO beyond 15 minutes?  
A7: **Use compression & change-block tracking in AWS DRS; throttle replication bandwidth.**

Q8: Active/Active across us-east-1 and eu-west-1 doubles data-transfer charges. What less-expensive pattern still gives sub-15 min RTO?  
A8: **Warm Standby with pre-provisioned but right-sized instances in the secondary Region.**

Q9: Which service provides a centralized, audited “toggle” to shift traffic between cells or Regions?  
A9: **Route 53 Application Recovery Controller (ARC) readiness & routing controls.**

Q10: Legacy docs mention CloudEndure for DR. What is its fully managed successor?  
A10: **AWS Elastic Disaster Recovery (AWS DRS).**

### 2. Automatic failure recovery architectures

Architectures that **self-heal in seconds** rely on automated health checks and orchestration—not humans on a bridge call. From **EC2 Auto Recovery** to **Route 53 fail-over** and **ECS task rescheduling**, AWS gives you building blocks that replace or re-route unhealthy components and keep SLAs intact. The exam wants you to spot _instance- vs. application-level_ health checks, understand what state is lost, and pick the control plane that meets “no manual intervention within 60 s.”

- **EC2 Auto Recovery** – moves an impaired instance to fresh hardware when system checks fail; zero config on new Nitro types.
- **Auto Scaling Group (ASG) health checks** – combines EC2 system checks + ELB target checks to terminate & replace bad instances.
- **Lifecycle hooks** – pause ASG scale-in/out to run scripts (drain, snapshot) before the instance is removed or put in service.
- **ALB/NLB target-group health checks** – HTTP/TCP probes that mark targets “unhealthy” and stop routing until recovered.
- **Route 53 health checks & fail-over routing** – DNS evaluates an HTTPS/TCP endpoint every 30 s (or 10 s) and flips to standby.
- **AWS Auto Scaling policies** – service umbrella covering EC2 ASG, DynamoDB on-demand scaling, Aurora Serverless v2, etc.
- **ECS Service Auto-Healing** – service scheduler restarts tasks to maintain desired count; leverages container-level health checks.
- **Lambda regional/AZ redundancy** – Lambda automatically spreads function instances across AZs; if one AZ degrades, invoke runs elsewhere.
- **Lambda Destinations** – route successes or failures to SQS/SNS/EventBridge for durable retries or alarms.
- **Step Functions retries** – state-machine rules for exponential back-off and catch/relay of task failures.
- **CloudWatch Alarms + SNS** – metric thresholds trigger notifications or recovery actions (e.g., `Recover this instance`).
- **AWS Systems Manager Automation** – runbooks that reboot, patch, or restore resources after alarm triggers.
- **Well-Architected Reliability BP “Automate Healing”** – prescribes auto-scaling and load balancing at every layer.

**Host Failure in 60 s ↔ EC2 Auto Recovery**  
“Single EC2 must reboot on hardware fault with no ASG” → enable **EC2 Auto Recovery**; CloudWatch ‘recover’ action boots on new host.

**Stateless Web Tier ↔ ASG + ALB Health**  
“Replace any unhealthy instance within a minute” → use **ASG** with **ELB target-group health checks** (grace period = 0).

**Graceful Drain ↔ Lifecycle Hooks**  
“App needs 30 s to flush logs before termination” → add **ASG lifecycle hook** to call an SSM doc that drains.

**Container Crash ↔ ECS Auto-Healing**  
“ECS task exits with 137; service must maintain 3 tasks” → **ECS service scheduler** restarts the task automatically.

**AZ Outage ↔ Route 53 Fail-over or Lambda Redundancy**  
“AZ A lost power; keep Lambda/API alive” → rely on **Lambda AZ redundancy** or deploy **fail-over DNS** between regional APIs.

**No State Loss Allowed?**  
“Redis cache must persist sessions” → ASG replacement alone is not enough; use **Multi-AZ clusters** or backup/restore.

Q1: A lone critical EC2 instance must restart on new hardware if the underlying host fails, with **no scaling group**. Which feature meets this?  
A1: **EC2 Auto Recovery**.

Q2: An ASG should remove targets from the ALB only after a custom script finishes log upload. What ASG capability enables this?  
A2: **Lifecycle hooks** with a `Wait` state calling SSM automation.

Q3: A micro-service must keep exactly five tasks running in ECS; if one segfaults it should respawn automatically. Which native mechanism handles this?  
A3: **ECS Service Auto-Healing (desired count enforcement)**.

Q4: Users must be redirected to a standby Region when the primary `/health` endpoint returns 500 for 60 s. Which AWS combo solves this?  
A4: **Route 53 health check + fail-over routing policy**.

Q5: After an AZ outage, Lambda invocations in that AZ fail. What built-in feature keeps the function available without changes?  
A5: **Lambda automatically runs in remaining AZs (regional redundancy)**.

Q6: You need a pager alert whenever an ASG scales **in** so ops can verify state flush. Which signal and service chain achieves this?  
A6: **CloudWatch alarm on `GroupInServiceInstances` → SNS topic for on-call.**

Q7: A Step Functions workflow must retry a flaky API call up to three times with exponential back-off. Which language block defines this?  
A7: **`"Retry": [{"ErrorEquals":["States.ALL"],"IntervalSeconds":1,"BackoffRate":2,"MaxAttempts":3}]`** in the task state.

Q8: A workload runs in “static stability” mode with pre-provisioned capacity in two AZs. Which Well-Architected principle does this follow?  
A8: **Automate Healing on all layers** (REL11-BP03).

Q9: An ALB marks instances unhealthy due to 5xx errors, but ASG does **not** replace them. What mis-configuration causes this?  
A9: **ASG health check type set to “EC2” instead of “ELB.”**

Q10: Which Lambda feature routes failed asynchronous invocations to a queue or topic for later inspection, avoiding silent data loss?  
A10: **Lambda Destinations (on Failure target)**.

### 3. Scale-up and scale-out architecture decisions

When performance bottlenecks appear—CPU pegged at 90 %, hot DynamoDB partitions, single-AZ limits—you must decide whether to **scale up (vertical)** or **scale out (horizontal)**. AWS offers ever-larger instance families, load balancers, auto-scaling primitives, serverless autoscaling, and price-performance wins like **Graviton**. The exam tests your ability to pick the **lowest-cost, future-proof path** that meets 10× growth without breaking licensing, stateful sessions, or consistency guarantees.

- **Vertical Scaling (scale-up)** — move to a larger EC2 instance or Aurora DB class; limited by family max size and licensing.
- **Horizontal Scaling (scale-out)** — add more nodes behind ELB/ASG/ECS; improves availability and shard capacity.
- **EC2 instance family right-sizing / AWS Compute Optimizer** — recommends better families (e.g., **Graviton**) for 40 % price-performance gains. :contentReference[oaicite:0]{index=0}
- **Elastic Load Balancing (ALB/NLB)** — distributes traffic across AZs; session stickiness options for stateful apps.
- **Auto Scaling Groups (ASG)** — maintains desired instance count; scale policies on CPU, SQS depth, or custom metrics.
- **Aurora Read Replicas** — up to 15 replicas per Region; reader endpoint load-balances reads.
- **Aurora Serverless v2** — granular, ACU-based compute that now scales **from 0 to thousands of ACUs**.
- **DynamoDB partition-split / Adaptive Capacity** — auto-balances hot partitions without manual sharding.
- **EKS/ECS cluster scaling** — Cluster Autoscaler or Karpenter adds nodes; service scheduler reschedules pods/tasks.
- **ElastiCache Cluster-Mode** — sharded Redis/Memcached up to 250 nodes; resharding online.
- **S3 concurrent multipart uploads** — parallelize parts for > GB files; each PUT part is independent.
- **Provisioned Concurrency (Lambda)** — keeps functions warm to avoid cold starts under spikes.
- **Graviton migration** — Arm-based instances with up to 40 % better price-performance.

**CPU Bottleneck ↔ Vertical vs. Horizontal**  
“Instance at 90 % CPU, 10× growth forecast” → if monolithic licensed DB, **scale-up** to r8i.metal; else put behind **ASG** & **ALB** for horizontal elasticity.

**Aurora Read vs. Serverless**  
“Read traffic doubles nightly, writes steady” → add **Aurora read replicas** + reader endpoint.  
“Intermittent batch jobs” → switch to **Aurora Serverless v2** (scales 0–X ACUs).

**DynamoDB Hot Partition**  
“Partition throttle errors on key 123” → rely on **Adaptive Capacity**, or **split partition** if > 3000 RCU/1000 WCU.

**Container Surge**  
“EKS pods pending during traffic spike” → enable **Karpenter / Cluster Autoscaler** and turn on **ALB Ingress** for immediate node scale-out.

**Lambda Spikes**  
“Latency SLA 200 ms under burst” → configure **Provisioned Concurrency**; horizontal scaling is implicit.

**License-Locked Monolith**  
“Commercial DB licensed per-core” → vertical scale on fewer, bigger cores; horizontal scaling violates license.

Q1: A Java API in one AZ pegs at 90 % CPU during sales; forecasts say 10× traffic next quarter. Stateless, no session stickiness. Which architecture change is most cost-effective?  
A1: **Create an ASG across 3 AZs behind an ALB (horizontal scale-out).**

Q2: An Oracle DB licensed per-socket must ingest 4× data next year but can’t shard. What meets the goal?  
A2: **Vertical scale-up to a larger EC2 / RDS instance class.**

Q3: Read-heavy workload doubles at night; write volume flat. Which Aurora feature minimizes cost and latency?  
A3: **Add Aurora read replicas and use the reader endpoint.**

Q4: Batch jobs run sporadically; idle DB time costs money. Which option auto-scales to zero?  
A4: **Aurora Serverless v2 (now supports 0 ACU pause).**

Q5: DynamoDB table throttles on a single partition key during flash sales. Which native feature resolves this without redesign?  
A5: **Adaptive Capacity (automatic partition-split).**

Q6: Lambda cold starts hurt a 99-pctl latency SLA when traffic bursts. What AWS setting fixes this?  
A6: **Provisioned Concurrency on the function.**

Q7: Compute Optimizer shows 30 % idle CPU on r6g instances. What migration saves money with equal performance?  
A7: **Move to Graviton-based r7g for ~40 % price-performance gain.**

Q8: ECS service must keep 5 tasks running; a container OOMs. How is capacity restored automatically?  
A8: **ECS service scheduler restarts the task and, if needed, triggers cluster autoscaling.**

Q9: A Redis cluster reaches node memory limits. Licenses allow unlimited nodes but single-thread constraints apply. Which scaling strategy?  
A9: **Enable ElastiCache Cluster-Mode and add shards (horizontal scale-out).**

Q10: Large media uploads stall at 5 GB. Which S3 technique accelerates and parallelizes the upload?  
A10: **Multipart upload with concurrent part uploads (horizontal client-side scaling).**

### 4. Backup and restoration strategy

### 4. Backup and restoration strategy

Seven-year retention, cross-Region copies, and **zero-touch restores in < 30 min** demand more than nightly scripts.  
AWS Backup + Organizations gives you _policy-driven_ protection at scale, while **Vault Lock** and **multi-Region KMS keys** guarantee immutability and decrypt-anywhere recovery. The exam rewards designs that use these managed controls—not ad-hoc Lambda jobs—and punishes answers that miss encryption alignment or immutable retention.

- **AWS Backup plans & vaults** — JSON plans define frequency/retention; vaults store encrypted recovery points.
- **Cross-Account / Cross-Region copy** — copies backups to another account/Region for DR; set in the plan wizard.
- **Backup Vault Lock** — Governance/Compliance modes make retention **immutable**, blocking deletes—even by root.
- **AWS Organizations backup policies** — apply plans automatically to OUs; no per-account setup.
- **Delegated Admin for Backup / Audit Manager** — non-management account that owns backup & audit reporting.
- **AWS Backup Audit Manager** — maps Backup events to compliance frameworks and produces evidence.
- **Point-in-Time Recovery (PITR)** — continuous logs for RDS / DynamoDB let you restore to any second in the last 35 d.
- **EBS Snapshots & Fast Snapshot Restore (FSR)** — FSR makes new volumes _fully performant_ immediately after restore.
- **EFS/Lustre backup integration** — AWS Backup native support for file systems and FSx variants.
- **S3 Versioning + Lifecycle** — keep immutable copies; move to Glacier tiers over time.
- **S3 Glacier Instant Retrieval / Deep Archive** — lowest-cost, milliseconds or hours retrieval for cold data.
- **Multi-Region KMS keys** — replicate CMKs so encrypted backups restore cross-Region without re-encrypt.
- **AWS Storage Gateway (Tape Gateway)** — VTL interface that writes to Glacier classes; ejects virtual tapes for infinity retention.
- **Data Lifecycle Manager (DLM)** — automates EBS snapshot creation/expiration; complements AWS Backup.
- **Backup Vault Notifications (EventBridge + SNS)** — 2025 update adds index & job events for proactive paging.

**Immutable 7-Year Retention**  
“Regulators demand WORM backups” → **Backup Vault Lock in Compliance mode**; Governance mode can still be overridden.

**Org-Wide Visibility**  
“Centrally monitor 300 accounts” → use **Backup policies + Delegated Admin**; avoid per-account IAM roles.

**Cross-Region Key Mismatch**  
“Encrypted restore fails in us-west-2” → you forgot **multi-Region KMS replicas**; single-Region CMK can’t decrypt.

**30-Minute Restore SLA**  
“Need full-performance EBS volume in 15 min” → enable **Fast Snapshot Restore** in required AZs.

**Alerting Pipeline**  
“Page on failed copy jobs” → create **EventBridge rule + SNS** on `COPY_JOB_FAILED`.

Q1: Compliance mandates seven-year, immutable backups across all Regions. Which AWS feature enforces this?  
A1: **Backup Vault Lock in Compliance mode**.

Q2: A security team must _centrally_ ensure every new account gets a 30-day daily backup plan. What Organizations feature do you use?  
A2: **Backup policies applied to the OU.**

Q3: Restoring an encrypted RDS snapshot copied to eu-west-1 fails with “KMS key not found.” What’s missing?  
A3: **A multi-Region replica of the KMS CMK in eu-west-1.**

Q4: A forensic drill requires EBS volumes to deliver full IOPS immediately after restore. Which setting meets this < 30 min SLA?  
A4: **Enable Fast Snapshot Restore on the snapshot in the target AZ.**

Q5: Backup operators need a daily report of non-compliant resources without accessing the management account. Which service provides it?  
A5: **AWS Backup Audit Manager via Delegated Admin.**

Q6: To cut cold-data storage costs but keep millisecond access, which S3 tier should a backup plan target?  
A6: **S3 Glacier Instant Retrieval.**

Q7: An S3 bucket uses versioning and lifecycle rules to Glacier Deep Archive. What additional feature guards against accidental deletes?  
A7: **S3 object lock (WORM) or backup via Vault Lock for immutable retention.**

Q8: After enabling Vault Lock Governance mode, an admin with `aws:PrincipalTag=BackupAdmin` must delete a test vault. What else is required?  
A8: **`BypassGovernanceRetention` permission granted in IAM.**

Q9: How can you ensure DynamoDB tables support point-in-time recovery across accounts without writing code?  
A9: **Include DynamoDB resources in an AWS Backup plan with PITR enabled; use cross-Account copy.**

Q10: Which EventBridge pattern matches a failed cross-Region copy to page on-call?  
A10: **`detail-type:"AWS Backup Copy Job State Change" AND detail.state:"FAILED"` routed to an SNS topic.**

## Task 1.4: Design a multi-account AWS environment

### 1. Account structure for organizational requirements

Designing a **multi-account landing zone** is the first control you set for security, billing, and blast-radius isolation in AWS. By grouping accounts into **purpose-built Organizational Units (OUs)**—such as _Security_, _Infrastructure_, and _Workloads_—you apply preventative guardrails (SCPs), delegate shared services, and centralize logging **without** granting root-level trust between workloads. This module maps the landing-zone patterns AWS recommends (Control Tower, Landing Zone Accelerator, SRA) to exam scenarios that test scale, compliance, and least-privilege.

- **AWS Organizations** — service that creates and manages multiple AWS accounts under one billing entity.
- **Management Account** — root account that owns billing and enables key Org features; should do nothing else.
- **Organizational Units (OUs)** — logical folders (_Workload_, _Security_, _Sandbox_, _Infrastructure_) for policy inheritance.
- **AWS Control Tower Landing Zone** — turnkey setup that deploys Guardrails, Log Archive, Audit, and Account Factory.
- **Account Factory / Account Vending Machine (AVM)** — automated pipeline that provisions new accounts with baseline config.
- **Log Archive Account** — immutable S3 buckets for CloudTrail and Config logs; denies writes from everywhere but Org.
- **Shared Services Account** — hosts networking, AD DS, CI/CD, or patch repositories consumed by other accounts.
- **Delegated Admin** — lets member accounts manage specific Org services (e.g., Security Hub, IAM Identity Center).
- **Service Control Policies (SCPs)** — Org-level JSON policies that set maximum permissions (“guardrails”).
- **Tag Policies / Cost-Allocation Tags** — enforce standardized tags for FinOps and chargeback.
- **IAM Identity Center Permission Sets** — SSO role bundles applied across accounts.
- **AWS Landing Zone Accelerator** — opinionated CDK stacks that deploy Control-Tower-compatible blueprints.
- **AWS Security Reference Architecture (SRA)** — prescriptive OU and guardrail model for security services.
- **Alternate Contacts** — security / billing / ops emails required for every account.
- **Environment-based splits** — separate _prod_, _dev_, _test_ accounts for each workload.

**Shared Security Tooling**  
“Centralize GuardDuty and Security Hub for 200 accounts” → create a **Security OU** with a **delegated-admin SecOps account**.

**Immutable Logs**  
“Compliance demands WORM audit logs” → route CloudTrail to **Log Archive account** with Object Lock; deny `DeleteObject`.

**OU-Level Guardrails**  
“Block creation of public S3 buckets in all prod accounts” → attach an **SCP deny** to the **Prod OU**, not individual accounts.

**Account Factory Use**  
“DevOps needs to spin up sandbox accounts on demand” → use **Control Tower Account Factory**; applies baseline SCPs automatically.

**Billing Isolation**  
“Finance wants separate invoices per business unit” → map each BU to its own **Workload OU** and enable **Cost-Allocation Tags**.

Q1: Where should CloudTrail and Config logs be stored to guarantee immutability and centralized visibility?  
A1: **A dedicated Log Archive account within the Security OU**.

Q2: You need to block all member accounts from disabling AWS Config. Which governance mechanism is most appropriate?  
A2: **Service Control Policy (SCP) attached to the target OU**.

Q3: A newly created account must automatically have GuardDuty enabled and findings aggregated. What Control Tower feature accomplishes this?  
A3: **A Security OU with delegated-admin GuardDuty and an Account Factory workflow that enrolls the account.**

Q4: Developers require admin permissions only in sandbox accounts but read-only in prod. How do you implement this at scale?  
A4: **IAM Identity Center permission sets applied by OU (Admin in Sandbox OU, ReadOnly in Prod OU).**

Q5: Which landing-zone component provisions accounts with VPC, baseline IAM roles, and centralized logging already configured?  
A5: **Account Factory / Account Vending Machine.**

Q6: A third-party SOC tool needs cross-account read access to Security Hub findings but should never assume root. What is the recommended approach?  
A6: **Create a delegated-admin SecOps account and grant the tool an assumable role there; share findings via Organizations.**

Q7: In the Security Reference Architecture, where do you place shared networking resources like Transit Gateway?  
A7: **Shared Services account inside the Infrastructure (or Network) OU.**

Q8: An SCP is attached directly to a single prod account, causing management overhead. What is the better practice?  
A8: **Attach the policy to the parent Prod OU so it propagates to all prod accounts.**

Q9: Control Tower detects drift because an admin edited GuardDuty settings in a member account. Where are these violations surfaced?  
A9: **Landing Zone dashboard (Control Tower) and AWS Config aggregator in the Audit account.**

Q10: Which Organizations feature enforces a company-wide tagging standard such as `CostCenter` or `Environment`?  
A10: **Tag Policies.**

### 2. Central logging and event notification strategy

A well-designed landing zone funnels **every API call, configuration change, and threat finding** into a single, immutable log store—then fans out high-severity alerts to on-call in seconds. This module shows how an **organization trail**, **Log Archive account**, and **EventBridge-to-SNS pipeline** deliver seven-year retention, near-real-time notifications, and auditor self-service, all without per-account scripts.

- **Organization Trail (CloudTrail)** — one trail created in the management or delegated _Audit_ account that captures API activity from every account and Region.
- **Central S3 Log Bucket + KMS** — immutable, versioned bucket (often in the Log Archive account) encrypted with customer-managed keys.
- **AWS Control Tower Log Archive Account** — dedicated account that owns CloudTrail, Config, VPC Flow Logs, and Object Lock buckets.
- **AWS Config Aggregator** — aggregates Config snapshots and compliance status from all Regions/accounts into the Audit account.
- **Amazon Security Lake** — tiered S3 data lake that normalizes security logs (CloudTrail, VPC Flow Logs, etc.) for Athena/OpenSearch queries.
- **Amazon EventBridge (org-wide bus)** — organization-level event bus that receives Security Hub, GuardDuty, and CloudTrail events.
- **SNS Topics & ChatOps Integrations** — fan-out channel for paging tools (PagerDuty, Slack) triggered by EventBridge rules.
- **CloudWatch Logs Insights** — ad-hoc SQL-like queries over central log groups for incident triage.
- **AWS Security Hub Findings (ASFF)** — normalized findings routed through EventBridge for automated response.
- **GuardDuty Delegated Admin** — auto-enables GuardDuty in new accounts and sends findings to Security Hub.
- **OpenSearch-based Centralized Logging** — optional stack (OpenSearch Service, Logstash, Kibana) for full-text log search and dashboards.

- **Immutable retention**: “Keep API logs for seven years” → use an **organization trail** writing to a **Log Archive bucket** with Object Lock and KMS encryption.
- **Near-real-time alerting**: “On-call must be paged within 60 s of high-severity findings” → create an **EventBridge rule** targeting `SecurityHub Findings – Imported`, filter on `Severity.Label >= HIGH`, then publish to an **SNS topic** integrated with ChatOps.
- **Auditor single pane**: “Auditors need cross-account visibility without console hopping” → point them at **AWS Config Aggregator**, **Security Hub delegated admin**, and **OpenSearch dashboards** reading from **Security Lake**.
- **Wrong-answer traps**: per-account trails only, logs stored in workload accounts, Lambdas merging CSVs, or forgetting to replicate KMS keys to the DR Region.

Q1: Compliance requires seven-year retention of all API activity across 300 accounts. Which construct meets this with the least operational overhead?  
A1: **Create a CloudTrail organization trail that delivers to a versioned, Object-Locked S3 bucket in the Log Archive account.**

Q2: New AWS accounts must automatically have GuardDuty enabled and forward findings to a central dashboard. What two features achieve this?  
A2: **GuardDuty delegated admin** (auto-enable) and **Security Hub organization aggregation.**

Q3: High-severity Security Hub findings should page Slack within one minute. Which AWS service chain implements this?  
A3: **Security Hub → EventBridge org bus rule (severity filter) → SNS topic → Slack/Webhook.**

Q4: Auditors need to query historical CloudTrail logs with SQL-like syntax. Which native tool provides this without moving data?  
A4: **AWS Athena querying logs stored in Amazon Security Lake (or directly in the S3 log bucket).**

Q5: A developer mistakenly creates a per-account trail in a workload account, duplicating logs and cost. How do you prevent this?  
A5: **Apply an SCP that denies `cloudtrail:CreateTrail` outside the Audit account.**

Q6: Restoring encrypted logs in the DR Region fails with `AccessDenied (KMS)`. What prerequisite was missed?  
A6: **Creating a multi-Region replica of the KMS key used to encrypt the central log bucket.**

Q7: Operations wants dashboards showing Config compliance across all Regions. Which feature supplies the data source?  
A7: **AWS Config Aggregator configured in the Audit account.**

Q8: Which Amazon service normalizes security data into the Open Cybersecurity Schema Framework for lake-wide analytics?  
A8: **Amazon Security Lake.**

Q9: An EventBridge rule catches `CreateUser` API calls and sends them to an SNS topic, but messages are missing the user name. How can you enrich the event?  
A9: **Use EventBridge input transformation to map `$.detail.requestParameters.userName` into the SNS message body.**

Q10: What is the default minimum polling interval for CloudTrail delivery to CloudWatch Logs for near-real-time monitoring?  
A10: **About 5 minutes (configurable 1–5 minutes when using CloudTrail → CloudWatch Logs integration).**

### 3. Multi-account governance model

Governance at scale means **automating guardrails**—preventive, detective, and proactive—so every new account, Region, or workload inherits the same controls **without manual rework**. AWS now layers **Control Tower**, **SCPs**, **tag policies with wildcard support**, and 200 + new **AWS Config rules** to close gaps once filled by custom Lambda auditors. The exam checks whether you can choose the right mechanism (OU-level SCP vs. detective guardrail) and understand the difference between _blocking_ and _report-only_ controls.

- **AWS Control Tower preventive & detective guardrails** — managed **controls** that you enable per-OU; preventive blocks non-compliant actions, detective monitors and reports.
- **Service Control Policies (SCPs)** — Org-level “maximum permission” boundaries; override any allow in child accounts.
- **Tag Policies (2025 wildcard support)** — new `ALL_SUPPORTED` wildcard lets one rule cover every resource type in a service.
- **AWS Config rules library (April 2025 +223 rules)** — Control Tower now exposes 223 additional managed rules for security, cost, operations.
- **Custom frameworks in AWS Audit Manager** — build or clone bespoke compliance frameworks for industry regs.
- **AWS Budgets & Cost Anomaly Detection (org-level)** — org-wide spend guardrails and anomaly alerts.
- **StackSets-driven mandatory resources** — deploy baseline IAM roles, CW alarms, or guardrail lambdas to every account.
- **Landing Zone Accelerator for sovereignty** — CDK/CloudFormation solution that enforces data-residency & regional controls.
- **Continuous Compliance dashboards** — Control Tower + Security Hub widgets showing control status across OUs.
- **Preventive vs Detective vs Proactive** — preventive stops, detective flags, proactive validates configs before deploy.

- **Region restrictions** → _Preventive_ SCP deny `aws:RequestedRegion` or Control Tower _preventive_ guardrail.
- **Tag compliance** → enable **Tag Policy** with wildcard to all OUs; detective guardrail reports missing tags.
- **Backup mandates** → attach **Config rule set** (223 new rules) via Control Tower, or use org-level AWS Backup policy.
- **Cost guardrails** → org-wide **Budgets** + **Cost Anomaly Detection** alert to Finance SNS.
- **Distractors** → IAM inline policy in one account, per-account CloudFormation auditors, or detective guardrail when requirement says “block”.

Q1: A company must block creation of resources in non-approved Regions across 150 accounts. Which governance control provides the least-effort solution?  
A1: **A preventive SCP attached to a top-level OU specifying a `Deny` on disallowed `aws:RequestedRegion` values.**

Q2: You need every resource in all prod accounts to carry `CostCenter` and `Environment` tags, and you want one policy line to cover all resources. Which 2025 feature enables this?  
A2: \*\*Tag Policies wildcard support using `ALL_SUPPORTED`.

Q3: Security wants to detect public RDS snapshots across the organization without writing code. What’s the fastest option?  
A3: **Enable the new managed AWS Config rule (one of the +223 April 2025 additions) via Control Tower.**

Q4: An auditor requires a control framework aligned to a regional data-sovereignty standard not in AWS’s catalog. Which service lets you create it?  
A4: **AWS Audit Manager custom framework.**

Q5: Developers in a Sandbox OU should experiment freely, but Prod OUs must enforce strict controls. Where do you attach detective guardrails?  
A5: **Attach them to the Prod OU; leave Sandbox OU with only baseline preventive guardrails.**

Q6: After enabling a detective guardrail that flags unencrypted S3 buckets, engineers complain it doesn’t block creation. Why?  
A6: **Detective guardrails only monitor and report; they do not prevent the action.**

Q7: Finance asks for alerts when monthly spend in any account exceeds \$10 K. Which org-wide service meets this?  
A7: **AWS Budgets (organization-level)** with an SNS alert.

Q8: Sovereignty rules require restricting service endpoints to a single Region and logging to regional-only buckets. What AWS solution accelerates this deployment?  
A8: **Landing Zone Accelerator on AWS.**

Q9: Control Tower shows “drift detected” on a preventive guardrail. What likely happened?  
A9: **A user with sufficient privileges disabled the guardrail outside Control Tower; remediation is required.**

Q10: Which IaC approach lets you roll out new detective controls to hundreds of accounts as code?  
A10: **Deploy Control Tower controls with AWS CDK or CloudFormation StackSets.**

## Task 1.5: Determine cost optimization and visibility strategies

### 1. Monitoring cost and usage with AWS tools

FinOps teams need **granular visibility, real-time anomaly alerts, and automated budget enforcement**—all without stitching together spreadsheets. AWS now offers a stack that ranges from **CUR-powered QuickSight dashboards** to **Cost Anomaly Detection alerts** and the new **Cost Optimization Hub** that consolidates savings opportunities across accounts. The exam checks that you match each spending scenario to the **right** tool—and avoid laggy or manual options.

- **AWS Cost Explorer** — interactive UI & API for trend lines, tag/region pivots, and RI/SP utilization.
- **Cost & Usage Reports (CUR)** — hourly (or 1-hour refined) CSV/Parquet files in S3; fuel QuickSight or Athena.
- **AWS Budgets** — threshold-based cost, usage, RI/SP utilization budgets; supports **Budgets Actions** to stop/resize resources.
- **Cost Anomaly Detection** — ML service that monitors spend and triggers **SNS / email alerts** when it spots spikes.
- **Cost Optimization Hub** — single dashboard that aggregates > 15 savings recommendations (rightsizing, Graviton, idle).
- **Cost Intelligence Dashboard** — QuickSight template that layers CUR data for BU / product chargeback.
- **AWS Billing Console & CloudWatch Billing metrics** — high-level totals; useful for automation but up to 24 h latency.
- **Cost Categories** — rule-based groupings (by tag, account, service) that flow into Explorer, Budgets, Anomaly Detection.
- **AWS Billing Conductor** — custom rate & discount modeling for reseller/ISV showback; outputs synthetic CUR.
- **Compute Optimizer cost recommendations** — rightsizing and Graviton migration advice based on utilization.
- **AWS Budgets Actions** — on-threshold automation (stop RDS, detach EBS, scale ASG).
- **SNS / ChatOps alerts** — EventBridge or Budget actions fan-out to Slack / PagerDuty.
- **FinOps dashboards** — QuickSight or OpenSearch visualizations built on CUR / Cost Intelligence data.

| Requirement                                               | Best Tool(s)                              | Why                                                                                          |
| --------------------------------------------------------- | ----------------------------------------- | -------------------------------------------------------------------------------------------- |
| **Near-real-time spike alert (< 60 min)**                 | **Cost Anomaly Detection + SNS**          | ML detection + push alerts, no query needed. :contentReference[oaicite:4]{index=4}           |
| **Monthly spend cap with auto-stop**                      | **AWS Budgets Actions**                   | Triggers `StopRunningInstances` / `SSM` runbook at threshold.                                |
| **Granular chargeback by BU / project**                   | **CUR + Cost Intelligence Dashboard**     | Pre-built QuickSight visuals; deep tag/account pivots. :contentReference[oaicite:5]{index=5} |
| **Identify idle & over-provisioned resources across Org** | **Cost Optimization Hub**                 | Consolidates rightsizing + Graviton recommendations. :contentReference[oaicite:6]{index=6}   |
| **High-level daily spend metric for Lambda**              | **CloudWatch Billing `EstimatedCharges`** | Simple metric, but 3–5 h delay—know the lag pitfall.                                         |

Q1: Finance wants an email when daily spend in any account jumps by 40 % above the 30-day average. Which AWS feature delivers this with the least setup?  
A1: **Cost Anomaly Detection monitor with SNS notification.**

Q2: A workload quickly burns through \$5 000 of test budget. You must _automatically_ stop its non-prod RDS instances when the threshold hits. Which service and feature accomplish this?  
A2: **AWS Budgets with a “Budgets Action” that invokes `rds:StopDBInstance`.**

Q3: The FinOps team needs a dashboard that breaks costs down by custom “BusinessUnit” tag and account, including RI/Savings Plan amortization. What is the fastest way to build this?  
A3: **Load the CUR into the Cost Intelligence Dashboard QuickSight template.**

Q4: Leadership asks, “How much could we save by migrating idle instances to Graviton?” Which 2023 AWS console page answers this in one view?  
A4: **Cost Optimization Hub** (aggregated savings opportunities).

Q5: Engineers create CloudWatch alarms on `EstimatedCharges`, but alerts arrive hours after spikes. What inherent limitation causes this?  
A5: **CloudWatch Billing metrics have up to 24-hour latency; they’re not real-time.**

Q6: To split shared services costs fairly, a reseller must apply custom pricing and discounts per end customer. Which AWS billing feature supports this?  
A6: **AWS Billing Conductor**.

Q7: A manager wants to group all Sandbox accounts plus Dev tags into one reporting bucket without editing every dashboard. Which AWS feature enables the grouping once for all cost tools?  
A7: **Cost Categories**.

Q8: Compute Optimizer recommends downsizing 30 % of t3.large instances. Where can you _quantify_ the dollar impact before acting?  
A8: **Cost Optimization Hub**, which aggregates savings across recommendations.

Q9: Anomaly Detection fails to publish to an encrypted SNS topic. What prerequisite was missed?  
A9: **Grant Cost Anomaly Detection the KMS key permissions required for the topic.**

Q10: Which two files from the CUR are needed to populate the QuickSight Cost Intelligence Dashboard?  
A10: **`/cur/cost-and-usage-data/line_item.csv` (or Parquet) and `resource_tags` mapping files.**

### 2. Tagging strategy to map costs to business units

A well-governed tagging model unlocks **chargeback / showback**, FinOps dashboards, and automated budget controls across hundreds of accounts. The key is to **standardize tag keys**, **enforce them with Tag Policies**, and **activate those keys in Billing** so they flow into CUR, Explorer, and Budgets. New 2025 wildcard support (`"ALL_SUPPORTED"`) lets you apply one Tag Policy line to every resource type in a service, slashing policy size and ops toil.

- **Cost-Allocation Tags** — user-defined or AWS-generated tags that become reporting columns once **activated** in the Billing console or via `UpdateCostAllocationTagsStatus`.
- **Tag Policies (Organizations)** — Org-level JSON rules that enforce allowed tag keys/values; 2025 wildcard `ALL_SUPPORTED` covers all resource types.
- **Resource Groups Tag Editor** — console + CLI to bulk add or fix tags across Regions.
- **Cost Categories** — higher-level buckets (e.g., `BU-Environment-Project`) built on tag rules for Explorer, Budgets, and Anomaly Detection.
- **Chargeback vs. Showback** — chargeback bills BUs; showback just reports.
- **ABAC (Attribute-Based Access Control)** — IAM policies reference `aws:ResourceTag/*` or `aws:PrincipalTag/*`.
- **SCIM tag propagation** — IdP SAML/OIDC attributes flow into IAM Identity Center session tags and can map to cost tags.
- **AWS Budgets by Tag** — per-tag cost thresholds with email/SNS actions.
- **Tag Compliance dashboards** — Control Tower + Explorer reports of non-compliant resources.
- **AWS CLI bulk-tagger** — scripts that call `tag-resources` and `untag-resources` across accounts.
- **AWS Config “required-tags” rule** — managed or custom rule that flags/tag-less resources for remediation.
- **AWS Billing Conductor & CUR** — consume activated tags for detailed BU billing.

| Requirement                                       | Correct AWS Features                                     | Common Distractors                   |
| ------------------------------------------------- | -------------------------------------------------------- | ------------------------------------ |
| **Enforce standard tag keys across 200 accounts** | **Tag Policies** attached to the BU OU (wildcard rule)   | IAM policy conditions in one account |
| **Make tags appear in Cost Explorer & CUR**       | **Activate cost-allocation tags in Billing console/API** | Forgetting the activation step       |
| **Slice spend by BU, Env, Project**               | **Cost Categories** referencing the three tag keys       | Custom spreadsheets                  |
| **Alert when BU exceeds \$10 K**                  | **AWS Budgets filtered by `CostCenter` tag** + SNS       | CloudWatch `EstimatedCharges` (lag)  |
| **Auto-remediate missing tags**                   | **Config rule `required-tags`** + SSM/Lambda remediator  | Manual audits                        |

Q1: Finance must allocate charges to 12 business units across 200 accounts _and_ ensure every resource includes a `CostCenter` tag. Which two AWS features satisfy enforcement and reporting?  
A1: **(1) Tag Policies attached at the Org/OU level to mandate `CostCenter` (2) Activation of the `CostCenter` cost-allocation tag in the Billing console or via API.**

Q2: After you create a new `BusinessUnit` tag and apply it to EC2 instances, it does **not** show up in Cost Explorer. What step did you miss?  
A2: **Activating the `BusinessUnit` tag as a cost-allocation tag in AWS Billing.**

Q3: Governance wants one policy line that enforces tagging on _all_ S3 resource types. Which 2025 Tag Policy feature enables this?  
A3: **The `ALL_SUPPORTED` wildcard in Tag Policies.**

Q4: A BU requests a monthly Slack alert when its tagged resources exceed $50 K. Which AWS service chain provides this with no code?  
A4: **AWS Budgets (filtered by `BusinessUnit` tag) → Budgets alert → SNS → Slack webhook.**

Q5: Ops created an IAM policy to deny `ec2:RunInstances` unless `CostCenter` is tagged, but users can still launch untagged S3 buckets. Why?  
A5: **IAM conditions only cover the specified service; they don’t enforce cross-service tagging. Use Tag Policies + Config rules instead.**

Q6: You need a dashboard showing non-compliant tagging across the Org. Which combination delivers this fastest?  
A6: **AWS Config `required-tags` rule + Explorer Tag Compliance dashboard (or Control Tower console).**

Q7: An IdP sends a `division` attribute via SCIM. How can this help cost attribution?  
A7: **Map the attribute to `aws:PrincipalTag/division`, then require the same `division` value as a resource tag for ABAC and cost allocation.**

Q8: A team bulk-updated tags with the CLI but missed some Regions. What AWS UI helps them find and fix gaps quickly?  
A8: **Resource Groups Tag Editor with multi-Region search and bulk tagging.**

Q9: A reseller must apply custom internal cost centers on behalf of customers without exposing real AWS prices. Which billing feature supports this?  
A9: **AWS Billing Conductor with synthetic CUR output.**

Q10: Which file in the Cost & Usage Report contains tag values after activation?  
A10: **The `resource_tags` Parquet/CSV manifest inside the CUR delivery folder.**

### 3. Purchasing options impact on cost and performance

Choosing the **right purchasing model**—On-Demand, Reserved Instances, Savings Plans, Spot, or Capacity Reservations—can cut compute costs by **70 % or more** without sacrificing performance. The exam forces you to balance **commitment length, flexibility, and interrupt tolerance**: long-lived production × steady usage → Standard RIs or 3-year Compute SP; bursty ML training → Spot or GPU Capacity Blocks; mixed families across accounts → Compute SP plus Mixed-Instance ASGs.

- **On-Demand** — pay-as-you-go, no commitment; highest rate, full flexibility.
- **Standard Reserved Instances (1 yr / 3 yr)** — up to 72 % discount; instance family/Region fixed.
- **Convertible Reserved Instances** — exchange attributes (family, OS, tenancy) during term; ~54 % max discount.
- **Compute / EC2 Instance / SageMaker Savings Plans** — commit $/hr for any Region; Compute SP applies to Fargate + Lambda too.
- **Spot Instances** — spare capacity at up to 90 % off; can be interrupted with 2-min warning.
- **Capacity Reservations & Capacity Blocks** — guarantee inventory; Blocks (e.g., GPU) reserve slices 1–14 days.
- **RI Marketplace** — buy/sell existing RIs to fine-tune coverage.
- **Mixed-Instance Policy (Auto Scaling)** — ASG uses multiple sizes/families to maximize Spot pools and RI/SP coverage.
- **Graviton3 right-sizing** — migrate to Arm for ~40 % price-performance gain.
- **Compute Optimizer purchase recommendations** — ML suggestions for RIs/SPs based on past utilization.
- **Cost Explorer Coverage & Utilization reports** — dashboards showing how much usage is covered by RIs/SPs and their actual utilization.

| Scenario                                                       | Best Purchasing Option                                                        | Rationale                                        |
| -------------------------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------ |
| **Steady 24×7 web tier for 3 years**                           | **3-yr No-Upfront Standard RIs** or **3-yr Compute SP**                       | Highest discount for predictable baseline        |
| **\$10 k/mo commitment across any family/Region**              | **Compute Savings Plan**                                                      | Applies to EC2, Fargate, Lambda; family-agnostic |
| **GPU training jobs that run 6 h nightly**                     | **EC2 Spot Instances** or **12-hour GPU Capacity Block**                      | Short-lived, interrupt-tolerant workload         |
| **Data-processing fleet with seasonal spikes**                 | **Base capacity covered by Convertible RIs**, burst with **Spot + On-Demand** | Flexibility to change instance types             |
| **Regulated app needs capacity guarantee during Black Friday** | **Zonal Capacity Reservation**                                                | Locks inventory while paying On-Demand price     |
| **Unknown growth pattern, want discount but flexibility**      | **1-yr Convertible RI**                                                       | Can exchange as sizing becomes clearer           |

Q1: A finance app runs at 60 % CPU on four m6i.xlarge instances, 24×7 for the next three years. Which purchasing model gives the highest savings with minimal management?  
A1: **3-year Standard Reserved Instances (All Upfront or Partial Upfront).**

Q2: A startup commits to spend \$8 000 per month on any mix of EC2, Fargate, and Lambda. Which AWS offering matches this?  
A2: **Compute Savings Plan** for \$8 000/month.

Q3: Machine-learning engineers need 128 vCPU GPU hosts for 8-hour training jobs, three times a week, and can tolerate restarts. What is the most cost-effective option?  
A3: **EC2 Spot Instances** using a diversified Spot Fleet.

Q4: Operations buys Standard RIs but later migrates from x86 to Graviton3. Which purchasing model would have allowed this swap without penalty?  
A4: **Convertible Reserved Instances** (or Compute Savings Plan).

Q5: A game launch requires guaranteed c7g capacity in a single AZ for 48 hours. Which feature secures this without a long-term commitment?  
A5: **EC2 Capacity Reservation** for the AZ.

Q6: Coverage reports show 50 % of usage is unprotected by RIs/SPs during weekends. Which AWS tool produces this report?  
A6: **Cost Explorer Coverage Report.**

Q7: An Auto Scaling Group spans four instance families and wants to maximize Spot pool availability **and** apply existing RIs. Which ASG setting accomplishes this?  
A7: **Mixed-Instance Policy with weighted capacity and prioritized allocation.**

Q8: FinOps wants an automated recommendation engine for RI vs. Savings Plans. Which service provides this?  
A8: **AWS Compute Optimizer purchase recommendations.**

Q9: A fleet uses Spot Instances but termination rate is high during peak hours, impacting SLAs. What purchasing option should be added to ensure baseline capacity?  
A9: **On-Demand or Convertible RIs for baseline; keep Spot for overflow.**

Q10: After purchasing Convertible RIs you want to change from m6i.large Linux/UNIX to r7g.large. What AWS API or console workflow supports this?  
A10: **“ModifyReservedInstances” (API) or RI exchange in the EC2 console.**
