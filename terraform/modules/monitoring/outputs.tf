output "alert_topic_arn" { value = aws_sns_topic.alerts.arn }
output "app_log_group" { value = aws_cloudwatch_log_group.app.name }
output "alb_log_group" { value = aws_cloudwatch_log_group.alb.name }
output "dashboard_name" { value = aws_cloudwatch_dashboard.this.dashboard_name }
