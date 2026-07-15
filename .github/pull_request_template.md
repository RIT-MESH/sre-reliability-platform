## Summary

<!-- What does this PR change and why? -->

## Change type

- [ ] Bug fix
- [ ] New feature
- [ ] Reliability / SRE improvement
- [ ] Infrastructure (Terraform)
- [ ] Monitoring / alerting
- [ ] Documentation
- [ ] CI/CD

## Checklist

- [ ] No secrets, `.env`, `*.tfstate` or private keys committed
- [ ] Unit tests added/updated and passing locally (`cd app && pytest -q`)
- [ ] `ruff check . && ruff format --check .` pass
- [ ] `terraform fmt` + `terraform validate` pass (if Terraform changed)
- [ ] `docker compose config` valid (if compose changed)
- [ ] Docs updated where behaviour changed
- [ ] PR references an issue (e.g. `Closes #123`)

## Risk and rollback

<!-- What could go wrong and how do we roll back? -->
