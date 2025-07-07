# AWS SAP-C02

## Content Domain 1: Design Solutions for Organizational Complexity

### Task 1.2: Prescribe security controls

#### IAM User

- A single AWS identity that represents a human user; can be assigned a username, password, and long-term access keys for console or API calls.
- Best suited for proofs of concept or quick experiments where simplicity outweighs risk.
- Production best practice: replace IAM Users with AWS Identity Center or federated identities (SAML/OIDC) to eliminate long-lived credentials.
- Exam tip: If the question asks how to replace hard-coded keys to meet best practices, answer “Use federated sign-in or AWS Identity Center, then disable or delete the IAM User credentials.”

**Note:** IAM User is the most basic AWS identity mechanism, suitable for testing purposes but not recommended for production due to its reliance on long-term credentials. In production environments, Federated Sign-In should be used, allowing access to AWS through an organization’s existing identity provider without creating separate IAM Users. SAML and OIDC are the two protocol standards that enable Federated Sign-In. AWS Identity Center is a fully managed service provided by AWS that orchestrates the federated authentication process, maps identities to permissions, and issues short-term credentials—effectively serving as a centralized access control platform and temporary credential broker.

#### IAM Role

- An identity with no permanent credentials; principals obtain temporary credentials by calling AssumeRole.
- Typical use cases: EC2 → S3, Lambda → DynamoDB, cross-account administration.
- Key element: a trust policy that declares who may assume the role; maximum session duration is 12 hours (some services default to 1 hour).
- Exam tip: Whenever you see “secure cross-account access,” think IAM Role + trust policy.

**Note:** IAM User represents a permanent identity registered within an AWS account, typically assigned to long-term internal users. In contrast, IAM Role functions as a temporary access identity that can be assumed by trusted entities—either people or systems—without the need for creating new IAM Users. IAM Role offers higher flexibility and security, as it provides short-term credentials and is well-suited for cross-service access, cross-account operations, and temporary authorization scenarios. Common use cases include auditor access, external vendor or contractor integration, federated login from corporate identity providers, and just-in-time administrative elevation.

#### IAM Policy

- A JSON document that states Action, Resource, Effect, and optional Condition.
- Attached to users/roles (identity-based) or to resources such as S3 buckets and Lambda functions (resource-based).
- Evaluation order: default deny → explicit deny → explicit allow.
- Exam tip: Given a conflict (e.g., Allow s3:\* and Deny s3:DeleteObject), deletion is denied because explicit deny wins.

**Note:** An IAM Policy is a JSON document that defines the permissions granted to a specific identity, such as a user or role. It is created and assigned by administrators with appropriate privileges, and can be reviewed or analyzed through the AWS Management Console, AWS CLI, or the IAM Policy Simulator to determine the effective permissions of any identity within the account.

#### Managed vs Inline Policies\*

- Managed Policy: standalone object (AWS-managed or customer-managed) that can be attached to many identities.
- Inline Policy: embedded directly in a single identity and deleted with it.
- Use customer-managed policies for version control and reuse.
- Exam tip: If the question asks how to reduce policy drift and centralize governance, choose Managed Policy over inline.

**Note:** A Managed Policy is a reusable, standalone permission template that can be attached to multiple identities such as users or roles. It is ideal for defining standardized, team-level access and allows centralized control and version management. In contrast, an Inline Policy is directly embedded within a single identity and exists exclusively for that identity—it is automatically deleted when the identity is removed. Inline Policies are suited for one-off, individualized permissions that are not intended to be shared or reused.

#### Policy Evaluation Logic

- Step 1 - explicit deny? ⇒ deny
- Step 2 - explicit allow? ⇒ allow
- Otherwise ⇒ implicit deny
- Applies across Identity Policy, Resource Policy, Session Policy, Permissions Boundary, and SCP.
- Exam tip: When multiple policies overlap, remember explicit deny always wins.

**Note:** Policy evaluation in AWS follows a fixed precedence order: implicit deny → explicit deny → explicit allow. By default, all actions are denied unless explicitly allowed—this is known as implicit deny. If any policy explicitly denies an action (with "Effect": "Deny"), that denial takes absolute precedence and overrides all allow statements. Only when there is no explicit deny and a policy explicitly allows an action (with "Effect": "Allow"), the action is permitted. This evaluation logic applies consistently across all policy types, including identity-based policies, resource-based policies, session policies, permission boundaries, and service control policies (SCPs).

#### Resource-Based Policy

- Attached directly to a resource (S3, SNS, Lambda, etc.) to grant external principals access.
- Eliminates the need to create roles in the other account.
- Exam tip: If an external account must read your S3 bucket, add a Bucket Policy (resource-based) rather than new roles.

**Note:** A resource-based policy is a JSON document attached directly to a resource, such as an S3 bucket, Lambda function, or SNS topic. It defines who can access the resource—typically specifying IAM users, roles, or entire AWS accounts in the Principal field—and what actions they are allowed to perform. Unlike identity-based policies, which state what the identity can do, resource-based policies declare who is allowed to interact with the resource and under what conditions.

#### Session Policy

- A temporary limiting policy passed to AssumeRole; applies only for that session.
- Useful for auditors who need read-only access for two hours, or to shrink DevOps privileges on demand.
- Exam tip: The correct answer to “How do I temporarily narrow a role’s permissions without editing the original policy?” is Session Policy.

**Note:** Session policies act as a dynamic safety mechanism to mitigate the risk of excessive permissions. By allowing temporary restriction of a role’s effective permissions during a session, they help prevent unintended actions—especially in high-privilege contexts—without altering the role’s base policy. This enables secure practices like read-only audits, just-in-time privilege reduction, and constrained automation workflows.

#### Permissions Boundary

- Sets a maximum permission boundary for a user or role; effective permissions are the intersection of the boundary and identity policies.
- Lets developers create roles while preventing them from exceeding corporate limits.
- Exam tip: In CI/CD scenarios where roles are created dynamically but must stay within a ceiling, use Permissions Boundary.

**Note:** Permissions Boundary is typically used by security administrators to define predefined permission ceilings that constrain the maximum access levels assignable to users or roles. These boundaries allow flexibility in creating new roles or adjusting existing ones—especially in dynamic environments such as CI/CD—while ensuring that no identity can exceed the organization's established security limits.

#### Service Control Policy (SCP)

- An organization-level “breaker switch” that restricts AWS accounts or OUs.
- E.g., block `iam:*` or “deleting CloudTrail” across every child account.
- Exam tip: If you must ensure no account can disable CloudTrail, attach an SCP that explicitly denies it.

**Note:** Service Control Policies (SCPs) are account-level permission boundaries enforced by AWS Organizations. Unlike session policies, which restrict only temporary sessions of assumed roles, SCPs apply universally—including to the root user—and define the maximum set of actions that identities within an account can perform. While session policies operate at the session level to temporarily reduce privileges, SCPs act as a persistent, organization-wide control mechanism to enforce security standards, compliance, and governance across accounts.

#### ABAC (Attribute-Based Access Control)

- Grants permissions based on tags/attributes, e.g., `aws:ResourceTag/Project == aws:PrincipalTag/Project`.
- Scales for hundreds of developers managing their own resources without per-user policies.
- Exam tip: For “Each developer can only manage resources they tag,” choose ABAC with tag governance.

**Note:** ABAC (Attribute-Based Access Control) allows access decisions to be made based on user and resource attributes—typically implemented using tags. For example, a policy might permit actions only if `aws:PrincipalTag/Project` matches `aws:ResourceTag/Project`. This model enables scalable permission management for large organizations where hundreds of users need to manage their own resources without individually crafted policies. Unlike RBAC, which assigns permissions based on static roles, ABAC enforces access dynamically based on metadata.

#### IAM Policy Simulator

- Web tool that evaluates whether a given principal can perform a specific action.
- Ideal for debugging complex permission sets or confirming least-privilege adjustments.
- Exam tip: To verify a new policy still follows least privilege, run IAM Policy Simulator.

**Note:** The IAM Policy Simulator is a diagnostic tool that emulates AWS’s permission evaluation engine. It allows administrators to simulate whether a given identity can perform a specific action without executing the action itself. This makes it ideal for debugging access issues, verifying new policies for least-privilege adherence, and auditing complex policy combinations across identity, session, and resource policies.

#### IAM Access Analyzer

- Scans IAM, S3, KMS, and other resources for unintended external exposure and suggests fixes.
- Since 2025 it also recommends removing unused permissions.
- Exam tip: For “How do we detect and remediate accidentally public resources?” enable IAM Access Analyzer.

**Note:** IAM Access Analyzer is a static security analysis tool that scans AWS resources like IAM roles, S3 buckets, and KMS keys to detect unintended external access. It identifies whether any resource-based policies allow access from anonymous users, external accounts, or entities outside your AWS Organization. Since 2025, it also recommends removal of unused permissions, supporting least-privilege enforcement. Unlike the IAM Policy Simulator, which answers “Can this identity perform this action?”, Access Analyzer answers “Can any external entity access this resource unintentionally?”

#### Identity Source

- AWS Identity Center can store users itself or federate to AD, Okta, Azure AD, etc.
- Enterprises typically federate to their existing IdP for unified MFA and password policy.
- Exam tip: If the scenario says “The company already uses Azure AD and wants one-click AWS sign-on,” configure Azure AD as the Identity Source.

**Note:** An Identity Source defines where AWS Identity Center retrieves and validates user identities. While Identity Center can manage users natively, enterprises typically configure an external Identity Provider (IdP) such as Azure AD, Okta, or Active Directory. This enables federation via SAML or OIDC, allowing users to sign into AWS using their existing corporate credentials, including multi-factor authentication. The Identity Center trusts the authentication result and maps it to permissions within AWS. This model supports centralized user management, single sign-on (SSO), and streamlined access control across systems.

#### Permission Set

- A reusable permission template; Identity Center creates an IAM Role with those permissions in each target account.
- Common templates: DeveloperReadOnly, OpsAdmin, etc.
- Exam tip: When asked how to avoid duplicating roles in 50 accounts, answer Permission Set.

**Note:**
Permission Set defines reusable permission templates within AWS Identity Center. When a user federates into AWS via SSO, the system creates a corresponding IAM role in each target account with the attached permissions. It is designed for centralized access provisioning across multiple accounts.

Permissions Boundary, in contrast, is an IAM-level guardrail that limits the maximum effective permissions a user or role can obtain—regardless of what their identity policy grants. It ensures roles created dynamically (e.g., via CI/CD) do not exceed organizational security standards.

#### SCIM Provisioning

- Automatically creates, updates, and removes users and groups via SCIM from an external IdP.
- Ensures immediate revocation when employees leave.
- Exam tip: For guaranteed off-boarding of departed staff, enable SCIM sync.

**Note:** SCIM (System for Cross-domain Identity Management) enables real-time identity synchronization between an external identity provider (IdP) and AWS Identity Center. It ensures that user and group lifecycle events—such as creation, updates, and deletions—are automatically propagated to AWS. This integration bridges the gap between the HR system, corporate directory, and cloud permissions, preventing scenarios where departed employees retain access.

#### Multi-Account Access

- A user logs in once and can switch among roles in multiple accounts; session duration tunable from 15 minutes to 90 days.
- Exam tip: If DevOps engineers need rapid context-switching across accounts, use Identity Center multi-account access.

**Note:** Multi-Account Access enables users to log in once via AWS Identity Center and access multiple AWS accounts by switching roles without re-authenticating. This is commonly used in enterprises that isolate workloads across accounts—for example, separating development, testing, and production environments. DevOps engineers, SREs, and auditors frequently use this capability to perform cross-account tasks such as deployments, log analysis, or compliance checks without the overhead of multiple logins.

#### Session Management API

- Admins can list and instantly terminate any active session—critical for incident response.
- Exam tip: When the question is “Credentials may be compromised; cut off access immediately,” call TerminateSession in Identity Center.

**Note:** Session Management API enables administrators to immediately list and revoke active AWS sessions issued through Identity Center. This is critical during security incidents where credentials may be compromised or a federated user must be instantly deauthorized. Unlike deleting the user at the identity provider level—which may not invalidate an already-issued session—calling TerminateSession ensures immediate access cutoff within AWS.

#### Route Table

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

#### Security Group (SG, Stateful)

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

#### Network ACL (NACL, Stateless)

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

#### Layered VPC Design

One-sentence summary:
A multi-tier network architecture with dedicated DMZ, Application, Database, and Shared Services VPCs, enabling fine-grained east-west control via Transit Gateway or VPC Lattice across accounts and VPCs.

Typical use cases:

Internet ingress through DMZ VPC using ALB + WAF

Application and database layers placed in private VPCs

Centralized logging, AD, CI/CD services hosted in a Shared Services VPC, connected via TGW route domains or Lattice service mesh

Key points:

East-west isolation should use both SG references and subnet route blacklists/whitelists; don’t rely solely on SGs

The database layer must never have direct internet access

The DMZ layer should expose only ports 80/443 and use NACLs to prevent lateral port scans

High-frequency exam topic:
Question: "As an architect, how can you prevent lateral movement from the web layer to the database layer?"
Answer: Implement a layered VPC design with SG references + NACLs for dual-layer isolation. In the database subnet's route table, remove IGW/NAT entries and allow only internal TGW communication.
