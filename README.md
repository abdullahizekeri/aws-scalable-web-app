# 🚀 AWS Scalable Web Application

![AWS](https://img.shields.io/badge/AWS-SAA--C03-orange?logo=amazon-aws)
![CloudFormation](https://img.shields.io/badge/IaC-CloudFormation-blue)
![License](https://img.shields.io/badge/License-Apache%202.0-green)
![Status](https://img.shields.io/badge/Status-Live-brightgreen)

> Production-grade scalable web application on AWS — SAA-C03 Graduation Project

---

## 📐 Architecture

![Architecture Diagram](./diagrams/architecture.png)

---

## 🌍 Live Demo

| Endpoint | URL |
|----------|-----|
| ALB (direct) | http://scalable-web-app-alb-1562775529.us-east-1.elb.amazonaws.com |
| CloudFront (CDN) | https://d4swcrka279hq.cloudfront.net |

---

## 🛠️ AWS Services Used

| Category | Services |
|----------|----------|
| Networking | VPC, Public & Private Subnets, NAT Gateway, Internet Gateway, Security Groups, NACLs |
| Compute | EC2 (Amazon Linux 2023), Auto Scaling Group, Launch Template |
| Load Balancing | Application Load Balancer (ALB) |
| Security | WAF (OWASP rules), IAM Roles, KMS Encryption |
| Database | RDS MySQL 8.0 Multi-AZ |
| CDN | CloudFront |
| DNS | Route 53 |
| Monitoring | CloudWatch Dashboards, Alarms, SNS Notifications |
| Access | Systems Manager Session Manager (no SSH) |

aws-scalable-web-app/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   ├── CODEOWNERS
│   └── PULL_REQUEST_TEMPLATE.md
├── deployment/
│   ├── cloudformation/
│   │   ├── vpc.yaml          # VPC, subnets, NAT gateways, security groups
│   │   ├── ec2-asg.yaml      # Launch template, Auto Scaling Group, IAM roles
│   │   ├── alb-waf.yaml      # Application Load Balancer, WAF Web ACL
│   │   ├── cloudfront.yaml   # CloudFront distribution
│   │   ├── rds.yaml          # RDS MySQL Multi-AZ instance
│   │   └── monitoring.yaml   # CloudWatch dashboard, alarms, SNS
│   └── scripts/
│       ├── deploy.sh         # Deploy all stacks in order
│       └── destroy.sh        # Tear down all resources
├── source/
│   ├── app/                  # Application source files
│   └── userdata/
│       └── userdata.sh       # EC2 bootstrap script
├── docs/
│   └── screenshots/          # AWS Console screenshots
├── diagrams/
│   └── architecture.png      # Architecture diagram
├── ARCHITECTURE.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── README.md
└── SECURITY.md

---

## 📁 Repository Structure

---

## ✅ Prerequisites

- AWS Account with admin IAM access
- AWS CLI v2 installed and configured
- Git installed on your machine

---

## 🚀 Deployment Guide

### 1. Clone the repository

```bash
git clone https://github.com/your-username/aws-scalable-web-app.git
cd aws-scalable-web-app
```

### 2. Configure AWS CLI

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
```

### 3. Deploy stacks in order

```bash
# Stack 1: VPC and networking
aws cloudformation deploy \
  --template-file deployment/cloudformation/vpc.yaml \
  --stack-name scalable-web-app-vpc \
  --region us-east-1 \
  --capabilities CAPABILITY_IAM

# Stack 2: EC2 and Auto Scaling Group
aws cloudformation deploy \
  --template-file deployment/cloudformation/ec2-asg.yaml \
  --stack-name scalable-web-app-ec2-asg \
  --region us-east-1 \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM

# Stack 3: ALB and WAF
aws cloudformation deploy \
  --template-file deployment/cloudformation/alb-waf.yaml \
  --stack-name scalable-web-app-alb-waf \
  --region us-east-1 \
  --capabilities CAPABILITY_IAM

# Stack 4: CloudFront
aws cloudformation deploy \
  --template-file deployment/cloudformation/cloudfront.yaml \
  --stack-name scalable-web-app-cloudfront \
  --region us-east-1

# Stack 5: Monitoring
aws cloudformation deploy \
  --template-file deployment/cloudformation/monitoring.yaml \
  --stack-name scalable-web-app-monitoring \
  --region us-east-1 \
  --parameter-overrides AlertEmail=your-email@example.com

# Stack 6: RDS (takes ~15 minutes)
aws cloudformation deploy \
  --template-file deployment/cloudformation/rds.yaml \
  --stack-name scalable-web-app-rds \
  --region us-east-1 \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides DBPassword=YourSecurePassword123!
```

### 4. Attach ASG to ALB Target Group

```bash
TG_ARN=$(aws cloudformation describe-stacks \
  --stack-name scalable-web-app-alb-waf \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`TargetGroupArn`].OutputValue' \
  --output text)

ASG_NAME=$(aws cloudformation describe-stacks \
  --stack-name scalable-web-app-ec2-asg \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`AutoScalingGroupName`].OutputValue' \
  --output text)

aws autoscaling attach-load-balancer-target-groups \
  --auto-scaling-group-name $ASG_NAME \
  --target-group-arns $TG_ARN \
  --region us-east-1
```

### 5. Get your application URLs

```bash
# ALB URL
aws cloudformation describe-stacks \
  --stack-name scalable-web-app-alb-waf \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ALBDNSName`].OutputValue' \
  --output text

# CloudFront URL
aws cloudformation describe-stacks \
  --stack-name scalable-web-app-cloudfront \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
  --output text
```

---

## 🏗️ Architecture Overview

### Networking Layer
- VPC CIDR: `10.0.0.0/16` across `us-east-1`
- 2 Public Subnets: `10.0.1.0/24` (1a), `10.0.2.0/24` (1b)
- 2 Private Subnets: `10.0.3.0/24` (1a), `10.0.4.0/24` (1b)
- 1 NAT Gateway per AZ for high availability and no cross-AZ traffic

### Compute Layer
- EC2 instances running Amazon Linux 2023
- Auto Scaling Group: Min 2, Max 6, Desired 2
- Target tracking scaling policy: CPU at 50%
- IMDSv2 enforced on all instances

### Load Balancing & Security
- ALB in public subnets with HTTP listener on port 80
- WAF with AWS Managed Rules: CommonRuleSet, SQLiRuleSet
- Rate-based rule: 2000 requests per 5 minutes per IP

### Database Layer
- RDS MySQL 8.0 in Multi-AZ configuration
- Automated backups with 7-day retention
- Encryption at rest using AWS KMS
- Placed in private subnets only

### CDN Layer
- CloudFront distribution with ALB as custom origin
- Static asset caching on `/static/*` path pattern
- Dynamic content bypasses cache

### Observability
- CloudWatch Dashboard with EC2, ALB, and RDS metrics
- Alarms for CPU > 80% and ALB 5XX errors > 10
- SNS email notifications for all alarm state changes
- Systems Manager Session Manager for secure instance access

---

## 🔒 Security Highlights

- EC2 instances in **private subnets only** — no direct internet access
- **No SSH ports open** — access via Systems Manager Session Manager
- **WAF enabled** on ALB with OWASP Top 10 managed rules
- **RDS encrypted** at rest with AWS KMS
- **IAM roles** follow least privilege principle
- **Security groups** use source-based rules (no `0.0.0.0/0` on private resources)

---

## 📸 Screenshots

| Component | Description |
|-----------|-------------|
| VPC | Custom VPC with public and private subnets |
| Auto Scaling Group | EC2 instances scaling across two AZs |
| Application Load Balancer | Internet-facing ALB with target group |
| WAF | Web ACL with OWASP managed rules |
| RDS | MySQL Multi-AZ database instance |
| CloudFront | Global CDN distribution |
| CloudWatch | Dashboard and alarms |

> Screenshots available in [`docs/screenshots/`](./docs/screenshots/)

---

## 🧹 Cleanup

To avoid AWS charges, delete all resources:

```bash
chmod +x deployment/scripts/destroy.sh
./deployment/scripts/destroy.sh
```

Or manually delete stacks in reverse order:

```bash
for stack in monitoring cloudfront alb-waf ec2-asg rds vpc; do
  aws cloudformation delete-stack \
    --stack-name scalable-web-app-$stack \
    --region us-east-1
  echo "Deleting scalable-web-app-$stack..."
  aws cloudformation wait stack-delete-complete \
    --stack-name scalable-web-app-$stack \
    --region us-east-1
  echo "✅ scalable-web-app-$stack deleted"
done
```

---

## 💡 Design Decisions

| Decision | Rationale |
|----------|-----------|
| NAT Gateway per AZ | Avoids cross-AZ traffic costs and single point of failure |
| Session Manager over Bastion | No exposed SSH port, full CloudTrail audit trail |
| Multi-AZ RDS | Automatic failover, zero data loss on AZ failure |
| CloudFront + WAF | Edge protection reduces origin load and latency |
| Target tracking ASG policy | Simpler than step scaling, automatically adjusts to load |
| Private subnets for EC2 | Defense in depth, no direct internet exposure |

---

## 📖 Documentation

- [Architecture Details](./ARCHITECTURE.md)
- [Security Policy](./SECURITY.md)
- [Contributing Guide](./CONTRIBUTING.md)
- [Changelog](./CHANGELOG.md)

---

## 👤 Author

**Zekeri Abdullahi**
AWS Solutions Architect — Associate (SAA-C03) Graduation Project

---

## 📝 License

Apache-2.0 — see [LICENSE](./LICENSE) for details.