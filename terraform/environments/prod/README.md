# prod environment

Availability-optimised defaults: 3 AZs, Multi-AZ RDS, 2-node Redis failover,
NAT gateway per AZ, deletion protection on, 30-day backups.

## Apply

```bash
cp terraform.tfvars.example terraform.tfvars     # edit values
cp backend.hcl.example backend.hcl              # edit state bucket
export TF_VAR_redis_auth_token="$(aws secretsmanager get-secret-value --secret-id sre-prod/redis/auth --query SecretString --output text)"
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -out tfplan
# Production deploys should be approved out-of-band before apply:
terraform apply tfplan
```

> Deletion protection is enabled. To tear down, set `deletion_protection=false`
> and run `terraform apply` first, then `terraform destroy`.
