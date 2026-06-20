<div align="center">

<img src="https://img.shields.io/badge/AWS-Cloud%20Engineering-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/DevOps-Hands--On%20Labs-0A66C2?style=for-the-badge&logo=linux&logoColor=white"/>
<img src="https://img.shields.io/badge/Labs-20%20Projects-28a745?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge"/>

# ☁️ AWS LABS

### Hands-On AWS Cloud Engineering Portfolio

> **20 production-style labs** covering networking, compute, storage, security, serverless, and infrastructure-as-code — each documented with architecture diagrams, implementation steps, real commands, and troubleshooting notes.

</div>

---

## 🎯 Why This Repository Exists

Most cloud certifications test theory. This repository tests **execution**.

Every lab here is built from scratch, manually configured, and documented the way real engineers document their work — with architecture context, the exact CLI commands used, what broke, and how it was fixed. The goal is to build the kind of AWS muscle memory that shows up in production environments.

---

## 📋 Lab Index

| # | Lab | AWS Services | Status |
|:-:|-----|-------------|:------:|
| 01 | **VPC & Network ACLs** | VPC, Subnets, Route Tables, NACLs | ✅ Completed |
| 02 | **ALB-ASG-BASTION** | EC2, SGs, ELB, Key Pairs, AMIs | ✅ Completed |
| 03 | **S3 & IAM Security** | Bucket Policies, Public Access Control, Static Hosting | ✅ Completed |
| 04 | **S3 Static Website Hosting** | S3, Bucket Policies, CloudFront | ⏳ In Progress |
| 05 | **S3 Versioning & Lifecycle** | S3, Lifecycle Rules, Glacier | ⏳ In Progress |
| 06 | **Elastic Load Balancer** | ALB, Target Groups, Health Checks | ⏳ In Progress |
| 07 | **Auto Scaling Groups** | ASG, Launch Templates, Scaling Policies | ⏳ In Progress |
| 08 | **Route 53** | DNS, Routing Policies, Health Checks | ⏳ In Progress |
| 09 | **NAT Gateway** | NAT GW, Elastic IP, Private Subnets | ⏳ In Progress |
| 10 | **Bastion Host** | EC2, SSH Tunneling, Jump Server | ⏳ In Progress |
| 11 | **Elastic Block Store (EBS)** | EBS, Snapshots, Volume Types | ⏳ In Progress |
| 12 | **Elastic File System (EFS)** | EFS, Mount Targets, NFS | ⏳ In Progress |
| 13 | **AWS CLI** | CLI, Profiles, Automation Scripts | ⏳ In Progress |
| 14 | **CloudWatch** | Metrics, Alarms, Log Groups, Dashboards | ⏳ In Progress |
| 15 | **CloudTrail** | Audit Logs, S3 Integration, Event History | ⏳ In Progress |
| 16 | **SNS & SQS** | Topics, Queues, Fan-Out Pattern | ⏳ In Progress |
| 17 | **Lambda Functions** | Serverless, Triggers, IAM Roles | ⏳ In Progress |
| 18 | **API Gateway** | REST API, Lambda Integration, Stages | ⏳ In Progress |
| 19 | **CloudFormation** | IaC, Stacks, Templates, Drift Detection | ⏳ In Progress |
| 20 | **End-to-End AWS Project** | Multi-service Production Architecture | ⏳ In Progress |

---

## 🗂️ Repository Structuree

```
AWS-LABS/
│
├── 01-VPC-NACL/
│   ├── README.md          ← Architecture + implementation notes
│   ├── commands.sh        ← All CLI commands used
│   └── screenshots/       ← Console screenshots
│
├── 02-EC2-SecurityGroups/
├── 03-IAM/
├── 04-S3-Static-Website/
├── 05-S3-Versioning/
├── 06-Load-Balancer/
├── 07-Auto-Scaling/
├── 08-Route53/
├── 09-NAT-Gateway/
├── 10-Bastion-Host/
├── 11-EBS/
├── 12-EFS/
├── 13-AWS-CLI/
├── 14-CloudWatch/
├── 15-CloudTrail/
├── 16-SNS-SQS/
├── 17-Lambda/
├── 18-API-Gateway/
├── 19-CloudFormation/
└── 20-End-to-End-Project/
```

Each lab folder follows the same structure for easy navigation.

---

## 📄 Lab Documentation Standard

Every lab is documented consistently — no half-finished notes:

| Section | What's Included |
|---------|----------------|
| **Objective** | What this lab covers and why it matters |
| **Architecture** | Diagram or description of the setup |
| **Implementation** | Step-by-step configuration walkthrough |
| **Commands** | Every CLI command used, with context |
| **Screenshots** | Console state at key steps |
| **Troubleshooting** | Errors hit and how they were resolved |
| **Key Learnings** | What this lab reinforced or revealed |

---

## 🧰 Tech Stack & Environment

| Category | Details |
|----------|---------|
| ☁️ Cloud Platform | AWS (Free Tier + hands-on accounts) |
| 🐧 Operating System | Ubuntu Linux |
| 🔧 Version Control | Git & GitHub |
| 🐍 Scripting | Python + Bash |
| 📐 IaC | CloudFormation |
| 🎯 Approach | Manual → Automate → Document |

---

## 🏗️ AWS Services Covered

<table>
<tr>
<td valign="top">

**Networking**
- Amazon VPC
- Route 53
- NAT Gateway
- Elastic Load Balancer

</td>
<td valign="top">

**Compute & Storage**
- Amazon EC2
- Amazon S3
- EBS
- EFS

</td>
<td valign="top">

**Security & Identity**
- IAM
- Security Groups
- NACLs
- Bastion Host

</td>
<td valign="top">

**Serverless & Messaging**
- AWS Lambda
- API Gateway
- SNS / SQS
- CloudFormation

</td>
<td valign="top">

**Observability**
- CloudWatch
- CloudTrail
- AWS CLI

</td>
</tr>
</table>

---

## 📈 Learning Objectivess

- [ ] Build strong AWS fundamentals across 6+ service categories
- [ ] Understand cloud networking end-to-end (VPC → DNS → Load Balancing)
- [ ] Apply AWS security best practices (IAM, NACLs, SGs, Bastion)
- [ ] Deploy serverless and event-driven architectures (Lambda, SQS, SNS)
- [ ] Write infrastructure-as-code with CloudFormation
- [ ] Develop real troubleshooting instincts through hands-on failures
- [ ] Build a documented portfolio that demonstrates cloud engineering depth

---

## 🚀 Lab 01 Highlight — VPC & Network ACLs

> The foundation of everything in AWS. Before EC2 can talk to the internet, before load balancers can route traffic, before RDS can accept a connection — networking has to be right.

**What was built:**
- Custom VPC with public and private subnets across 2 AZs
- Internet Gateway attached and route tables configured
- Network ACLs layered on top of Security Groups
- Tested inbound/outbound traffic rules with real EC2 instances

📁 [View Lab 01 →](./01-VPC-NACL/)

---

<div align="center">

**Built to learn. Documented to share. Designed to get hired.**

![AWS](https://img.shields.io/badge/Amazon_AWS-FF9900?style=flat&logo=amazonaws&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat&logo=linux&logoColor=black)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=flat&logo=git&logoColor=white)

*Learn → Build → Break → Fix → Document → Repeat*

</div>
