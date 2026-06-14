#!/bin/bash
# User data script for EC2 instances
set -e

# Update system
yum update -y

# Install dependencies
yum install -y httpd python3 python3-pip amazon-cloudwatch-agent

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create simple web app
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AWS Scalable Web App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #232F3E, #FF9900);
            color: white;
            text-align: center;
        }
        .container {
            background: rgba(0,0,0,0.4);
            padding: 40px;
            border-radius: 12px;
        }
        h1 { font-size: 2.5em; margin-bottom: 10px; }
        p { font-size: 1.2em; }
        .badge {
            background: #FF9900;
            color: #232F3E;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: bold;
            margin-top: 20px;
            display: inline-block;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 AWS Scalable Web App</h1>
        <p>Running on Amazon EC2</p>
        <p>Instance ID: <strong id="instance-id">Loading...</strong></p>
        <p>Availability Zone: <strong id="az">Loading...</strong></p>
        <div class="badge">SAA-C03 Graduation Project</div>
    </div>
    <script>
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(r => r.text())
            .then(id => document.getElementById('instance-id').textContent = id)
            .catch(() => document.getElementById('instance-id').textContent = 'N/A');

        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(r => r.text())
            .then(az => document.getElementById('az').textContent = az)
            .catch(() => document.getElementById('az').textContent = 'N/A');
    </script>
</body>
</html>
EOF

# Health check endpoint
mkdir -p /var/www/html/health
echo '{"status":"healthy"}' > /var/www/html/health/index.html

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "append_dimensions": {
            "InstanceId": "${aws:InstanceId}"
        },
        "metrics_collected": {
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["disk_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "/aws/ec2/httpd/access",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/httpd/error_log",
                        "log_group_name": "/aws/ec2/httpd/error",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

echo "Userdata script completed successfully"