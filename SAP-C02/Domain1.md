# Content Domain 1: Design Solutions for Organizational Complexity

## Task 1.1: Architect network connectivity strategies

### AWS Global Infrastructure

A worldwide mesh of Regions (physically isolated groups of data-centres) made up of ≥2 Availability Zones linked by low-latency, high-bandwidth fibre; extended by Local Zones, Wavelength Zones and Outposts for edge or on-prem workloads.

Choose Region vs AZ vs multi-Region for latency, fault-tolerance and compliance; understand data-transfer pricing (in-AZ < cross-AZ < cross-Region) and control-plane independence.

### Building Blocks

- **AZ (Availability Zone):** Physically separate group of data-centres inside a Region; the smallest fault-isolation unit for compute and storage.
- **Local Zones:** Edge data-centres placed inside major metro areas so latency-sensitive parts of a workload run within a few milliseconds of users.
- **Wavelength Zones:** Micro-regions housed in 5 G carrier facilities; push compute to the radio-access edge so mobile AR/VR or connected-car traffic stays below ≈10 ms round-trip.
- **Outposts:** AWS-supplied rack hardware installed in your on-prem data-centre, managed from the parent Region but processing data locally for hybrid or data-sovereignty use-cases.

### Decision dimensions

**Latency:**

- What: keep request/response time low.
- AWS design: pick the closest Region; if sub-10 ms is mandatory use Local Zone, Wavelength, Global Accelerator or an Outpost.
- Example: a multiplayer game back-end runs in us-west-2; real-time physics server is placed in Los Angeles Local Zone to stay <15 ms for West-coast players.

**Fault tolerance inside a Region:**

- What: survive failure of a single data-centre.
- AWS design: deploy across at least two AZs with load balancing and automatic fail-over.
- Example: an ALB in front of EC2 instances spread over 1a and 1c; if 1a fails traffic shifts to 1c with zero manual action.

**Regional disaster:**

- What: recover from loss of an entire Region.
- AWS design: Pilot-Light, Warm-Standby or Active-Active architecture in a second Region; replicate data with S3 CRR, Aurora Global or Route 53 fail-over routing.
- Example: Sydney is primary, Singapore keeps warm standby RDS and minimal EC2; Route 53 health check flips traffic when Sydney goes dark.

**Compliance / data residency:**

- What: keep regulated data in a specific jurisdiction.
- AWS design: choose an in-country Region or Outposts; restrict replication with IAM/SCP and S3 bucket policies.
- Example: Australian health records stored only in ap-southeast-2; analytics jobs run locally on an Outpost in hospital’s data-centre.

**Control Plane**

Manages resource lifecycle (create, modify, delete, monitor) but never carries customer payload data.

**Control-plane actions:**

- aws ec2 run-instances → API allocates capacity and writes to metadata store.
- Editing a VPC route table in the console → configuration is pushed to data-plane routers.

**Not control-plane:**

- HTTPS requests hitting an ALB and reaching your EC2 fleet (data-plane traffic).
- Clients uploading objects directly to S3 (data-plane that bypasses management APIs).

**Exam tip:**

- Q: “I deployed across two subnets in the same AZ—am I highly available?” A: No; high availability requires separate AZs.
- Q: “Local Zone traffic between instances is free like inside a Region?” A: No, Local Zone ↔ Region traffic is charged at inter-AZ rates.

### AWS networking

VPC CIDR blocks, subnets, routing tables, IGW/NAT, PrivateLink & Gateway Endpoints; connectivity via Site-to-Site VPN, AWS Direct Connect (private, public, transit VIFs); Transit Gateway for hub-and-spoke transitive routing; ECS/EKS CNI for container ENI management.

**Networking terms:**

- **VPC:** Your logically-isolated cloud LAN (CIDR-based IP space) where you launch AWS resources; used to mirror an on-prem private network in the cloud.
- **Subnet:** A slice of a VPC, tied to one AZ, that separates workloads (public DMZ, private app, data tier) and lets you apply distinct route tables and security rules.
- **Route Table:** Forwarding map that decides which destination CIDRs go to the Internet Gateway, NAT, TGW, etc.; critical for multi-tier or hybrid designs.
- **Security Group:** Stateful virtual firewall attached to ENIs; controls traffic at instance-level and is the first line for least-privilege network access.
- **Network ACL:** Stateless subnet-level firewall; supplements Security Groups for coarse “deny” rules or auditing egress ports.
- **Internet Gateway (IGW):** Scales horizontally to give a subnet public IPv4/IPv6 reachability; required for inbound HTTPS traffic.
- **NAT Gateway:** Managed NAT device that lets private subnets initiate outbound Internet calls while remaining non-routable from outside.
- **PrivateLink / Interface Endpoint:** Creates an ENI in your subnet so you reach AWS/third-party services over the private backbone instead of public IPs; removes the need for IGW/NAT.
- **Gateway Endpoint:** Free, VPC-level target for S3 or DynamoDB traffic; keeps data inside AWS network and avoids NAT charges.

**Note:**

**1. Standard cloud-network hierarchy (outer → inner → controls)**
A VPC is the outer container that owns an IP space. Inside it, AZ-bound subnets partition that space. Every subnet is linked to a route table that decides where traffic exits—an Internet Gateway for public reachability, a NAT Gateway for egress-only, a Transit Gateway or VPC peering for inter-network paths, or endpoints (Gateway / PrivateLink) for private AWS-backbone access. Security then tightens from coarse to fine: subnet-level network ACLs (stateless) and ENI-level security groups (stateful) enforce least-privilege flow.

**2. Concrete mapping example**
A three-tier web stack runs in VPC 10.0.0.0/16. A public subnet (10.0.1.0/24) with a route 0.0.0.0/0 → IGW hosts an ALB. A private subnet (10.0.2.0/24) sends 0.0.0.0/0 → NAT GW and holds EC2 app servers that accept only ALB traffic (SG rule). A data subnet (10.0.3.0/24) has no Internet route and houses an RDS instance; its SG allows port 3306 only from the app subnet. All instances pull objects from S3 through a Gateway Endpoint, bypassing IGW/NAT entirely.

**3. Plain-language memory hook**
“VPC is the castle, subnets are the floors, route tables are the signposts, IGW/NAT are the gates, endpoints are private corridors, security groups are the room doors, and NACLs are the floor guards.”

**Connection toolbox:**

- **VPC Peering:** One-to-one, non-transitive peering between two VPCs (same or different accounts); simple, low-latency, but does not scale past dozens of VPCs.
- **Transit Gateway (TGW):** Hub-and-spoke router that enables transitive routing and thousands of attachments; ideal for multi-account, multi-Region enterprise topologies.
- **AWS Direct Connect:** Dedicated 1/10/100 Gbps fiber to an AWS Region for predictable latency and lower egress cost; pair with redundant links and VPN fail-over for 99.99 % SLA.
- **Site-to-Site VPN:** IPSec tunnels over the public Internet; quickest way to link on-prem networks to a VPC or TGW, typically used as DX backup or for PoC migrations.
- **Client VPN:** Fully managed OpenVPN endpoint letting remote staff reach VPCs securely without deploying on-prem concentrators.

**Exam tip:**

- Need transitive routing between three VPCs in different accounts; which service? — Transit Gateway. Peering blocks A→B→C forwarding; TGW is built for hub-style routing.
- Private subnet instances must pull OS updates from the Internet without exposing inbound ports; choose the simplest option. — NAT Gateway. Provides outbound-only Internet access while preserving isolation.
- Security team mandates that S3 traffic never traverse the public Internet. Cheapest design? — Gateway Endpoint. Creates private path, zero data processing cost, and no NAT charges.
- On-premises data-centre requires 5 Gbps steady throughput and sub-5 ms jitter into AWS; which connectivity pattern meets SLA? — Two Direct Connect links in separate DX locations plus VPN tunnels for backup. Delivers dedicated bandwidth and high availability.
- Application in us-east-1 needs <10 ms round-trip to mobile devices on a 5 G network; where to deploy compute? — Wavelength Zone tied to the nearest carrier POP; keeps traffic at the radio edge rather than round-tripping to the Region.
- “Can traffic flow A→B→C through a peered VPC?” A: No transitive routing in VPC Peering—use TGW.
- “One VPN tunnel is ‘multi-AZ’ because VGW is HA?” A: False; you need both tunnels up to achieve SLA.

### Hybrid DNS

Route 53 Resolver inbound/outbound endpoints enable bidirectional DNS between on-prem and VPCs; conditional forwarding rules can be shared across accounts with AWS RAM.

Route 53 Resolver inbound and outbound endpoints are pluggable DNS proxies provided by AWS to enable bidirectional DNS resolution between VPCs and on-premises networks.

- **Outbound endpoint:** Allows instances inside a VPC to forward DNS queries to on-premises DNS servers (e.g., resolving .corp.local domains).
- **Inbound endpoint:** Allows on-premises systems to resolve private domain names hosted within a VPC (e.g., \*.aws.internal or Private Hosted Zones).
- **Conditional forwarding rules:** Define which domain names should be forwarded to specific DNS targets. These rules can be shared across AWS accounts using AWS Resource Access Manager (RAM).

**Typical use cases:**

- **VPC to on-prem:** An EC2 instance in a VPC needs to resolve internal corporate domains via on-prem DNS. Solution: create an outbound resolver endpoint and a forwarding rule for .corp.local.
- **On-prem to VPC:** An on-prem application needs to resolve services hosted in the VPC using private hosted zones. Solution: configure an inbound resolver endpoint, update route tables, and allow UDP port 53 in Security Groups.
- **Organization-level DNS sharing:** Use RAM to share forwarding rules across accounts to support centralized DNS resolution.
- **Route 53 routing policies:** Hybrid DNS configurations can still leverage routing policies such as latency-based routing or failover routing to improve performance and availability.

**Exam tip:**

- Q: "After enabling VPN, can on-prem servers automatically resolve private VPC domain names?" A: No. An inbound resolver endpoint must be explicitly configured; otherwise, DNS requests from on-prem cannot reach the VPC.
- Q: "If I configure forwarding rules in one account, will they automatically apply to all accounts in the organization?" A: No. You must explicitly share these rules via AWS RAM; otherwise, they remain local to the originating account.

**Note:**
VPC ↔ (DNS) ↔ On-premises: Requires Resolver Endpoints to establish bidirectional resolution.
Use RAM to share DNS rules across accounts for centralized resolution.

### Network segmentation

Break a VPC’s CIDR block into public, private-app, and private-data subnets to separate exposure, business logic, and data layers.
Isolate workloads further by account and VPC; treat each VPC as a blast-radius boundary.
Apply defense-in-depth: Security Groups (stateful, ENI scope) and Network ACLs (stateless, subnet scope).
Plan unique, non-overlapping CIDRs from the start so future VPC Peering or Transit Gateway attachments are possible.

**Typical use cases:**

- Choosing CIDR sizes that leave head-room for growth and additional AZs.
- Deciding when to enable IPv6 dual stack and how it co-exists with IPv4.
- Designing multi-account landing zones that keep environments separate yet connectable.
- Knowing the behavioral differences between SGs and NACLs for east-west traffic inside a VPC.

**Exam tip:**

- Overlapping CIDR VPCs on one TGW? No—each attachment must advertise a unique prefix.
- Does a NACL automatically allow return traffic like an SG? No—NACL rules are stateless; you must add explicit outbound/return rules.

**Note:**
Network segmentation = CIDR slicing (subnets) + logical isolation (account/VPC) + traffic guard-rails (SG/NACL).
Think of address space, tenancy boundaries, and security controls as three interlocking layers that collectively enforce least-privilege network access.

### Network traffic monitoring

**VPC Flow Logs**

- Purpose: Record 5-minute, L3/L4 metadata for ENI, subnet or whole-VPC traffic; push to CloudWatch Logs, S3 or Firehose.
- Best for: Compliance audit trails, baseline traffic analytics, low-overhead troubleshooting.
- Exam pick-up words: audit, metadata, cost-effective logging, CloudWatch/S3 destination, 5-minute granularity.

**Common traps:**

- Enabling at VPC level does not auto-include future subnets unless you create a VPC-default flow log.
- No packet payload—only metadata.

### Traffic Mirroring (+ Gateway Load Balancer)

- Purpose: Full packet capture from Nitro-based EC2 instances; GWLB scales and centralises delivery to IDS/IPS appliances.
- Best for: Deep packet inspection, regulated forensics, third-party firewall or NDR tooling.
- Exam pick-up words: packet-level, IDS/IPS, deep inspection, pcap, GWLB appliance fleet.

**Common traps:**

- High bandwidth and data-processing cost; mirror filters required to reduce volume.
- Mirroring unavailable on earlier (non-Nitro) instance families.

### Reachability Analyzer

- Purpose: Static path simulation that pinpoints route-table, SG or NACL blockers between two AWS resources.
- Best for: “Why can’t A reach B?” pre-deployment validation, change-control checks.
- Exam pick-up words: simulate path, verify reachability, SG/NACL mis-config, connectivity troubleshooting.

**Common traps:**

- L3 analysis only; no runtime flow or latency data.
- Works inside one VPC, across peering, or via TGW—not across VPN/DX to on-prem.

### Amazon GuardDuty

- Purpose: Managed threat-detection service ingesting Flow Logs, DNS and CloudTrail to raise findings using AWS threat intel.
- Best for: Continuous anomaly detection, crypto-mining alerts, compliance requirements for managed security monitoring.
- Exam pick-up words: detect, threat intelligence, malicious IP, no appliances, managed service.

**Common traps**

- Detects only—does not block. Pair with WAF, Network Firewall, or Lambda automation for enforcement.
- Billed per analysed log volume and number of findings.

### CloudWatch Metrics Insights

- Purpose: SQL-like ad-hoc queries over CloudWatch metrics for near real-time analysis and dashboarding.
- Best for: Rapid slice-and-dice of NAT, ALB, TGW metrics; on-call diagnostics without building Athena tables.
- Exam pick-up words: real-time metrics, SQL query, GROUP BY, ad-hoc analysis, performance hotspot.

**Common traps:**

- Charged per query; queries run on metric data only—no logs or packets.
- Minimum resolution one minute; not sub-second.

## Task 1.2: Prescribe security controls

### IAM User

- A single AWS identity that represents a human user; can be assigned a username, password, and long-term access keys for console or API calls.
- Best suited for proofs of concept or quick experiments where simplicity outweighs risk.
- Production best practice: replace IAM Users with AWS Identity Center or federated identities (SAML/OIDC) to eliminate long-lived credentials.
- Exam tip: If the question asks how to replace hard-coded keys to meet best practices, answer “Use federated sign-in or AWS Identity Center, then disable or delete the IAM User credentials.”

**Note:** IAM User is the most basic AWS identity mechanism, suitable for testing purposes but not recommended for production due to its reliance on long-term credentials. In production environments, Federated Sign-In should be used, allowing access to AWS through an organization’s existing identity provider without creating separate IAM Users. SAML and OIDC are the two protocol standards that enable Federated Sign-In. AWS Identity Center is a fully managed service provided by AWS that orchestrates the federated authentication process, maps identities to permissions, and issues short-term credentials—effectively serving as a centralized access control platform and temporary credential broker.

### IAM Role

- An identity with no permanent credentials; principals obtain temporary credentials by calling AssumeRole.
- Typical use cases: EC2 → S3, Lambda → DynamoDB, cross-account administration.
- Key element: a trust policy that declares who may assume the role; maximum session duration is 12 hours (some services default to 1 hour).
- Exam tip: Whenever you see “secure cross-account access,” think IAM Role + trust policy.

**Note:** IAM User represents a permanent identity registered within an AWS account, typically assigned to long-term internal users. In contrast, IAM Role functions as a temporary access identity that can be assumed by trusted entities—either people or systems—without the need for creating new IAM Users. IAM Role offers higher flexibility and security, as it provides short-term credentials and is well-suited for cross-service access, cross-account operations, and temporary authorization scenarios. Common use cases include auditor access, external vendor or contractor integration, federated login from corporate identity providers, and just-in-time administrative elevation.

### IAM Policy

- A JSON document that states Action, Resource, Effect, and optional Condition.
- Attached to users/roles (identity-based) or to resources such as S3 buckets and Lambda functions (resource-based).
- Evaluation order: default deny → explicit deny → explicit allow.
- Exam tip: Given a conflict (e.g., Allow s3:\* and Deny s3:DeleteObject), deletion is denied because explicit deny wins.

**Note:** An IAM Policy is a JSON document that defines the permissions granted to a specific identity, such as a user or role. It is created and assigned by administrators with appropriate privileges, and can be reviewed or analyzed through the AWS Management Console, AWS CLI, or the IAM Policy Simulator to determine the effective permissions of any identity within the account.

### Managed vs Inline Policies

- Managed Policy: standalone object (AWS-managed or customer-managed) that can be attached to many identities.
- Inline Policy: embedded directly in a single identity and deleted with it.
- Use customer-managed policies for version control and reuse.
- Exam tip: If the question asks how to reduce policy drift and centralize governance, choose Managed Policy over inline.

**Note:** A Managed Policy is a reusable, standalone permission template that can be attached to multiple identities such as users or roles. It is ideal for defining standardized, team-level access and allows centralized control and version management. In contrast, an Inline Policy is directly embedded within a single identity and exists exclusively for that identity—it is automatically deleted when the identity is removed. Inline Policies are suited for one-off, individualized permissions that are not intended to be shared or reused.

### Policy Evaluation Logic

- Step 1 - explicit deny? ⇒ deny
- Step 2 - explicit allow? ⇒ allow
- Otherwise ⇒ implicit deny
- Applies across Identity Policy, Resource Policy, Session Policy, Permissions Boundary, and SCP.
- Exam tip: When multiple policies overlap, remember explicit deny always wins.

**Note:** Policy evaluation in AWS follows a fixed precedence order: implicit deny → explicit deny → explicit allow. By default, all actions are denied unless explicitly allowed—this is known as implicit deny. If any policy explicitly denies an action (with "Effect": "Deny"), that denial takes absolute precedence and overrides all allow statements. Only when there is no explicit deny and a policy explicitly allows an action (with "Effect": "Allow"), the action is permitted. This evaluation logic applies consistently across all policy types, including identity-based policies, resource-based policies, session policies, permission boundaries, and service control policies (SCPs).

### Resource-Based Policy

- Attached directly to a resource (S3, SNS, Lambda, etc.) to grant external principals access.
- Eliminates the need to create roles in the other account.
- Exam tip: If an external account must read your S3 bucket, add a Bucket Policy (resource-based) rather than new roles.

**Note:** A resource-based policy is a JSON document attached directly to a resource, such as an S3 bucket, Lambda function, or SNS topic. It defines who can access the resource—typically specifying IAM users, roles, or entire AWS accounts in the Principal field—and what actions they are allowed to perform. Unlike identity-based policies, which state what the identity can do, resource-based policies declare who is allowed to interact with the resource and under what conditions.

### Session Policy

- A temporary limiting policy passed to AssumeRole; applies only for that session.
- Useful for auditors who need read-only access for two hours, or to shrink DevOps privileges on demand.
- Exam tip: The correct answer to “How do I temporarily narrow a role’s permissions without editing the original policy?” is Session Policy.

**Note:** Session policies act as a dynamic safety mechanism to mitigate the risk of excessive permissions. By allowing temporary restriction of a role’s effective permissions during a session, they help prevent unintended actions—especially in high-privilege contexts—without altering the role’s base policy. This enables secure practices like read-only audits, just-in-time privilege reduction, and constrained automation workflows.

### Permissions Boundary

- Sets a maximum permission boundary for a user or role; effective permissions are the intersection of the boundary and identity policies.
- Lets developers create roles while preventing them from exceeding corporate limits.
- Exam tip: In CI/CD scenarios where roles are created dynamically but must stay within a ceiling, use Permissions Boundary.

**Note:** Permissions Boundary is typically used by security administrators to define predefined permission ceilings that constrain the maximum access levels assignable to users or roles. These boundaries allow flexibility in creating new roles or adjusting existing ones—especially in dynamic environments such as CI/CD—while ensuring that no identity can exceed the organization's established security limits.

### Service Control Policy (SCP)

- An organization-level “breaker switch” that restricts AWS accounts or OUs.
- E.g., block `iam:*` or “deleting CloudTrail” across every child account.
- Exam tip: If you must ensure no account can disable CloudTrail, attach an SCP that explicitly denies it.

**Note:** Service Control Policies (SCPs) are account-level permission boundaries enforced by AWS Organizations. Unlike session policies, which restrict only temporary sessions of assumed roles, SCPs apply universally—including to the root user—and define the maximum set of actions that identities within an account can perform. While session policies operate at the session level to temporarily reduce privileges, SCPs act as a persistent, organization-wide control mechanism to enforce security standards, compliance, and governance across accounts.

### ABAC (Attribute-Based Access Control)

- Grants permissions based on tags/attributes, e.g., `aws:ResourceTag/Project == aws:PrincipalTag/Project`.
- Scales for hundreds of developers managing their own resources without per-user policies.
- Exam tip: For “Each developer can only manage resources they tag,” choose ABAC with tag governance.

**Note:** ABAC (Attribute-Based Access Control) allows access decisions to be made based on user and resource attributes—typically implemented using tags. For example, a policy might permit actions only if `aws:PrincipalTag/Project` matches `aws:ResourceTag/Project`. This model enables scalable permission management for large organizations where hundreds of users need to manage their own resources without individually crafted policies. Unlike RBAC, which assigns permissions based on static roles, ABAC enforces access dynamically based on metadata.

### IAM Policy Simulator

- Web tool that evaluates whether a given principal can perform a specific action.
- Ideal for debugging complex permission sets or confirming least-privilege adjustments.
- Exam tip: To verify a new policy still follows least privilege, run IAM Policy Simulator.

**Note:** The IAM Policy Simulator is a diagnostic tool that emulates AWS’s permission evaluation engine. It allows administrators to simulate whether a given identity can perform a specific action without executing the action itself. This makes it ideal for debugging access issues, verifying new policies for least-privilege adherence, and auditing complex policy combinations across identity, session, and resource policies.

### IAM Access Analyzer

- Scans IAM, S3, KMS, and other resources for unintended external exposure and suggests fixes.
- Since 2025 it also recommends removing unused permissions.
- Exam tip: For “How do we detect and remediate accidentally public resources?” enable IAM Access Analyzer.

**Note:** IAM Access Analyzer is a static security analysis tool that scans AWS resources like IAM roles, S3 buckets, and KMS keys to detect unintended external access. It identifies whether any resource-based policies allow access from anonymous users, external accounts, or entities outside your AWS Organization. Since 2025, it also recommends removal of unused permissions, supporting least-privilege enforcement. Unlike the IAM Policy Simulator, which answers “Can this identity perform this action?”, Access Analyzer answers “Can any external entity access this resource unintentionally?”

### Identity Source

- AWS Identity Center can store users itself or federate to AD, Okta, Azure AD, etc.
- Enterprises typically federate to their existing IdP for unified MFA and password policy.
- Exam tip: If the scenario says “The company already uses Azure AD and wants one-click AWS sign-on,” configure Azure AD as the Identity Source.

**Note:** An Identity Source defines where AWS Identity Center retrieves and validates user identities. While Identity Center can manage users natively, enterprises typically configure an external Identity Provider (IdP) such as Azure AD, Okta, or Active Directory. This enables federation via SAML or OIDC, allowing users to sign into AWS using their existing corporate credentials, including multi-factor authentication. The Identity Center trusts the authentication result and maps it to permissions within AWS. This model supports centralized user management, single sign-on (SSO), and streamlined access control across systems.

### Permission Set

- A reusable permission template; Identity Center creates an IAM Role with those permissions in each target account.
- Common templates: DeveloperReadOnly, OpsAdmin, etc.
- Exam tip: When asked how to avoid duplicating roles in 50 accounts, answer Permission Set.

**Note:**
Permission Set defines reusable permission templates within AWS Identity Center. When a user federates into AWS via SSO, the system creates a corresponding IAM role in each target account with the attached permissions. It is designed for centralized access provisioning across multiple accounts.

Permissions Boundary, in contrast, is an IAM-level guardrail that limits the maximum effective permissions a user or role can obtain—regardless of what their identity policy grants. It ensures roles created dynamically (e.g., via CI/CD) do not exceed organizational security standards.

### SCIM Provisioning

- Automatically creates, updates, and removes users and groups via SCIM from an external IdP.
- Ensures immediate revocation when employees leave.
- Exam tip: For guaranteed off-boarding of departed staff, enable SCIM sync.

**Note:** SCIM (System for Cross-domain Identity Management) enables real-time identity synchronization between an external identity provider (IdP) and AWS Identity Center. It ensures that user and group lifecycle events—such as creation, updates, and deletions—are automatically propagated to AWS. This integration bridges the gap between the HR system, corporate directory, and cloud permissions, preventing scenarios where departed employees retain access.

### Multi-Account Access

- A user logs in once and can switch among roles in multiple accounts; session duration tunable from 15 minutes to 90 days.
- Exam tip: If DevOps engineers need rapid context-switching across accounts, use Identity Center multi-account access.

**Note:** Multi-Account Access enables users to log in once via AWS Identity Center and access multiple AWS accounts by switching roles without re-authenticating. This is commonly used in enterprises that isolate workloads across accounts—for example, separating development, testing, and production environments. DevOps engineers, SREs, and auditors frequently use this capability to perform cross-account tasks such as deployments, log analysis, or compliance checks without the overhead of multiple logins.

### Session Management API

- Admins can list and instantly terminate any active session—critical for incident response.
- Exam tip: When the question is “Credentials may be compromised; cut off access immediately,” call TerminateSession in Identity Center.

**Note:** Session Management API enables administrators to immediately list and revoke active AWS sessions issued through Identity Center. This is critical during security incidents where credentials may be compromised or a federated user must be instantly deauthorized. Unlike deleting the user at the identity provider level—which may not invalidate an already-issued session—calling TerminateSession ensures immediate access cutoff within AWS.

### Route Table

Determines the next hop for each CIDR prefix within a VPC, directing traffic to subnets, gateways, or peering connections along predefined paths.

**Typical use cases:**

- Cross-VPC access via Transit Gateway or VPC Peering
- Routing private subnet traffic to a NAT Gateway
- Enabling cross-region DNS queries using Route 53 Resolver Inbound/Outbound endpoints

**Key points:**

- Follows the “longest prefix match” rule for route resolution
- Works with Transit Gateway route domains for declarative multi-VPC segmentation
- A default route (0.0.0.0/0) pointing to an Internet Gateway allows all non-specific traffic to access the internet

**High-frequency exam topic:**

- Question: "Why can a private subnet still access the internet, even though it shouldn't have direct internet access?"
- Answer: Check if the route table contains 0.0.0.0/0 → igw-xxxx; it should instead point to a NAT Gateway or be removed entirely.

**Note:**

**How Route Tables Work Inside a VPC (Subnet-Level)**

In AWS, route tables are applied at the subnet level and control outbound traffic from resources like EC2. When traffic is sent, AWS uses the subnet’s route table to determine the next hop based on destination CIDR, using longest prefix match.
Each route maps a CIDR block to a target such as local, which enables communication within the same VPC. No route is needed for internal subnet-to-subnet traffic beyond this.
Route tables don’t control permissions—Security Groups and NACLs handle that. But without the correct route, traffic will be dropped regardless of security rules.
This model enables flexible architectures: some subnets route to NAT Gateways for internet access, others remain isolated for database or internal services.

**How Route Tables Enable Communication Outside the VPC**

To send traffic outside the VPC, subnets must define explicit routes to components like:

- Internet Gateway (IGW) for public access
- NAT Gateway for private outbound access
- VPC Peering or Transit Gateway (TGW) for cross-VPC traffic
- Elastic Network Interface (ENI) for Route 53 Resolver endpoints

These external routes must match the destination CIDR block (e.g., another VPC’s range). Without a defined route, AWS drops the packet—even if security groups allow it.
Each route acts like a bridge: IGW sends to internet, NAT proxies private hosts, TGW connects many VPCs, and ENIs help with DNS forwarding. Route tables thus define where packets go, and are essential for hybrid, multi-VPC, or internet-connected designs.

### Security Group (SG, Stateful)

An instance/ENI-level virtual firewall that automatically tracks return traffic, requiring no explicit rules for response flows.

**Typical use cases:**

Inbound/outbound control for EC2, Lambda interfaces, and RDS instances

Service mesh–level east-west isolation using SG references to other SGs

**Key points:**
Outbound is allow all by default; production environments should restrict it explicitly
Works across and within Availability Zones
SG rules can reference other SG IDs instead of static IPs for dynamic dependency management

**High-frequency exam topic:**

- Question: "How can multiple Auto Scaling group instances communicate with each other without exposing public access?"
- Answer: Use mutual SG references between the groups; SGs dynamically update with the instance lifecycle, no fixed IPs needed.

**Note:** A Security Group (SG) is a virtual firewall attached to network interfaces (ENIs) of AWS resources such as EC2, RDS, and Lambda, controlling inbound and outbound traffic at the instance level. By default, SGs deny all inbound traffic and allow all outbound traffic, and they are stateful—meaning return traffic is automatically allowed if the initial request was permitted, with no need to define reverse rules. SG rules are defined by protocol (e.g., TCP), port number (e.g., 80, 443, 22), and source (which can be an IP range or another SG), allowing fine-grained access control across Availability Zones and in dynamic environments like Auto Scaling. In the network path, Security Groups work in conjunction with Route Tables—SGs determine whether traffic is allowed, while Route Tables determine where the traffic should go—together forming the core control plane for communication within and beyond a VPC.

### Network ACL (NACL, Stateless)

Subnet-level traffic filter that explicitly allows or denies traffic; requires both inbound and outbound rules, and does not automatically track return traffic.

**Typical use cases:**

- An extra layer of segmented defense (e.g., DMZ subnets blocking internal 10.0.0.0/8 traffic)
- Blocking specific malicious IPs or CIDR blocks

**Key points:**

- Rule numbers range from 0–32766 and are evaluated in ascending order
- Forgetting to allow ephemeral ports (1024–65535) for return traffic causes broken TCP/UDP sessions

**High-frequency exam topic:**

- Question: "443 port is allowed in the SG, but clients still experience handshake timeouts—why?"
- Answer: Check if the NACL allows outbound 1024–65535 and inbound 443 return traffic; NACLs are stateless and require matching bidirectional rules.

**Note:**
A Network ACL (NACL) in AWS is a subnet-level network access control mechanism. It applies to entire subnets, meaning all resources within the same subnet (such as EC2, RDS, or Lambda functions) are governed by a shared set of NACL rules.

NACLs are stateless, meaning they do not track connection state. For any traffic to be allowed, both inbound and outbound rules must be explicitly defined. Each rule specifies a source or destination IP, protocol, port range, and an action (allow or deny). Rules are evaluated in ascending order by rule number, and evaluation stops at the first match. Therefore, return traffic must be explicitly permitted—e.g., if TCP port 443 is allowed inbound, you must also allow outbound ephemeral ports (1024–65535) for the response; otherwise, the connection will be silently dropped.

In actual traffic flow:

- Inbound traffic: The route table first determines which subnet the traffic should reach. Before entering that subnet, the traffic is checked by the NACL’s inbound rules. If allowed, it proceeds to the target instance, where it is further evaluated by the instance’s Security Group (SG) inbound rules.
- Outbound traffic: When traffic originates from an instance, it is first evaluated by the SG’s outbound rules. If permitted, it then passes through the NACL’s outbound rules, and finally the route table determines the appropriate path to its destination (e.g., IGW, NAT Gateway, or Transit Gateway).

### Layered VPC Design

A multi-tier network architecture with dedicated DMZ, Application, Database, and Shared Services VPCs, enabling fine-grained east-west control via Transit Gateway or VPC Lattice across accounts and VPCs.

**Typical use cases:**

- Internet ingress through DMZ VPC using ALB + WAF
- Application and database layers placed in private VPCs
- Centralized logging, AD, CI/CD services hosted in a Shared Services VPC, connected via TGW route domains or Lattice service mesh

**Key points:**

- East-west isolation should use both SG references and subnet route blacklists/whitelists; don’t rely solely on SGs
- The database layer must never have direct internet access
- The DMZ layer should expose only ports 80/443 and use NACLs to prevent lateral port scans

**Exam tip:** "As an architect, how can you prevent lateral movement from the web layer to the database layer?"— Implement a layered VPC design with SG references + NACLs for dual-layer isolation. In the database subnet's route table, remove IGW/NAT entries and allow only internal TGW communication.

**Note:**

**1. What is Layered VPC Design?**

Layered VPC Design is a network architecture pattern that separates the public-facing (DMZ), application logic (Application), data storage (Database), and shared services (Shared Services) into dedicated VPCs. These VPCs are interconnected through Transit Gateway, VPC Lattice, or PrivateLink to enforce controlled, least-privilege communication across trust boundaries. It’s conceptually similar to software patterns like MVC, MVP, or MVVM—where responsibilities are decoupled between layers. The difference is that here, the separation is applied to network trust zones and operational responsibilities instead of code modules.

**2. How Traffic Flows in a Layered VPC Design?**

Public traffic first hits the ALB + WAF in the DMZ VPC, where TLS termination and web-layer protections occur. The request is then forwarded—via Transit Gateway, VPC Peering, or Lattice—to the Application VPC for processing. If data access is required, the flow continues to the Database VPC, and the response returns along the same controlled path. Every east-west hop is subject to route table path selection, NACL subnet-level filtering, and Security Group instance-level access control. Shared Services VPCs expose centralized capabilities like logging, Active Directory, or CI/CD through TGW route domains, not open access.

**3. Four Key Questions**

- **How many VPCs per business line?** It depends on the trust boundaries. Small projects may use 1–2 VPCs; a typical production environment uses 3–4 (DMZ, App, DB, Shared); regulated enterprises often deploy 4–5 per environment plus shared infrastructure.

- **Do web/mobile/backend share the same VPC?** No. Frontend clients live outside AWS and connect through ALB in the DMZ VPC. Backend services typically share the Application VPC or use separate App VPCs per team or function.

- **How do the layers communicate?** Layers are connected using TGW, Peering, or Lattice. Subnet route tables define the allowed CIDR paths, and SG references + NACL rules enforce fine-grained access control.

- **Is everything fully connected?** Absolutely not. Only explicitly required ports and directions are opened. The DB subnet has no IGW or NAT routes. Flows like DMZ → App are permitted; others are denied by default to enforce least privilege.

### AWS Key Management Service (KMS)

A managed service that creates, stores, rotates, and audits cryptographic keys and exposes encrypt/decrypt APIs.

**Typical use cases:**

- Server-side encryption for S3, EBS, RDS, DynamoDB.
- Envelope encryption in custom applications.
- Multi-Region keys for fast DR replication.
- BYOK / XKS scenarios that keep keys inside customer-controlled HSMs.

**Key points:**

- Key types: customer-managed vs. AWS-managed; symmetric, asymmetric, HMAC.
- Permissions flow: Key Policy ➜ optional Grants for time-boxed access; automatic rotation every 365 days (or custom rotation via Lambda).
- Multi-Region keys share the same key ID but live in independent hardware; replication latency is sub-second.
- External key store (XKS) meets strict sovereignty or financial-sector rules.

**Exam tip:** “Need cross-Region DR and customer-owned keys?” — Use a multi-Region CMK combined with XKS, plus envelope encryption on the client side.

**Note:**
**AWS Key Management Service (KMS)** is a managed “encryption vault” that issues, stores, rotates, and audits cryptographic keys, allowing AWS services to transparently encrypt data-at-rest—such as S3 objects, EBS volumes, RDS snapshots, DynamoDB tables, CloudTrail logs, and Secrets Manager secrets—without developers handling raw keys.

- **AWS-managed key:** auto-created and fully maintained by AWS; ideal for quick-start encryption of S3 buckets or CloudTrail logs.
- **Customer-managed (CMK):** user-created, with custom key policies and rotation; used for production EBS volumes or RDS databases requiring granular access control.
- **Symmetric CMK:** single AES-256 key for encrypt/decrypt APIs; default choice for most at-rest encryption tasks.
- **Asymmetric CMK:** RSA or ECC key pair for digital signatures or envelope-key exchange; e.g., signing software artifacts.
- **HMAC CMK:** secret key for hash-based message authentication; validating webhooks or API payload integrity.
- **Multi-Region CMK:** logically one key, physically replicated per Region; supporting cross-Region S3 replication or Aurora Global Database.
- **Imported/BYOK CMK:** key material supplied from on-prem HSM, AWS only stores it; satisfies bring-your-own-key compliance.
- **External Key (XKS):** key never leaves customer-controlled HSM, KMS merely proxies requests; meets strict data-sovereignty or financial-sector mandates.

### AWS Certificate Manager (ACM)

A fully managed service that issues, deploys, and automatically renews public or private TLS certificates.

**Typical use cases:**

- HTTPS for CloudFront, ALB, NLB, and API Gateway.
- Mutual TLS between microservices or IoT devices via ACM Private CA.

**Key points:**

- Public certificates are free and now default to a 90-day validity (auto-renewed).
- Private certificates come from ACM PCA; ideal for internal services or client auth.
- NLB supports TLS offload with hot certificate replacement; CloudFront offers global TLS hand-shake acceleration.

**Exam tip:** “Need low-latency TLS across Regions for an API Gateway?” — Attach an ACM public cert to CloudFront + edge-optimised API Gateway.

**Note:** AWS Certificate Manager (ACM) is a managed service that handles the issuance, deployment, and automatic renewal of public or private TLS/HTTPS certificates. It integrates seamlessly with services like CloudFront, ALB, NLB, and API Gateway, enabling secure communication without manual certificate operations. While direct configuration of ACM is rarely required, the SAP exam frequently tests the ability to identify its role in architectures—such as using a free ACM public certificate with CloudFront for low-latency HTTPS, enabling mutual TLS with ACM Private CA, or leveraging hot certificate replacement for TLS offloading on Network Load Balancers. ACM is the default solution for scalable, trusted HTTPS integration in AWS.

### End-to-End Encryption Strategy

TLS in transit + KMS (or client-side) encryption at rest, covering every hop from user to storage.

- **Typical use cases:** Finance or healthcare systems that must prove data is encrypted in transit, at rest, and in backup/replica copies.

**Key points:**

- Enforce HTTPS with the aws:SecureTransport condition.
- TLS from client ➜ ALB/NLB ➜ EC2/Lambda; internal calls can use ACM PCA certificates.
- Multi-Region CMKs for replication; cross-account sharing via KMS Grants and resource policies.

**Exam tip:** “Client-side keys (BYOK), cross-Region DR, and mandatory encryption everywhere?” — Store keys in XKS, replicate as multi-Region CMKs, perform client-side envelope encryption, and enable SSE-KMS at the storage layer for layered defence.

**Note:** An end-to-end encryption strategy combines TLS (in transit) and KMS/XKS (at rest) to ensure that data is encrypted throughout its full lifecycle—from user requests to backups—across accounts and Regions, satisfying compliance and zero-trust security models.

### AWS CloudTrail & CloudTrail Lake

CloudTrail records every API call; CloudTrail Lake stores those events in an immutable data lake and lets you run SQL-style queries across Regions and across the entire AWS Organization.

**Typical use cases:** 90-day account-level audit (trails), long-term forensics or cost-efficient analytics up to 10 years (Lake’s flexible-retention option).

**Key points:**

- Organization event-data stores aggregate logs from all member accounts.
- Advanced joins let you correlate multiple data stores in a single query.
- Events can trigger real-time automation through EventBridge.

**Exam tip:** “Need to run cross-account forensic queries without exporting logs?” — Enable CloudTrail Lake with an organization event-data store.

**Note:**
AWS CloudTrail is a service that records all API activity across an AWS account, providing detailed audit logs for governance, compliance, and security analysis. CloudTrail Lake extends this by storing those logs in a queryable data lake with support for SQL-based analytics across Regions and accounts.
Simply put, CloudTrail acts as a real-time recorder of all AWS actions, while CloudTrail Lake serves as the long-term archive and analysis engine for those actions—functionally similar to a `git blame` for AWS, helping trace who did what, when, and from where.

### IAM Access Analyzer

A static-analysis engine that discovers unintended external access and, since 2024, recommends removing unused permissions to right-size policies.

**Typical use cases:** Detect publicly exposed S3 buckets, over-permissive KMS keys, or dormant IAM actions across all accounts.

**Key points:**

- Scans resource-based and identity-based policies; flags principals outside your Org.
- Unused-access report suggests a refined JSON policy you can apply with one click.
- Findings flow directly into Security Hub for aggregation.

**Exam tip:** “How do we identify and automatically tighten unused permissions organisation-wide?” — Run IAM Access Analyzer recommendations.

### AWS Security Hub (with CSPM)

A central console that aggregates security findings, maps them to the AWS Security Finding Format (ASFF), and scores your environment against CIS, PCI-DSS and new CSPM controls.

**Typical use cases:** Single pane of glass for GuardDuty, Macie, Inspector, Access Analyzer, plus enterprise posture dashboards.

**Key points:**

- CSPM integration normalises service-specific checks into ASFF, enabling cross-service correlation.
- Supports custom controls; scores can be pushed to ticketing or SOAR tools via EventBridge.
- Organisations auto-enrol new accounts, ensuring instant coverage.

**Exam tip:** “Need a unified risk score across 50 accounts and multiple AWS security services?” — Enable Security Hub with CSPM in the management account.

**Note:**
Security Hub provides a unified security posture dashboard by aggregating findings across services like GuardDuty and Inspector, converting them into ASFF format, and mapping them against compliance standards such as CIS and PCI-DSS. It supports cross-account, cross-service visibility, automated remediation via EventBridge, and organization-wide onboarding for continuous monitoring.
In the Security Hub ecosystem: all security findings are standardized into ASFF format, then correlated, visualized, and evaluated through CSPM rulesets. Together, they enable centralized, automated, and policy-aware security posture management.

### Amazon Inspector

A continual vulnerability-management service that scans EC2, Lambda, and ECR images with an upgraded engine (Feb 2025) for deeper dependency coverage.

**Typical use cases:** Automatically detect CVEs in container images before deployment; patch EC2 AMIs via SSM Automation.

**Key points:**

- New engine re-evaluates existing images, closing out false positives and surfacing newly discovered CVEs.
- Findings are de-duplicated and forwarded to Security Hub; EventBridge rules can trigger SSM Patch Manager or pipeline block actions.
- No manual rescans required—the enhancement rolls out transparently.

**Exam tip:** “How do we maintain continuous container vulnerability visibility without manual scans?” — Turn on Amazon Inspector for ECR.

**Note:** Amazon Inspector is a fully managed vulnerability management service that continuously scans EC2 instances, Lambda functions, and ECR container images for known CVEs. After a one-time manual activation, it automatically monitors and rescans resources whenever changes are detected—no manual rescans are needed. When a vulnerability is found, Inspector generates standardized findings, forwards them to Security Hub for centralized visibility, and can trigger automated responses via EventBridge, such as patching with SSM Patch Manager or blocking deployments in CI/CD pipelines.

### Security Architecture Lifecycle on AWS

#### 1. Requirements Gathering

Begin by clarifying all external and internal mandates that will drive security controls. Catalog relevant regulations (e-g., ISO 27001, PCI-DSS, APRA CPS 234), document business SLAs, and classify data by sensitivity so that confidentiality, integrity, and availability targets are explicit from day one.

#### 2. Baseline Design

Translate those mandates into a non-negotiable security baseline. Lock down identity (root MFA, SCPs that forbid disabling CloudTrail, unified sign-on with Identity Center), impose network segmentation with VPC tiers plus layered SG/NACL rules, require encryption by default (customer-managed CMKs, bucket keys, database TDE/SSL), and turn on organization-wide monitoring with CloudTrail + Lake, Security Hub, and continuous Inspector scans.

#### 3. Automation and IaC

Encode every baseline control—SG rules, KMS keys, SCPs, logging stacks—into CloudFormation or the AWS CDK, parameterising secrets via Systems Manager where needed. For multi-account estates, bootstrap environments with AWS Control Tower blueprints so that new accounts inherit the baseline automatically.

#### 4. Validation and Continuous Improvement

Close the loop by running IAM Access Analyzer to catch unintended exposure, IAM Policy Simulator for pre-deployment permission tests, and Audit Manager or custom Security Hub controls for ongoing compliance scoring. Feed findings into ticketing or automated remediation so each iteration measurably tightens least-privilege and governance posture.

## Task 1.3: Design reliable and resilient architectures
