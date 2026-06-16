<div align="center">

<img src="https://img.shields.io/badge/Lab-03-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/Amazon%20S3-Storage-569A31?style=for-the-badge&logo=amazons3&logoColor=white"/>
<img src="https://img.shields.io/badge/IAM-Access%20Control-DD344C?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-Complete-28a745?style=for-the-badge"/>

# ☁️ Lab 03 — S3, IAM & Static Website Hosting

### Two S3 use cases in one lab: locking data down with bucket policies, and opening it up just enough to host a public website.

[← Lab 02: VPC & Load Balancer](../02-EC2-SecurityGroups/) | [Back to Lab Index](../README.md) | [Lab 04: S3 Versioning →](../04-S3-Versioning/)

</div>

---

## 🎯 Objective

Understand how S3 access control actually works — not just in theory, but by hitting real access errors and fixing them at the right layer.

This lab covers two distinct scenarios that together reveal a critical AWS concept: **Block Public Access, IAM policies, and Bucket Policies are three separate layers. All three must align for access to work.**

| Demo | Scenario | Goal |
|------|----------|------|
| 01 | Sensitive data bucket | Lock it down — owner access only |
| 02 | Static website hosting | Open it just enough — public read, nothing else |

---

## 🔑 Core Concept — The S3 Access Decision Chain

Before diving in, this is how S3 evaluates every access request:

```
Request Arrives
      │
      ▼
Is Block Public Access ON?  ──► YES ──► DENIED (regardless of policies below)
      │
      NO
      ▼
Is there a Bucket Policy?
      │
      ├──► DENY rule matches? ──► DENIED immediately
      │
      └──► ALLOW rule matches?
                  │
                  ▼
          Does IAM policy allow it? ──► YES ──► ALLOWED
                                    ──► NO  ──► DENIED
```

> S3 is **deny-by-default**. Every layer has to say "yes" for access to go through. This lab makes each layer visible by triggering failures at each one.

---

## 🧰 AWS Services Used

- Amazon S3 (Buckets, Bucket Policies, Static Website Hosting)
- IAM (Users, Policies, Least Privilege)

---

# 🔐 Demo 01 — Securing Sensitive Data

## Scenario

You have an S3 bucket containing sensitive/confidential files. Even though an IAM user has broad S3 permissions in their policy, you want to guarantee that **only the AWS account owner can access this bucket** — no one else, regardless of their IAM permissions.

---

## Step 1 — Create the Bucket & IAM User

Created an S3 bucket and uploaded a test file to simulate sensitive data.

Created an IAM user following the **principle of least privilege** — granted only the S3 permissions needed:

| Permission | Why |
|-----------|-----|
| `s3:ListBucket` | See bucket contents |
| `s3:GetObject` | Download objects |
| `s3:PutObject` | Upload objects |

> **Principle of least privilege:** Grant only what's needed. If a user's job doesn't require deleting objects, don't give them `s3:DeleteObject`. Every unnecessary permission is an attack surface.

---

## Step 2 — Enable Block All Public Access

```
S3 Console → Bucket → Permissions → Block Public Access → Enable All
```

This is the first line of defense. Even if a bucket policy accidentally allows public access, this setting overrides it.

---

## Step 3 — Apply a Deny-All Bucket Policy (Except Owner)

The IAM user has S3 permissions in their IAM policy. Without a bucket policy restriction, they could access this sensitive bucket. The bucket policy below **explicitly overrides that** — even a permissive IAM policy can't bypass an explicit Deny.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAccessExceptOwner",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::sensitive-data-bucket",
        "arn:aws:s3:::sensitive-data-bucket/*"
      ],
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalArn": "arn:aws:iam::<ACCOUNT_ID>:root"
        }
      }
    }
  ]
}
```

**How this works:**
- `Principal: "*"` — applies to everyone
- `Effect: Deny` — explicit deny, highest priority in AWS IAM evaluation
- `Condition: StringNotEquals aws:PrincipalArn` — **except** the root account owner
- Result: IAM user's S3 permissions are irrelevant — the bucket itself refuses them

---

## ✅ Demo 01 Result

| Who Tries to Access | Result | Why |
|--------------------|--------|-----|
| AWS Account Root | ✅ Allowed | Matches the condition exception |
| IAM User (even with S3 permissions) | ❌ Denied | Explicit Deny in bucket policy overrides IAM Allow |
| Anonymous / Public Internet | ❌ Denied | Block Public Access + Explicit Deny |
| Other AWS accounts | ❌ Denied | No cross-account trust configured |

### Key Insight
**Explicit Deny always wins.** In AWS IAM, if there's a Deny anywhere in the evaluation chain, no Allow can override it. This is why bucket policies are powerful — they give the data owner control independent of IAM configurations elsewhere.

---

# 🌐 Demo 02 — Static Website Hosting

## Scenario

Host a simple static HTML page on S3, publicly accessible via a URL — no EC2, no web server, no cost beyond storage.

---

## Step 1 — Create Website Content

Created a basic `index.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <title>AWS S3 Website</title>
</head>
<body>
    <h1>Hello from Amazon S3</h1>
</body>
</html>
```

Uploaded to S3 as `index.html`.

---

## Step 2 — Enable Static Website Hosting

```
S3 Console → Bucket → Properties → Static Website Hosting → Enable
Index Document: index.html
```

AWS generates a website endpoint:
```
http://<bucket-name>.s3-website-<region>.amazonaws.com
```

Opened the URL — got an **Access Denied** error. Expected. This is where the learning starts.

---

## Troubleshooting — Two-Layer Fix

### ❌ Error 1 — Block Public Access was ON

The bucket had Block Public Access enabled from Demo 01. For a public website, this must be disabled.

```
S3 → Permissions → Block Public Access → Disable
```

Tried the URL again — still **Access Denied**. Because disabling Block Public Access doesn't *grant* access. It only *removes the block*. You still need an explicit Allow.

---

### ❌ Error 2 — No Bucket Policy Allowing Public Read

Disabling Block Public Access just removes the guardrail. The bucket still has no policy saying "public users can read files." Added this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadAccess",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-static-website-bucket/*"
    }
  ]
}
```

**Why only `s3:GetObject`?**
- `GetObject` = read files. That's all a website visitor needs.
- No `PutObject`, no `DeleteObject`, no `ListBucket` — anonymous users can fetch content, nothing else.

---

## ✅ Demo 02 Result

Website live and accessible at the S3 endpoint URL. HTML served directly from S3 — no servers involved.

---

## 🔒 Security Design Comparison

| | Sensitive Bucket | Static Website Bucket |
|-|-----------------|----------------------|
| Block Public Access | ✅ Enabled | ❌ Disabled (required) |
| Bucket Policy | Deny all except root | Allow `s3:GetObject` to `*` |
| IAM User Access | Blocked by bucket policy | Not needed |
| Public Internet Access | ❌ Denied | ✅ Read-only allowed |
| Write/Delete by public | ❌ | ❌ |

---

## 📚 Key Learnings

**IAM Policy vs Bucket Policy — when to use which:**

| | IAM Policy | Bucket Policy |
|-|-----------|---------------|
| Attached to | IAM User / Role | S3 Bucket |
| Controls | What the identity can do | Who can access this resource |
| Cross-account access | No | Yes |
| Anonymous / public access | No | Yes |
| Use when | Defining user permissions | Protecting or exposing specific buckets |

> **Real-world pattern:** Use IAM policies to define what your users/services can do across AWS. Use Bucket Policies when you need to lock down a specific bucket regardless of IAM, or when granting cross-account / public access.

**Layered access model:**
- Disabling Block Public Access ≠ public access. It just removes the block.
- An IAM Allow ≠ bucket access if a bucket policy has an explicit Deny.
- Explicit Deny always overrides any Allow — everywhere in AWS IAM.

**S3 Static Website Hosting limitations to know:**
- S3 websites serve over HTTP only (not HTTPS). For HTTPS, put CloudFront in front.
- S3 website URLs are different from S3 REST API URLs — health checks and redirects behave differently.
- This is perfect for SPAs, portfolios, and documentation. For dynamic content, you need Lambda or EC2.

---

## ✅ Lab Completion Checklist

| Objective | Status |
|-----------|--------|
| S3 bucket created and file uploaded | ✅ |
| IAM user created with least-privilege S3 permissions | ✅ |
| Block All Public Access enabled on sensitive bucket | ✅ |
| Deny-all bucket policy applied (except account owner) | ✅ |
| Confirmed IAM user blocked by bucket policy | ✅ |
| Static website bucket created with `index.html` | ✅ |
| Static Website Hosting enabled | ✅ |
| Troubleshot Access Denied — Block Public Access disabled | ✅ |
| Troubleshot Access Denied — Public Read bucket policy added | ✅ |
| Website live and accessible via S3 endpoint | ✅ |

---

<div align="center">

[← Lab 02: VPC & Load Balancer](../02-EC2-SecurityGroups/) | [Back to Lab Index](../README.md) | [Lab 04: S3 Versioning →](../04-S3-Versioning/)

*In AWS, "no access" is the default. Every door you open, open it deliberately.*

</div>
