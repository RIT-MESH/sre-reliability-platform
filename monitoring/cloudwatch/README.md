# CloudWatch monitoring

The Terraform `monitoring` module provisions:
- an SNS alert topic (+ optional email subscription)
- CloudWatch log groups for the app and ALB
- CloudWatch alarms (CPU, unhealthy targets, 5xx rate, latency, RDS storage/CPU/connections, Redis CPU/memory)
- a CloudWatch dashboard

`cloudwatch-agent-config.json` is the Amazon CloudWatch Agent configuration
applied to EC2 instances to collect CPU, memory, disk and disk-io metrics plus
user-data logs. Deploy it with SSM (AmazonCloudWatch-Agent association) or bake
it into the AMI/user-data.

The Prometheus + Grafana stack in `monitoring/prometheus` and
`monitoring/grafana` is used for the **local Docker Compose** environment and as
an on-host/EC2 observability option. AWS production uses CloudWatch as the
system of record, with Prometheus metrics optionally forwarded via the
Prometheus remote write / CloudWatch agent.
