# Deployment and operations

[Back to the README](../README.md)

This guide describes [.github/workflows/deploy.yaml](../.github/workflows/deploy.yaml) and the current Terraform configuration. Repository settings and deployed AWS resources must be checked separately.

## Workflow events

| Event | Configured action |
| --- | --- |
| PR to `main`: opened, updated (`synchronize`), or reopened | Validate, scan backend artifacts, apply a `pr-<number>` AWS stack, then run Cypress against its CloudFront URL |
| PR to `main`: closed, whether merged or unmerged | Attempt to destroy that PR's test stack |
| Push to `main` | Validate, scan, deploy production, then run Cypress against production |
| Manual dispatch of Staged Delivery | Run the production path using the selected workflow ref |

**There are no file/path filters or draft-PR exclusions.** Documentation-only changes can reach AWS deployment steps. The workflow's `production` environment name does not itself create an approval requirement; required reviewers and allowed deployment branches must be set in GitHub. AWS roles and secrets also determine which events can deploy; fork PRs do not normally receive repository secrets.

Signed-commit verification and CodeQL run as separate workflows. The deployment jobs directly depend on validation and the SBOM/Grype job; signed-commit and CodeQL results are not explicit deployment dependencies. Configure branch protections and environment controls as described in the [security guide](security-supply-chain.md).

## Deployment inputs

Before enabling delivery, prepare AWS OIDC roles with repository-scoped trust, S3 remote-state storage, DynamoDB lock tables, a public Route 53 zone for production, and a globally unique site bucket prefix. The Terraform stack does not create those state resources or the GitHub deployment roles.

| GitHub setting | Use in the current workflow |
| --- | --- |
| Variable `AWS_REGION` | AWS credentials and Terraform provider region |
| Variable `BUCKET_NAME` | Prefix for website and signing-artifact bucket names |
| Variable `DOMAIN_NAME` | Production root domain |
| Variable `ROUTE53_ZONE_ID` | Optional public hosted-zone ID when domain lookup is ambiguous |
| Variable `ALERT_EMAIL` | SNS email destination |
| Variable `PAGERDUTY_URL` | Notifier endpoint input, even when the optional notifier is disabled |
| Variables `TEST_TF_STATE_BUCKET`, `TEST_TF_LOCK_TABLE` | PR state bucket and lock table |
| Secrets `TEST_AWS_ROLE_ARN`, `PROD_AWS_ROLE_ARN` | AWS roles assumed by GitHub Actions |
| Secret `PAGERDUTY_INTEGRATION_KEY` | Sensitive PagerDuty input |
| Secret `OPENAI_API_KEY` | Sensitive chatbot input |

These inputs are mapped to `TF_VAR_*` environment variables where appropriate. See [variables.tf](../Infra/variables.tf) for all defaults and optional controls. Production monitoring is on by default; PagerDuty, X-Ray, and DynamoDB point-in-time recovery are off by default. The required PagerDuty inputs still have to be supplied to Terraform even if the integration is disabled; an empty key can be used when that feature remains off.

PR state keys are `cloud-resume/pr-<number>/terraform.tfstate`. Production initialization instead reads the committed [backend-prod.hcl](../Infra/backend-prod.hcl), which contains a specific bucket, region, lock table, and state key. The workflow currently does **not** read `PROD_TF_STATE_BUCKET` or `PROD_TF_LOCK_TABLE` repository variables. Review and reconcile that backend configuration before deploying in a different account. [backend-dev.hcl](../Infra/backend-dev.hcl) is a local-development configuration and is not used by the delivery workflow.

## Delivery sequence and current limits

The workflow validates Python/Terraform, scans copied backend sources with Syft/Grype, bootstraps signing resources with a targeted apply, creates and signs ZIPs, applies the full stack using signed object versions, invalidates four CloudFront paths, and runs Cypress. Useful Terraform outputs include `site_url`, `visitor_api_url`, `cloudfront_distribution_id`, the counter's Lambda/table names, and the signing profile/bucket.

Review these implementation limits before relying on a new deployment:

- **Bootstrap dependency order:** the signing bootstrap also targets counter alarms and the optional PagerDuty Lambda. Those targets can pull Lambda resources into the apply before the signed artifact inputs exist, while signing enforcement defaults to `Enforce`. Review the bootstrap plan and dependency closure before a first deployment; do not assume this is a complete blank-account bootstrap.
- **Cleanup:** the signing bucket is versioned and receives files outside Terraform's managed objects. It has no `force_destroy` configuration. A nonempty bucket can prevent PR teardown; its lifecycle rules are not immediate cleanup. Inspect a failed teardown and use an explicit artifact-retention/cleanup plan before retrying.
- **Chatbot coverage:** unit tests mock the OpenAI boundary, and Cypress only covers the counter. The handler expects top-level `output_text`; real upstream response parsing is not tested. Its HTTP timeout is 20 seconds while the Lambda timeout is 15 seconds, so a slow upstream call can end at the Lambda limit first.
- **Secrets and state:** sensitive Terraform inputs are passed into Lambda environment variables and can be present in state. Protect state access and avoid sharing state or plan files.

These are source-review observations, not evidence of a successful or failed live deployment.

## Routine checks and troubleshooting

| Symptom | First checks |
| --- | --- |
| Frontend shows `Live` instead of a count | Browser request to `/counter`, API response, counter Lambda logs, DynamoDB table name/permissions |
| Chat returns a configuration error | GitHub secret mapping and the chatbot Lambda's environment; avoid printing the key |
| Chat returns a local fallback | Upstream quota/rate-limit error code in chatbot logs; fallback only handles the two documented codes |
| Chat times out or returns the generic answer | Lambda duration, HTTP timeout, and real upstream response shape |
| Site changes are stale | Terraform's uploaded objects and the workflow's CloudFront invalidation result |
| Alerts are absent | Monitoring toggle, counter alarm thresholds, and confirmed SNS email subscription |
| PR cleanup fails | Correct PR state key, workflow logs, remaining resources, and versioned signing-bucket contents |

Counter CloudWatch alarms publish both alarm and OK transitions to SNS. The PagerDuty notifier always sends a `trigger` action; it does not translate recovery events into incident resolution. Default log retention is 30 days in production and 7 days elsewhere. Tests and manual visits increment the shared counter, so compare behavior rather than expecting a fixed count.
