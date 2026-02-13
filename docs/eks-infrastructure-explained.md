# EKS Infrastructure — Resource-by-Resource Explanation

All 38 AWS resources created by `terraform apply`, explained in detail.

---

## VPC Module (17 resources)

### 1. `aws_vpc.main`
The virtual private cloud itself — your isolated network in AWS. Creates the `10.0.0.0/16` address space (65,536 IPs). `enable_dns_support` and `enable_dns_hostnames` allow resources inside the VPC to resolve DNS names (required for EKS to work).

### 2. `aws_default_security_group.default`
Every VPC comes with a default security group that allows all traffic between members. This resource **takes ownership** of that default SG and strips all rules (empty ingress/egress). This is a security hardening measure — forces you to create explicit SGs per service instead of accidentally using the permissive default.

### 3-4. `aws_subnet.public[0]` and `aws_subnet.public[1]`
Two public subnets, one per AZ:
- `[0]` = `10.0.0.0/24` in first AZ (e.g. `ap-south-1a`)
- `[1]` = `10.0.1.0/24` in second AZ (e.g. `ap-south-1b`)

`map_public_ip_on_launch = true` means any EC2 instance launched here gets a public IP automatically. Tagged with `kubernetes.io/role/elb = 1` so the AWS Load Balancer Controller knows to place **internet-facing ALBs** here.

### 5-6. `aws_subnet.private[0]` and `aws_subnet.private[1]`
Two private subnets, one per AZ:
- `[0]` = `10.0.100.0/24` in first AZ
- `[1]` = `10.0.101.0/24` in second AZ

No public IPs. Tagged with `kubernetes.io/role/internal-elb = 1` for **internal load balancers**. Your EKS nodes, RDS, and other backend services live here.

### 7. `aws_internet_gateway.main`
Attaches to the VPC and provides a bidirectional gateway between the VPC and the public internet. Without this, nothing in the VPC can reach (or be reached from) the internet.

### 8. `aws_eip.nat`
An Elastic IP (static public IP address) allocated for the NAT gateway. This gives the NAT gateway a fixed outbound IP — useful if you ever need to whitelist your outbound traffic with external services.

### 9. `aws_nat_gateway.main`
Placed in `public[0]` subnet. Allows resources in **private** subnets to make outbound internet requests (e.g., pulling Docker images, calling external APIs) without being directly reachable from the internet. Traffic flow: private instance -> NAT GW -> IGW -> internet.

### 10. `aws_route_table.public`
A route table is a set of routing rules. This one is for public subnets. The table itself is just a container — the actual rules are added separately.

### 11. `aws_route.public_internet`
The rule added to the public route table: `0.0.0.0/0 -> IGW`. Means "any traffic not destined for the VPC (`10.0.0.0/16`, handled by implicit local route) goes directly to the Internet Gateway."

### 12. `aws_route_table.private`
Route table container for private subnets.

### 13. `aws_route.private_nat`
Rule for private route table: `0.0.0.0/0 -> NAT Gateway`. Means "outbound internet traffic from private subnets goes through the NAT gateway" (not directly to IGW).

### 14-15. `aws_route_table_association.public[0]` and `[1]`
Links each public subnet to the public route table. Without this association, subnets use the VPC's main route table (which only has the `local` route — no internet access).

### 16-17. `aws_route_table_association.private[0]` and `[1]`
Links each private subnet to the private route table.

---

## EKS Module (21 resources)

### IAM — Cluster (2 resources)

### 18. `aws_iam_role.cluster`
The IAM role that the **EKS control plane** assumes. The trust policy says: "only the `eks.amazonaws.com` service can assume this role." The control plane uses this role to manage AWS resources on your behalf (creating ENIs in your subnets, managing the cluster security group, writing logs to CloudWatch).

### 19. `aws_iam_role_policy_attachment.cluster_policy`
Attaches `AmazonEKSClusterPolicy` to the cluster role. This is an AWS-managed policy that grants permissions the EKS control plane needs: managing EC2 network interfaces, security groups, describing subnets, writing CloudWatch logs, etc. Without this, the cluster creation would fail with `AccessDenied`.

### IAM — Node Group (5 resources)

### 20. `aws_iam_role.node_group`
The IAM role that **EC2 worker nodes** assume. Trust policy allows `ec2.amazonaws.com` to assume it. Every EC2 instance in the node group uses this role to authenticate with AWS services.

### 21. `aws_iam_role_policy_attachment.node_worker_policy`
Attaches `AmazonEKSWorkerNodePolicy`. Grants nodes permission to: call `eks:DescribeCluster` (to discover the cluster endpoint and CA), connect to the EKS API server, and register themselves as Kubernetes nodes. Without this, nodes can't join the cluster.

### 22. `aws_iam_role_policy_attachment.node_ecr_policy`
Attaches `AmazonEC2ContainerRegistryReadOnly`. Grants nodes permission to pull Docker images from any ECR repository in the account. When your pods specify an ECR image URI, the kubelet on the node uses these credentials to pull the image.

### 23. `aws_iam_role_policy_attachment.node_cni_policy`
Attaches `AmazonEKS_CNI_Policy`. Grants permissions for the **VPC CNI plugin** running on each node. The CNI plugin allocates/deallocates ENIs and secondary IP addresses from the VPC subnet to assign to pods. Without this, pods can't get IP addresses and networking fails.

### 24. `aws_iam_role_policy_attachment.node_ssm_policy`
Attaches `AmazonSSMManagedInstanceCore`. Allows you to access nodes via **SSM Session Manager** (a secure shell without opening SSH ports or managing key pairs). This is the modern alternative to SSH — you can debug node issues by running `aws ssm start-session --target <instance-id>` without any security group changes.

### IAM — EBS CSI IRSA (2 resources)

### 25. `aws_iam_role.ebs_csi_driver`
An IRSA (IAM Roles for Service Accounts) role specifically for the EBS CSI driver. The trust policy is more restrictive: only the **specific Kubernetes service account** `kube-system:ebs-csi-controller-sa` can assume this role, verified via the OIDC provider. This follows the principle of least privilege — only the EBS CSI pods get EBS permissions, not every pod on the cluster.

The `Condition` block with `StringEquals` checks two claims from the OIDC token:
- `:aud = sts.amazonaws.com` — audience must be STS
- `:sub = system:serviceaccount:kube-system:ebs-csi-controller-sa` — only this specific service account

### 26. `aws_iam_role_policy_attachment.ebs_csi_driver_policy`
Attaches `AmazonEBSCSIDriverPolicy`. Grants permissions to create, attach, detach, delete, and snapshot EBS volumes. The EBS CSI driver uses these when a pod requests a `PersistentVolumeClaim` — it creates an actual EBS volume in AWS and attaches it to the node running the pod.

### KMS (2 resources)

### 27. `aws_kms_key.eks`
A customer-managed KMS (Key Management Service) encryption key. Used for **envelope encryption** of Kubernetes secrets stored in etcd. When you create a K8s Secret (e.g., database password), the API server:
1. Generates a DEK (Data Encryption Key)
2. Encrypts the secret with the DEK
3. Calls KMS to encrypt the DEK itself with this master key
4. Stores both the encrypted secret and encrypted DEK in etcd

`enable_key_rotation = true` means AWS automatically rotates the key material every year. `deletion_window_in_days = 7` is a safety net — if you accidentally delete the key, you have 7 days to recover it before all encrypted secrets become unreadable.

### 28. `aws_kms_alias.eks`
A human-readable name (`alias/vibevault-dev-eks`) pointing to the KMS key. Instead of referencing the key by its UUID (`mrk-abc123...`), you can use the alias in AWS console and CLI. Purely a convenience — no functional impact.

### Security Group (2 resources)

### 29. `aws_security_group.cluster_additional`
An **additional** security group attached to the EKS cluster. EKS auto-creates its own "cluster security group" that handles control-plane-to-node communication. This additional SG is a hook for you to add custom rules later, for example:
- Allow a bastion host to reach the API server
- Allow specific CIDR ranges
- Restrict inter-service traffic

### 30. `aws_vpc_security_group_egress_rule.cluster_all_egress`
A single rule on the additional SG: allow **all outbound** traffic (`ip_protocol = -1` means all protocols, `0.0.0.0/0` means any destination). This is a standard baseline — the control plane needs to reach nodes, AWS APIs, and the internet for various operations.

### EKS Core (4 resources)

### 31. `aws_cloudwatch_log_group.eks`
Pre-creates the CloudWatch log group at `/aws/eks/vibevault-dev/cluster` with **7-day retention**. If you let EKS auto-create it, retention defaults to "Never expire" and logs accumulate forever (costing money). By creating it first with the exact name EKS expects, EKS writes to your managed log group. This receives all 5 log types: API server, audit, authenticator, controller manager, and scheduler logs.

### 32. `aws_eks_cluster.main`
**The EKS cluster itself** — the most important resource. This provisions the Kubernetes control plane (API server, etcd, controllers, scheduler) as a managed AWS service. Key configuration:
- `vpc_config.subnet_ids` = private subnets (control plane ENIs are placed here)
- `endpoint_private_access = true` — nodes and pods within the VPC reach the API server via private DNS
- `endpoint_public_access = true` — you can run `kubectl` from your laptop
- `encryption_config` — Kubernetes secrets are encrypted at rest with your KMS key
- `enabled_cluster_log_types` — all 5 control plane log types sent to CloudWatch

This resource takes **~10-15 minutes** to create because AWS is provisioning a highly-available control plane across multiple AZs behind the scenes.

### 33. `aws_eks_node_group.main`
A **managed node group** — AWS handles provisioning EC2 instances, joining them to the cluster, and rolling updates. Key configuration:
- `instance_types = ["t3.medium"]` — 2 vCPU, 4GB RAM per node
- `scaling_config` — min 2, desired 3, max 5 nodes
- `subnet_ids` = private subnets (nodes have no public IPs, outbound via NAT)
- `disk_size = 20` GB EBS root volume per node
- `max_unavailable = 1` — during rolling updates (e.g., AMI upgrade), only 1 node is drained at a time, keeping 2+ always available

Under the hood, this creates an Auto Scaling Group, a Launch Template, and registers the instances with the EKS cluster.

### 34. `aws_iam_openid_connect_provider.eks`
The **OIDC identity provider** that enables IRSA (IAM Roles for Service Accounts). This establishes a trust relationship between your AWS account and the EKS cluster's built-in OIDC issuer.

How it works: When a pod needs AWS permissions, Kubernetes injects an OIDC token into the pod. The pod presents this token to AWS STS via `AssumeRoleWithWebIdentity`. STS validates the token against this OIDC provider, checks the conditions (audience + subject), and returns temporary AWS credentials.

`thumbprint_list` contains the SHA-1 fingerprint of the OIDC issuer's TLS certificate root CA, which STS uses to verify the token wasn't tampered with.

### Addons (4 resources)

### 35. `aws_eks_addon.vpc_cni`
The **Amazon VPC CNI plugin**. Runs as a DaemonSet on every node. Responsible for:
- Allocating ENIs (Elastic Network Interfaces) on each node
- Assigning secondary IP addresses from the VPC subnet to each pod
- This is why pods in EKS get **real VPC IP addresses** (not overlay network IPs) — they're routable within the VPC just like EC2 instances

This is what makes it possible for your pods to directly communicate with RDS, OpenSearch, etc. without any network translation.

### 36. `aws_eks_addon.coredns`
**CoreDNS** — the cluster DNS server. Runs as a Deployment (typically 2 replicas) on worker nodes. When a pod does `curl http://productservice.default.svc.cluster.local`, CoreDNS resolves that to the ClusterIP of the productservice Service. Without CoreDNS, service discovery inside Kubernetes doesn't work. `depends_on = [aws_eks_node_group.main]` because CoreDNS pods need nodes to schedule on.

### 37. `aws_eks_addon.kube_proxy`
**kube-proxy** — runs as a DaemonSet on every node. Maintains network rules (iptables/IPVS) that enable Kubernetes Services. When traffic hits a Service's ClusterIP, kube-proxy routes it to one of the backing pods. It's the layer that makes `ClusterIP`, `NodePort`, and `LoadBalancer` service types work.

### 38. `aws_eks_addon.ebs_csi_driver`
The **AWS EBS CSI (Container Storage Interface) driver**. Enables Kubernetes `PersistentVolumeClaim` to dynamically provision EBS volumes. When a pod requests persistent storage (e.g., for Prometheus metrics, Kafka data), the CSI driver:
1. Creates an EBS volume in AWS via the API (using IRSA role #25)
2. Attaches it to the node running the pod
3. Mounts it into the pod's container

`service_account_role_arn` wires up the IRSA role so the CSI controller pods get AWS permissions without node-level credentials.

---

## Dependency Order (how Terraform creates them)

```
Phase 1 (parallel):  IAM roles, KMS key, log group, SG, VPC resources
Phase 2:             Policy attachments, KMS alias, SG rules, routes
Phase 3:             EKS cluster (~15 min)
Phase 4:             TLS cert fetch, node group (~5 min)
Phase 5:             OIDC provider
Phase 6:             EBS CSI IRSA role
Phase 7:             Addons (coredns + ebs-csi wait for nodes)
```

Terraform parallelizes as much as possible within each phase. The total apply time is dominated by the cluster (~15 min) and node group (~5 min) creation.

---

## EKS Access Management

The cluster uses `CONFIG_MAP` authentication mode by default. This means:

- The IAM identity that runs `terraform apply` (your SSO role) automatically gets `system:masters` access — the highest level of Kubernetes RBAC. No extra configuration needed to run `kubectl` immediately after cluster creation.
- Other IAM users/roles have **no access** by default. To grant access, you edit the `aws-auth` ConfigMap in the `kube-system` namespace.

### Granting access to another IAM role (e.g., Jenkins)

```bash
kubectl edit configmap aws-auth -n kube-system
```

Add a `mapRoles` entry:

```yaml
mapRoles: |
  - rolearn: arn:aws:iam::ACCOUNT_ID:role/jenkins-role
    username: jenkins
    groups:
      - system:masters    # full admin (use a more restrictive group in prod)
```

### Why this matters

When you set up Jenkins CI/CD (Week 6), Jenkins will need to run `kubectl apply` to deploy services to EKS. Jenkins running on EC2 will assume an IAM role — that role must be mapped in `aws-auth` before it can interact with the cluster.

### Alternative: API-based access entries

AWS now supports a newer `API` authentication mode (`access_config` block in `aws_eks_cluster`) that manages access via AWS API calls instead of a ConfigMap. This is more auditable and less error-prone (a bad ConfigMap edit can lock you out). Consider migrating to this for staging/prod environments.

---

## Post-Deployment Verification

After `terraform apply` completes, run these checks to verify the cluster is healthy.

### 1. Configure kubectl

```bash
aws eks update-kubeconfig --name vibevault-dev --region ap-south-1
```

### 2. Verify cluster connectivity and nodes

```bash
# Cluster API server is reachable
kubectl cluster-info

# All 3 nodes are Ready (IPs should be in your private subnets: 10.0.100.x and 10.0.101.x)
kubectl get nodes

# Kubernetes version matches what you set in Terraform
kubectl version
```

### 3. Verify all addons are running

```bash
# Expect: aws-node (3), coredns (2), ebs-csi-controller (2), ebs-csi-node (3), kube-proxy (3)
kubectl get pods -n kube-system

# All pods across all namespaces
kubectl get pods -A
```

### 4. Inspect IRSA in action

```bash
# The ebs-csi-controller-sa has an eks.amazonaws.com/role-arn annotation
# This is the IRSA link between the K8s service account and the IAM role from Terraform
kubectl get serviceaccount ebs-csi-controller-sa -n kube-system -o yaml
```

### 5. Inspect the aws-auth ConfigMap

```bash
# Shows which IAM roles have cluster access
# Your node group role is mapped here automatically by EKS
kubectl get configmap aws-auth -n kube-system -o yaml
```

### 6. Check node capacity and VPC CNI IP allocation

```bash
# Shows allocatable CPU/memory/pods per node
# t3.medium: ~17 pods max (limited by ENI secondary IPs)
kubectl describe node <NODE_NAME> | grep -A5 "Allocatable"

# See how many pods are running vs capacity
kubectl describe node <NODE_NAME> | grep "pods"
```

### 7. Verify storage and CSI drivers

```bash
# Default gp2 StorageClass should exist, plus gp3 from EBS CSI
kubectl get storageclass

# EBS CSI driver is registered
kubectl get csidrivers
```

### Expected healthy state

| Check | Expected |
|---|---|
| Nodes | 3x `Ready`, IPs in `10.0.100.0/24` and `10.0.101.0/24` |
| aws-node (VPC CNI) | 3 pods, `2/2 Running` |
| coredns | 2 pods, `1/1 Running` |
| kube-proxy | 3 pods, `1/1 Running` |
| ebs-csi-controller | 2 pods, `6/6 Running` |
| ebs-csi-node | 3 pods, `3/3 Running` |
| All pods restarts | `0` |
