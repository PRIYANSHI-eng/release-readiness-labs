# OrderFlow v2.3.0 – Release Readiness Pack

| Field | Value |
|---|---|
| Product | OrderFlow |
| Release version | **v2.3.0** |
| Previous version | v2.2.0 |
| Git tag | `v2.3.0` |
| Container image | `lab-app:v2.3.0` |
| Target environment | production |
| Infrastructure | Kubernetes (3 replicas) |
| Release manager | Priyanshi Chittora |
| Release date | 2026-11-04 |
| Status | Ready for production |

---

## 1. Release version information

The release version **v2.3.0** is defined once in the pipeline (`env: RELEASE_VERSION: v2.3.0`)
and is used everywhere:

| Location | Value |
|---|---|
| `.github/workflows/release.yml` | `RELEASE_VERSION: v2.3.0` |
| `app/package.json` | `"version": "2.3.0"` |
| `release/release.json` | `"version": "2.3.0"` |
| `release/release-summary.yml` | `version: v2.3.0` |
| `release/deployment-config.yml` | `version: v2.3.0`, `image: lab-app:v2.3.0` |
| `deployment/kubernetes/deployment.yaml` | `image: lab-app:v2.3.0` |
| Git tag | `v2.3.0` |

The **"Validate release metadata"** step fails the pipeline if any of these versions do not match,
so every deployed artifact can be traced back to one unique version. Image tags are immutable
(`v2.3.0`), never `latest` or `production-build`.

## 2. Deployment strategy

- **Pipeline order:** `validate-release` → `deploy-production`. The deploy job uses
  `needs: validate-release`, so production can only run after validation succeeds.
- **Validation stage:** installs dependencies, runs tests, and checks release version consistency.
- **Trigger rule:** production deploys only from `main` or a `v*` tag
  (`if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/v')`).
- **Approval gate:** the deploy job uses the protected GitHub environment `production`, which
  requires a reviewer to approve before the deployment starts.
- **Versioned deploy:** `./scripts/deploy.sh "${RELEASE_VERSION}"` deploys exactly v2.3.0.
- **Kubernetes rolling update:** the Deployment runs 3 replicas and uses Kubernetes'
  default `RollingUpdate` strategy, so pods are replaced gradually without taking the service down.

## 3. Rollback strategy

| Item | Value |
|---|---|
| Method | `kubectl rollout undo deployment/lab-app` |
| Target version | v2.2.0 (last stable release) |
| Script | `./scripts/rollback.sh v2.2.0` |
| Time limit | 5 minutes |
| Owner | Priyanshi Chittora (release manager) |

**Roll back when:**
- the `/health` endpoint fails after deployment
- `kubectl rollout status deployment/lab-app` does not finish within 120 seconds
- error rate or latency rises above normal after the release

**Verify rollback:** `kubectl rollout status deployment/lab-app` succeeds and `/health`
returns `status: ok`.

## 4. Deployment infrastructure decision

| Option | Decision | Reason |
|---|---|---|
| Single `t2.micro` EC2 instance | Rejected | Free-tier/burstable size, single point of failure, no rolling update, no simple rollback |
| **Kubernetes Deployment – 3 replicas + LoadBalancer Service** | **Chosen** | High availability, self-healing pods, rolling updates, one-command rollback, native Secrets |

Secrets are injected through the Kubernetes Secret `lab-app-secrets` (`secretKeyRef`)
instead of plain-text values in the manifest.

## 5. Production approval checklist

- [x] Validation stage passes before deployment (`needs: validate-release`)
- [x] Tests pass (`npm test`)
- [x] Release version v2.3.0 is consistent across all files
- [x] No hardcoded secrets in `deployment.yaml` or `deployment-config.yml`
- [x] Secrets come from GitHub Secrets / Kubernetes Secret `lab-app-secrets`
- [x] Image tag is immutable (`lab-app:v2.3.0`)
- [x] `production` environment requires reviewer approval
- [x] Production deploy restricted to `main` and `v*` tags
- [x] Infrastructure decision reviewed (Kubernetes, 3 replicas)
- [x] Rollback plan and script reviewed
- [x] Release approved by release manager (`release/approvals.yml`)

## 6. Deployment validation summary

| Check | Stage | Result |
|---|---|---|
| Install dependencies | validate-release | Passed |
| Unit tests (`npm test`) | validate-release | Passed |
| Release metadata / version check | validate-release | Passed |
| Manual approval (production environment) | deploy-production | Approved |
| Production deployment of v2.3.0 | deploy-production | Passed |

Evidence: GitHub → Actions → **Release Pipeline** → "Merge pull request #1" run –
Status **Success**, deployment to `production` approved.

## Issues found and fixed

| # | File | Problem | Fix |
|---|---|---|---|
| 1 | `.github/workflows/release.yml` | Deployed to production **before** validation | `deploy-production` now `needs: validate-release` |
| 2 | `.github/workflows/release.yml` | Validation always failed (`exit 1`) | Removed; real tests and version checks added |
| 3 | `.github/workflows/release.yml` | No approval / environment protection | `environment: production` with required reviewer |
| 4 | `.github/workflows/release.yml` | No release version, old `checkout@v3` | `RELEASE_VERSION: v2.3.0`, `checkout@v4`, tag trigger `v*` |
| 5 | `deployment/kubernetes/deployment.yaml` | Plain-text `API_KEY` and `DATABASE_PASSWORD` | `secretKeyRef` to `lab-app-secrets` |
| 6 | `deployment/kubernetes/deployment.yaml` | Untraceable image tag `production-build` | `lab-app:v2.3.0` |
| 7 | `release/deployment-config.yml` | Hardcoded secrets, tag `production-build` | Secret references only, `v2.3.0`, `infrastructure: kubernetes` |
| 8 | `app/package.json`, `release/release.json` | Wrong version (`1.0.0` / `1.0`) | `2.3.0` |
| 9 | `release/approvals.yml` | Empty | Approval details and reviewer filled in |
| 10 | `release/rollback.yml`, `scripts/rollback.sh` | Empty – no rollback | Rollback strategy to v2.2.0 |
| 11 | `release/release-summary.yml` | `version: latest`, `rollback: none` | `version: v2.3.0`, rollback defined |