<div align="center">

<img src="https://img.shields.io/badge/Terraform%20Lab-01-7B42BC?style=for-the-badge&logo=terraform&logoColor=white"/>
<img src="https://img.shields.io/badge/IaC-AWS%20Infrastructure-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/ALB-High%20Availability-0A66C2?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-Complete-28a745?style=for-the-badge"/>

# 🌍 Terraform Lab 01 — AWS ALB Infrastructure as Code

### Zero console clicks. One `terraform apply`. Full HA web infrastructure — VPC, EC2, S3, ALB — provisioned entirely through code.

[Back to Lab Index](../README.md)

</div>

---

## 🎯 Objective

Provision a complete, highly available AWS web infrastructure using **Terraform** — no AWS Console, no manual resource creation, no clicking around.

Everything — networking, compute, storage, security, and load balancing — defined as code, version-controlled, and reproducible in any environment with a single command.

> **Why this matters:** Manual console deployments can't be repeated reliably, can't be reviewed in a PR, and can't be rolled back. IaC solves all three. This lab is the foundation of that shift.

---

## 🏗️ Architecture

```
Internet
    │
    ▼
┌──────────────────────────────────────────────────────┐
│              Custom VPC (Terraform-managed)           │
│                                                       │
│  ┌────────────────────────────────────────────────┐  │
│  │           Internet Gateway                      │  │
│  └────────────────────────────────────────────────┘  │
│                       │                               │
│   ┌───────────────────▼──────────────────────────┐   │
│   │       Application Load Balancer (public)      │   │
│   │       internet-facing · port 80 · HTTP        │   │
│   └──────────────┬──────────────┬────────────────┘   │
│                  │              │                      │
│         ┌────────▼───┐   ┌─────▼──────┐              │
│         │  Subnet 1  │   │  Subnet 2  │  (2 AZs)     │
│         │  AZ-a      │   │  AZ-b      │              │
│         │            │   │            │              │
│         │ ┌────────┐ │   │ ┌────────┐ │              │
│         │ │  EC2-1 │ │   │ │  EC2-2 │ │              │
│         │ │ Apache │ │   │ │ Apache │ │              │
│         │ │ :80    │ │   │ │ :80    │ │              │
│         │ └────────┘ │   │ └────────┘ │              │
│         └────────────┘   └────────────┘              │
│                                                       │
│  ┌─────────────┐  ┌──────────────┐                   │
│  │ S3 Bucket   │  │ Security Grp │                   │
│  │ (Terraform) │  │ :22 :80 in   │                   │
│  └─────────────┘  └──────────────┘                   │
└──────────────────────────────────────────────────────┘
```

---

## 📦 Infrastructure Inventory

Everything below was created by **Terraform** — zero manual steps in the AWS Console:

| Resource | Count | Details |
|----------|:-----:|---------|
| VPC | 1 | Custom CIDR, not default |
| Public Subnets | 2 | One per AZ for HA |
| Internet Gateway | 1 | Attached to VPC |
| Route Table | 1 | `0.0.0.0/0 → IGW` |
| Security Group | 1 | Inbound: 22, 80 / Outbound: all |
| S3 Bucket | 1 | Terraform-provisioned |
| EC2 Instances | 2 | User data bootstrapped |
| Application Load Balancer | 1 | Internet-facing, multi-AZ |
| Target Group | 1 | Health check: `GET /` |
| ALB Listener | 1 | Port 80 → Target Group |

---

## 🔑 Core Concept — The Terraform Workflow

```
Write (.tf files)
      │
      ▼
terraform init      ← downloads AWS provider plugin
      │
      ▼
terraform validate  ← syntax + config check
      │
      ▼
terraform plan      ← shows exactly what will be created/changed/destroyed
      │              (always review this before applying)
      ▼
terraform apply     ← provisions real infrastructure
      │
      ▼
terraform destroy   ← tears everything down cleanly
```

> **The power of `plan`:** Before touching any real infrastructure, Terraform shows you a complete diff — what gets added (`+`), changed (`~`), or destroyed (`-`). In production, this plan output goes into a PR for team review before anyone runs `apply`.

---

## 🚀 Implementation

### Step 1 — Setup Terraform Workstation

Launched a fresh EC2 instance as the Terraform control node and installed tooling:

```bash
# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

# Verify
terraform -version

# Configure AWS credentials
aws configure
# → AWS Access Key ID
# → AWS Secret Access Key
# → Default region: ap-south-1
# → Output format: json
```

> **Add Screenshot:** Terraform version + AWS CLI configured

---

### Step 2 — Provider Configuration

```hcl
# provider.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}
```

```bash
terraform init
```

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
✅ Terraform has been successfully initialized!
```

```bash
terraform validate
# Success! The configuration is valid.
```

---

### Step 3 — Network Infrastructure

```hcl
# vpc.tf

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "terraform-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = { Name = "terraform-igw" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "terraform-rt" }
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = { Name = "terraform-subnet-1" }
}

resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = { Name = "terraform-subnet-2" }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rt.id
}
```

> **Add Screenshot:** VPC + subnets visible in AWS Console after apply

---

### Step 4 — Security Group

```hcl
# sg.tf

resource "aws_security_group" "mysg" {
  name   = "terraform-sg"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "terraform-sg" }
}
```

> **Production note:** `0.0.0.0/0` on port 22 is fine for a lab. In production, SSH access should be scoped to a bastion host CIDR or a VPN range — never open to the internet.

---

### Step 5 — S3 Bucket

```hcl
# s3.tf

resource "aws_s3_bucket" "mybucket" {
  bucket = "terraform-demo-bucket-${random_id.bucket_suffix.hex}"
  tags   = { Name = "terraform-s3", Environment = "lab" }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

> S3 bucket names are globally unique — the `random_id` suffix prevents naming conflicts across deployments.

---

### Step 6 — EC2 Instances with User Data

Each instance bootstraps its own web server on launch — no manual SSH required:

```hcl
# ec2.tf

resource "aws_instance" "webserver1" {
  ami                    = "ami-0f58b397bc5c1f2e8"  # Ubuntu 22.04 ap-south-1
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.sub1.id

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt update -y
    apt install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>Hello from Terraform — Server 1 (AZ-a)</h1>" > /var/www/html/index.html
  EOF
  )

  tags = { Name = "terraform-webserver-1" }
}

resource "aws_instance" "webserver2" {
  ami                    = "ami-0f58b397bc5c1f2e8"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id              = aws_subnet.sub2.id

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt update -y
    apt install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>Hello from Terraform — Server 2 (AZ-b)</h1>" > /var/www/html/index.html
  EOF
  )

  tags = { Name = "terraform-webserver-2" }
}
```

> **Why different content per server?** So you can reload the ALB endpoint and see requests bouncing between `Server 1 (AZ-a)` and `Server 2 (AZ-b)` — proving load balancing is actually working.

> **Add Screenshot:** Both EC2 instances running in console

---

### Step 7 — Application Load Balancer, Target Group & Listener

```hcl
# alb.tf

resource "aws_lb" "myalb" {
  name               = "terraform-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
  tags               = { Name = "terraform-alb" }
}

resource "aws_lb_target_group" "tg" {
  name     = "terraform-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
```

> **Add Screenshot:** Target group showing both instances healthy

---

### Step 8 — Terraform Output

```hcl
# outputs.tf

output "loadbalancerdns" {
  description = "ALB DNS endpoint — paste this in the browser"
  value       = aws_lb.myalb.dns_name
}
```

```bash
terraform apply

# After apply completes:
Outputs:
loadbalancerdns = "terraform-alb-xxxxxxxxxx.ap-south-1.elb.amazonaws.com"
```

Open the DNS in browser → see `Server 1`. Refresh → see `Server 2`. Load balancing confirmed.

> **Add Screenshot:** App serving from ALB — both servers responding

---

## 🗂️ Final File Structure

```
terraform-lab-01/
│
├── provider.tf      ← AWS provider + Terraform version config
├── vpc.tf           ← VPC, subnets, IGW, route tables
├── sg.tf            ← security group rules
├── s3.tf            ← S3 bucket
├── ec2.tf           ← two EC2 instances with user data
├── alb.tf           ← ALB, target group, listener, attachments
└── outputs.tf       ← ALB DNS output
```

> Splitting resources into separate `.tf` files by concern (not one giant `main.tf`) is the standard Terraform project structure — easier to navigate, review, and maintain.

---

## 📚 Key Learnings

**Terraform fundamentals:**
- `init` downloads providers, `validate` checks syntax, `plan` previews changes, `apply` executes — never skip `plan` in real environments
- Terraform tracks state in `terraform.tfstate` — this file is the source of truth about what's deployed. In production, store it in S3 with DynamoDB locking, never locally
- Resources reference each other via `resource_type.name.attribute` (e.g. `aws_vpc.myvpc.id`) — Terraform builds a dependency graph and provisions in the right order automatically

**IaC vs console:**

| | AWS Console | Terraform |
|-|-------------|-----------|
| Repeatable | ❌ Manual steps | ✅ Same result every time |
| Version-controlled | ❌ | ✅ Git history of every change |
| Reviewable | ❌ | ✅ PRs, `plan` output as diff |
| Rollback | ❌ Manual reversal | ✅ `terraform destroy` or revert commit |
| Multi-environment | ❌ Tedious | ✅ Workspaces / variable files |

**ALB + Target Group design:**
- The ALB forwards traffic to a **Target Group**, not directly to instances — this abstraction lets you swap instances behind the TG without changing the ALB config
- Health checks run on a schedule — `unhealthy_threshold: 2` means two consecutive failures before an instance is pulled from rotation
- Two subnets in two AZs is the minimum for ALB creation — it's a hard requirement, not optional

**User data:**
- Runs once at first boot as root — perfect for bootstrapping web servers, installing agents, configuring the instance
- `base64encode()` in Terraform is required — EC2 expects user data in base64 format

---

## ✅ Lab Completion Checklist

| Objective | Status |
|-----------|--------|
| Terraform + AWS CLI installed and configured | ✅ |
| AWS provider configured with version pinning | ✅ |
| `terraform init` → provider plugins downloaded | ✅ |
| `terraform validate` → configuration valid | ✅ |
| VPC, 2 subnets, IGW, route table provisioned via Terraform | ✅ |
| Security group created (ports 22, 80) | ✅ |
| S3 bucket provisioned | ✅ |
| 2 EC2 instances launched with user data bootstrapping Apache | ✅ |
| ALB created across both AZs | ✅ |
| Target group created with health checks — both instances healthy | ✅ |
| ALB listener configured on port 80 | ✅ |
| ALB DNS output configured in `outputs.tf` | ✅ |
| App accessible via ALB — load balancing between both servers confirmed | ✅ |

---

<div align="center">

[Back to Lab Index](../README.md)

*You didn't build infrastructure. You wrote the recipe. Terraform cooked it.*

</div>
