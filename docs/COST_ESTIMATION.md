# Cost estimation

> These are **planning estimates**, not a quote. Always verify with the
> [AWS Pricing Calculator](https://calculator.aws) for your region and usage.

## Dev (cost-optimised)

| Resource | Spec | Est. monthly (us-east-1) |
| --- | --- | --- |
| EC2 ×2 | t3.small | ~$30 |
| ALB | small | ~$18 |
| RDS | db.t3.medium Multi-AZ + 50GB gp3 | ~$70 |
| ElastiCache | cache.t3.micro ×1 | ~$12 |
| NAT Gateway ×1 | + data | ~$32 + egress |
| S3 | ops bucket (small) | ~$1 |
| Secrets Manager | a few secrets | ~$2 |
| **Indicative total** | light traffic | **~$90–$160/mo** |

## Prod (availability-optimised)

| Resource | Spec | Est. monthly (us-east-1) |
| --- | --- | --- |
| EC2 ×3+ | t3.medium | ~$90+ |
| ALB | + LCU | ~$25+ |
| RDS | db.r6g.large Multi-AZ + 50GB | ~$260 |
| ElastiCache | cache.r6g.large ×2 | ~$180 |
| NAT Gateway ×3 | + data | ~$96 + egress |
| CloudWatch | logs/metrics/alarms | ~$15+ |
| **Indicative total** | moderate traffic | **~$600–$900/mo** |

## Cost levers

- Dev: single NAT gateway, 1-day backups, smallest cache node, 2 instances.
- Prod: multi-AZ everywhere, 30-day backups, deletion protection (safety > cost).
- Data transfer egress is usage-dependent; keep payloads small (pagination,
  gzip, caching).
- Use Spot where appropriate for non-critical batch work (not the app tier here).
- Turn off dev environments when not in use.
