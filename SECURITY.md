# Security Policy

## Reporting a Vulnerability
Please do NOT open a public GitHub issue for security vulnerabilities.
Instead, email: your-email@example.com

## Security Best Practices in this Project
- All EC2 instances are in private subnets
- No SSH access — Systems Manager Session Manager only
- WAF enabled on ALB and CloudFront
- RDS encrypted at rest with KMS
- Secrets stored in AWS Secrets Manager
- All traffic encrypted in transit (HTTPS)
- IAM roles follow least privilege principle