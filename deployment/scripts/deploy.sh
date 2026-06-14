#!/bin/bash
# Deploy script for AWS Scalable Web App
set -e

echo "========================================="
echo " AWS Scalable Web App - Deployment Script"
echo "========================================="

# Configuration
AWS_REGION=${AWS_REGION:-"us-east-1"}
STACK_PREFIX="scalable-web-app"
KEY_PAIR_NAME=${KEY_PAIR_NAME:-"your-key-pair"}

echo "Region: $AWS_REGION"
echo "Stack Prefix: $STACK_PREFIX"

# Step 1: Deploy VPC
echo ""
echo "[1/6] Deploying VPC Stack..."
aws cloudformation deploy \
    --template-file deployment/cloudformation/vpc.yaml \
    --stack-name "$STACK_PREFIX-vpc" \
    --region "$AWS_REGION" \
    --capabilities CAPABILITY_IAM
echo "✅ VPC Stack deployed"

# Step 2: Deploy RDS
echo ""
echo "[2/6] Deploying RDS Stack..."
aws cloudformation deploy \
    --template-file deployment/cloudformation/rds.yaml \
    --stack-name "$STACK_PREFIX-rds" \
    --region "$AWS_REGION" \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        VpcStackName="$STACK_PREFIX-vpc"
echo "✅ RDS Stack deployed"

# Step 3: Deploy EC2 + ASG
echo ""
echo "[3/6] Deploying EC2/ASG Stack..."
aws cloudformation deploy \
    --template-file deployment/cloudformation/ec2-asg.yaml \
    --stack-name "$STACK_PREFIX-ec2-asg" \
    --region "$AWS_REGION" \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        VpcStackName="$STACK_PREFIX-vpc" \
        KeyPairName="$KEY_PAIR_NAME"
echo "✅ EC2/ASG Stack deployed"

# Step 4: Deploy ALB + WAF
echo ""
echo "[4/6] Deploying ALB/WAF Stack..."
aws cloudformation deploy \
    --template-file deployment/cloudformation/alb-waf.yaml \
    --stack-name "$STACK_PREFIX-alb-waf" \
    --region "$AWS_REGION" \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        VpcStackName="$STACK_PREFIX-vpc" \
        AsgStackName="$STACK_PREFIX-ec2-asg"
echo "✅ ALB/WAF Stack deployed"

# Step 5: Deploy CloudFront
echo ""
echo "[5/6] Deploying CloudFront Stack..."
aws cloudformation deploy \
    --template-file deployment/cloudformation/cloudfront.yaml \
    --stack-name "$STACK_PREFIX-cloudfront" \
    --region "$AWS_REGION" \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        AlbStackName="$STACK_PREFIX-alb-waf"
echo "✅ CloudFront Stack deployed"

# Step 6: Deploy Monitoring
echo ""
echo "[6/6] Deploying Monitoring Stack..."
aws cloudformation deploy \
    --template-file deployment/cloudformation/monitoring.yaml \
    --stack-name "$STACK_PREFIX-monitoring" \
    --region "$AWS_REGION" \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        AlbStackName="$STACK_PREFIX-alb-waf" \
        AsgStackName="$STACK_PREFIX-ec2-asg" \
        RdsStackName="$STACK_PREFIX-rds" \
        AlertEmail="your-email@example.com"
echo "✅ Monitoring Stack deployed"

echo ""
echo "========================================="
echo " ✅ All stacks deployed successfully!"
echo "========================================="

# Get CloudFront URL
CF_URL=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_PREFIX-cloudfront" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
    --output text)

echo ""
echo "🌍 Application URL: https://$CF_URL"
echo ""