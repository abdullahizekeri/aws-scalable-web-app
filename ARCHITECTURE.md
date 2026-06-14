# Architecture Documentation

## Overview
This project implements a production-grade scalable web application
on AWS following the Well-Architected Framework principles.

## Architecture Diagram
![Architecture](./diagrams/architecture.png)

## Components

### Networking Layer
- VPC CIDR: 10.0.0.0/16
- 2 Public Subnets (10.0.1.0/24, 10.0.2.0/24)
- 2 Private Subnets (10.0.3.0/24, 10.0.4.0/24)
- 1 NAT Gateway per AZ for high availability
- Internet Gateway for public subnet access

### Compute Layer
- EC2 instances (Amazon Linux 2023, t3.micro)
- Auto Scaling Group: Min 2, Max 6, Desired 2
- Target tracking: CPU at 50%
- Launch Template with IMDSv2 enforced

### Load Balancing & Security
- ALB in public subnets
- WAF with OWASP Top 10 managed rules
- HTTP → HTTPS redirect
- ACM certificate for TLS termination

### Database Layer
- RDS MySQL 8.0 Multi-AZ
- Automated backups (7-day retention)
- Encryption at rest (KMS)
- Private subnet placement

### CDN Layer
- CloudFront distribution
- ALB as origin
- Static asset caching (/static/*)
- WAF associated at edge

### Observability
- CloudWatch Dashboard
- Alarms for CPU, 5XX errors, RDS storage
- SNS email notifications
- Session Manager audit logs in S3

## Design Decisions
| Decision | Rationale |
|----------|-----------|
| NAT Gateway per AZ | Avoid cross-AZ traffic costs and single point of failure |
| Session Manager over Bastion | No exposed SSH port, full audit trail |
| Multi-AZ RDS | Automatic failover, no data loss |
| CloudFront + WAF | Edge protection, reduced origin load |