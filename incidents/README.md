# Incident simulations

Safe, local-first chaos engineering for the sre-reliability-platform.

- See [`INCIDENT_CATALOG.md`](INCIDENT_CATALOG.md) for the full per-scenario
  runbooks (symptoms, expected alerts, investigation, root cause, recovery,
  verification, prevention).
- Trigger via `bash scripts/incident-sim.sh <scenario>`.
- Recover via `bash scripts/service-recovery.sh [app|redis|postgres|all]`.
- AWS-side actions require the explicit `--confirm-aws` flag and never run
  automatically.
