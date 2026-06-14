#!/bin/bash
# Destroy all stacks in reverse order
set -e

AWS_REGION=${AWS_REGION:-"us-east-1"}
STACK_PREFIX="scalable-web-app"

echo "⚠️  WARNING: This will delete ALL resources!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo "Deleting stacks in reverse order..."

for stack in monitoring cloudfront alb-waf ec2-asg rds vpc; do
    echo "Deleting $STACK_PREFIX-$stack..."
    aws cloudformation delete-stack \
        --stack-name "$STACK_PREFIX-$stack" \
        --region "$AWS_REGION"
    aws cloudformation wait stack-delete-complete \
        --stack-name "$STACK_PREFIX-$stack" \
        --region "$AWS_REGION"
    echo "✅ $STACK_PREFIX-$stack deleted"
done

echo "✅ All resources deleted successfully"