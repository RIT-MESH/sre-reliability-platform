# dev environment

Lower-cost defaults for development and interview walkthroughs.

## Apply

```bash
cp terraform.tfvars.example terraform.tfvars   # edit values
cp backend.hcl.example backend.hcl            # edit state bucket
export TF_VAR_redis_auth_token="$(aws secretsmanager get-secret-value --secret-id sre-dev/redis/auth --query SecretString --output text)"
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

## Destroy

```bash
terraform destroy
```

> Dev sets `deletion_protection = false` and 1-day backups to keep costs low.
> Prod keeps deletion protection on and 30-day backups.
