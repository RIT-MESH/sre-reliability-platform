output "state_bucket" { value = aws_s3_bucket.tf_state.id }
output "lock_table" { value = aws_dynamodb_table.tf_lock.name }
output "github_actions_role_arn" { value = aws_iam_role.github_actions.arn }
output "kms_key_arn" { value = aws_kms_key.tf_state.arn }
