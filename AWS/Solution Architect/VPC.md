#### Ingress & Egress (Public/Private)

- **IGW (Internet Gateway):** Public subnet in + out to Internet.
- **NAT Gateway:** Private subnet out to Internet only (no inbound). For HA, deploy one per AZ; cross-AZ routing incurs fees.
- **Egress-only IGW (IPv6):** IPv6 outbound-only.

**Mnemonic:** “Inbound = IGW, outbound = NAT, IPv6 outbound = Egress-only”

#### Accessing AWS Services Privately

- **Gateway Endpoint:** Only for S3 / DynamoDB, adds route table entry, cheap and high throughput.
- **Interface Endpoint (PrivateLink consumer side):** Creates ENI in your VPC, works for most AWS services + third-party/custom services (via NLB). Supports Endpoint Policies.
- **PrivateLink provider side:** Must use NLB (not ALB).

**Mnemonic:** “S3/DDB = Gateway, others = Interface; provider = NLB; fine-grained = Endpoint Policy”
**Trap:** ALB cannot be used as PrivateLink provider.

#### VPC-to-VPC Connectivity

- **VPC Peering:** Point-to-point, no transitive routing, no overlapping CIDR. Cheap, small scale.
- **Transit Gateway (TGW):** Hub-and-spoke, transitive routing, cross-account, large scale.
- **VPC Lattice:** Service-to-service (L7), built-in auth/observability, good for microservices.

**Mnemonic:** “Small scale = Peering, many-to-many = TGW, service-to-service = Lattice”
**Trap:** Peering doesn’t do transitive routing.

#### Hybrid Connectivity (On-prem ↔ AWS)

- **Site-to-Site VPN:** IPsec over Internet, fast setup but less stable.
- **Direct Connect (DX):** Dedicated link, stable/low jitter; pair with VPN backup for HA.
- **Attachment:** To VGW (VPC-level) or TGW (multi-VPC aggregation). Cross-account/multi-VPC often uses DXGW/TGW.

**Mnemonic:** “Quick = VPN, stable = DX, many VPCs = TGW, always add backup”

#### Load Balancer Family

- **ALB:** L7 HTTP/HTTPS, host/path routing, WAF, OIDC auth.
- **NLB:** L4 TCP/UDP/TLS, static IP/EIP, ultra-high throughput, TLS pass-through.
- **GWLB:** Transparent insertion of security appliances (firewall/IDS/IPS), uses GENEVE.

**Mnemonic:** "L7 = ALB, L4 = NLB, security chaining = GWLB"
**Trap:** ALB cannot have EIP; NLB can.

#### Security & DNS

- **Security Group:** Stateful, instance/ENI level, allow rules only.
- **NACL:** Stateless, subnet level, allow + deny, ordered rules.
- **AWS Network Firewall:** Managed firewall, centralized rules.
- **Route 53 Resolver:**
  - Inbound Endpoint: On-prem → VPC queries.
  - Outbound Endpoint + rules: VPC → On-prem forwarding.
  - Troubleshooting trio: Flow Logs, Traffic Mirroring, Reachability Analyzer.

**Mnemonic:** “Instance = SG, subnet = NACL, org-wide = NF”

#### IPv6 Notes

- Typical /64 per subnet.
- Egress-only IGW for outbound-only IPv6 traffic.
- If question says “IPv6 outbound only, block inbound” → choose Egress-only IGW.

#### Cost Pointers

- **NAT GW:** Charged per hour + data; avoid costs by using Gateway Endpoint for S3/DDB.
- **Interface Endpoint/PrivateLink:** Charged per ENI/hour/data; more isolation, more expensive.
- **TGW:** Charged per attachment + data, but cheaper for scale.
- **Cross-AZ/Region traffic = $$** → watch for exam hints about heavy inter-AZ data.

#### 10-Second Decision Tree

- Private AWS service access without Internet? → VPC Endpoint
- S3/DDB → Gateway; others → Interface (+ policy)
- Consume a service in another VPC only? → PrivateLink (NLB provider)
- Large scale, many VPCs, transitive routing? → TGW
- Outbound to Internet? → NAT GW (private subnets), Egress-only IGW (IPv6)
- Fixed inbound public IP? → NLB + EIP (not ALB)
- Hybrid link? → DX + VPN backup, attach via TGW

#### Common Traps

- ALB cannot have EIP; PrivateLink provider must be NLB.
- Gateway Endpoint = only S3 & DynamoDB.
- VPC Peering = no transitive routing.
- NAT GW must be per AZ for HA.
- Endpoint Policies = fine-grained control; SCP ≠ grant permissions.
- Route 53 Resolver: cross VPC/on-prem DNS needs Inbound/Outbound endpoints + rules.
