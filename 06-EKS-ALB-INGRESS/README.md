<div align="center">

<img src="https://img.shields.io/badge/K8s%20Lab-01-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white"/>
<img src="https://img.shields.io/badge/Amazon%20EKS-Cluster-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/ALB%20Ingress-Controller-0A66C2?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-Complete-28a745?style=for-the-badge"/>

# ☸️ K8s Lab 01 — Amazon EKS with ALB Ingress Controller

### Provision an EKS cluster. Deploy an app. Wire Kubernetes Ingress to AWS ALB automatically. The full production K8s-on-AWS stack.

[Back to Lab Index](../README.md)

</div>

---

## 🎯 Objective

Deploy a Kubernetes application on Amazon EKS and expose it to the internet using the **AWS Load Balancer Controller** — the production pattern for routing external traffic into a Kubernetes cluster on AWS.

The core challenge: Kubernetes and AWS don't natively speak to each other. Bridging them requires OIDC federation, IAM service accounts, Helm, and the LBC controller — all wired together in the right order. This lab does exactly that.

---

## 🏗️ Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────┐
│         AWS Application Load Balancer            │
│         (auto-provisioned by LBC controller)     │
└─────────────────────┬───────────────────────────┘
                      │
                      │ routes to
                      ▼
┌─────────────────────────────────────────────────┐
│              Amazon EKS Cluster                  │
│                                                  │
│  ┌─────────────────────────────────────────┐    │
│  │         Kubernetes Ingress               │    │
│  │  (watched by AWS Load Balancer Controller│    │
│  └──────────────────┬──────────────────────┘    │
│                     │                            │
│                     ▼                            │
│  ┌──────────────────────────────────────────┐   │
│  │          Kubernetes Service               │   │
│  └───────────┬──────────────────────────────┘   │
│              │ selects pods                      │
│    ┌─────────┴─────────┐                        │
│    ▼                   ▼                         │
│  [Pod: 2048]     [Pod: 2048]                     │
│                                                  │
│  Node: t3.medium    Node: t3.medium              │
└─────────────────────────────────────────────────┘
         ▲
         │ IAM OIDC Federation
         │ (K8s ServiceAccount ↔ IAM Role)
    AWS IAM
```

---

## ⚙️ Cluster Configuration

| Setting | Value |
|---------|-------|
| Cluster Name | `my-fargate-cluster` |
| Region | `ap-south-1` |
| Node Count | 2 |
| Node Type | `t3.medium` |
| Provisioning Tool | `eksctl` |
| Provisioning Time | ~15 minutes |

---

## 🔑 Core Concept — Why IAM OIDC?

This is the most important thing to understand in this lab before touching any commands.

```
The problem:
  Kubernetes pods need to call AWS APIs (e.g. "create an ALB")
  But AWS has no idea who a Kubernetes ServiceAccount is
  IAM only trusts IAM users, IAM roles, and AWS services

The solution: IAM OIDC Provider
  EKS exposes an OIDC endpoint for the cluster
  AWS IAM is told to trust that endpoint
  A Kubernetes ServiceAccount is annotated with an IAM Role ARN
  When the pod calls AWS, it gets temporary IAM credentials via the role
  AWS sees a legitimate IAM role → allows the call

Flow:
  Pod → K8s ServiceAccount → OIDC token → IAM Role → AWS API ✅
```

Without OIDC, the LBC controller pod has no AWS permissions and cannot create the ALB — this is why this step can't be skipped.

---

## 🚀 Implementation

### Step 1 — Install Prerequisites on EC2

All tooling installed on an EC2 instance used as the management host:

```bash
# AWS CLI — already installed on Amazon Linux / Ubuntu AMIs
aws --version

# kubectl — K8s command line tool
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
kubectl version --short --client

# eksctl — EKS cluster lifecycle management
curl --silent --location \
  "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
  | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# Helm — K8s package manager (used to install LBC controller)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

> **Add Screenshot:** All tools installed and version-verified

---

### Step 2 — Create EKS Cluster

```bash
eksctl create cluster \
  --name my-fargate-cluster \
  --region ap-south-1 \
  --node-type t3.medium \
  --nodes 2
```

This single command provisions:
- EKS control plane
- 2 EC2 worker nodes (t3.medium)
- VPC, subnets, security groups
- IAM roles for nodes
- kubeconfig entry

> Provisioning takes ~15 minutes. eksctl orchestrates CloudFormation stacks under the hood.

> **Add Screenshot:** EKS Cluster created in AWS Console

---

### Step 3 — Configure kubectl

```bash
# Update kubeconfig to point kubectl at the new cluster
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name my-fargate-cluster

# Verify cluster connectivity
kubectl get nodes
```

Expected output:
```
NAME                                          STATUS   ROLES    AGE   VERSION
ip-192-168-x-x.ap-south-1.compute.internal   Ready    <none>   2m    v1.xx.x
ip-192-168-x-x.ap-south-1.compute.internal   Ready    <none>   2m    v1.xx.x
```

> **Add Screenshot:** kubectl connected, nodes in Ready state

---

### Step 4 — Deploy the 2048 Application

Applied the Kubernetes manifests — Deployment, Service, and Ingress in one file:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/examples/2048/2048_full.yaml
```

This creates:

```bash
# Verify all resources created
kubectl get pods -n game-2048
kubectl get svc  -n game-2048
kubectl get ing  -n game-2048
```

At this point the Ingress exists in Kubernetes but **no ALB exists yet** — the controller that creates it hasn't been installed. The address field is empty.

> **Add Screenshot:** Pods running in game-2048 namespace

---

### Step 5 — Configure IAM OIDC Provider

```bash
# Associate OIDC provider with the cluster
eksctl utils associate-iam-oidc-provider \
  --region ap-south-1 \
  --cluster my-fargate-cluster \
  --approve

# Verify OIDC provider was created
aws iam list-open-id-connect-providers
```

This registers the cluster's OIDC endpoint with IAM — enabling Kubernetes ServiceAccounts to assume IAM roles.

---

### Step 6 — Install AWS Load Balancer Controller

The LBC controller watches for Ingress resources and provisions real AWS ALBs automatically.

**6a — Download and apply the IAM policy:**

```bash
curl -o iam_policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json
```

**6b — Create IAM Service Account:**

```bash
eksctl create iamserviceaccount \
  --cluster my-fargate-cluster \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve
```

This creates a K8s ServiceAccount annotated with the IAM Role ARN — the OIDC bridge.

**6c — Install via Helm:**

```bash
# Add the EKS Helm repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install the controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-fargate-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

**6d — Verify controller is running:**

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```

```
NAME                           READY   UP-TO-DATE   AVAILABLE
aws-load-balancer-controller   2/2     2            2          ✅
```

> **Add Screenshot:** LBC controller pods in 2/2 Running state

---

### Step 7 — Ingress → ALB Provisioning

Once the controller was running, it detected the existing Ingress resource and automatically provisioned an ALB:

```bash
# Watch the Ingress — address field populates when ALB is ready
kubectl get ingress -n game-2048 --watch
```

```
NAME           CLASS   HOSTS   ADDRESS                                              PORTS
ingress-2048   alb     *       k8s-game2048-xxx.ap-south-1.elb.amazonaws.com       80
```

The ALB DNS endpoint is now live — opening it in a browser serves the 2048 game directly from pods running inside EKS.

> **Add Screenshot:** 2048 Application running in browser via ALB

---

## 🔗 How the Pieces Connect

```
kubectl apply ingress.yaml
        │
        │  controller watches for Ingress resources
        ▼
AWS Load Balancer Controller (running in kube-system)
        │
        │  calls AWS API: create ALB, target groups, listeners
        │  (uses IAM role via OIDC → K8s ServiceAccount)
        ▼
AWS Application Load Balancer (auto-created)
        │
        │  routes HTTP traffic to NodePort on worker nodes
        ▼
Kubernetes Service → Pod (2048 game)
```

**The key insight:** You never manually created an ALB. You defined desired state in a Kubernetes Ingress manifest — the controller reconciled that into real AWS infrastructure automatically. This is Kubernetes-native infrastructure management.

---

## 📚 Key Learnings

**EKS + IAM integration:**
- OIDC federation is the correct, production-grade way to give pods AWS permissions — not instance profiles, not hardcoded credentials
- IAM Service Accounts are K8s ServiceAccounts annotated with an IAM Role ARN — one annotation bridges the two identity systems
- The OIDC provider must be created before the ServiceAccount — order matters

**AWS Load Balancer Controller:**
- The controller is the bridge between K8s Ingress spec and real AWS ALBs
- It watches the Kubernetes API for Ingress resources and calls AWS APIs to create/update/delete ALBs to match
- Helm is the standard deployment method — `helm install` handles the deployment, RBAC, CRDs in one command

**Kubernetes concepts applied:**
- `Deployment` — defines desired pod count and container spec
- `Service` — stable internal endpoint that selects pods by label
- `Ingress` — defines external routing rules (host/path → service)
- `Namespace` — `game-2048` isolates the app, `kube-system` for cluster infrastructure

**Production considerations:**
- In production, use Fargate profiles or managed node groups instead of self-managed nodes
- Always pin Helm chart versions — `latest` in production is asking for breaking changes
- The LBC controller needs specific subnet tags for ALB creation to work (`kubernetes.io/role/elb: 1`)

---

## ✅ Lab Completion Checklist

| Objective | Status |
|-----------|--------|
| kubectl, eksctl, Helm installed on management host | ✅ |
| EKS cluster provisioned with 2 x t3.medium nodes | ✅ |
| kubectl configured and nodes verified in Ready state | ✅ |
| 2048 app deployed — Deployment, Service, Ingress | ✅ |
| IAM OIDC Provider associated with cluster | ✅ |
| LBC IAM policy created | ✅ |
| IAM Service Account created with OIDC role binding | ✅ |
| AWS Load Balancer Controller installed via Helm (2/2 Running) | ✅ |
| ALB auto-provisioned by controller on Ingress detection | ✅ |
| 2048 app accessible via ALB DNS endpoint | ✅ |

---

<div align="center">

[Back to Lab Index](../README.md)

*You didn't create an ALB. You declared desired state. The controller made it real.*

</div
