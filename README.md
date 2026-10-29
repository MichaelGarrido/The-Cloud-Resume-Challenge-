# The Cloud Resume Challenge

Michael Garrido's serverless resume and portfolio, built with AWS, Terraform, Python, and a static HTML/CSS frontend. The project includes a DynamoDB-backed visit counter, a portfolio chatbot, and GitHub Actions delivery workflows.

[Portfolio](https://michaelgarridoresume.com/) · [Repository](https://github.com/MichaelGarrido/The-Cloud-Resume-Challenge-)

## What is implemented

- A private S3 site served through CloudFront, with Route 53 and an ACM certificate for production.
- `GET /counter`: a Python Lambda atomically increments a shared DynamoDB counter. It counts requests, not unique visitors.
- `POST /chat`: a Python Lambda sends a question and the bundled portfolio knowledge base to OpenAI. Selected quota/rate-limit errors return local fallback answers.
- Terraform definitions for the application, AWS Signer, CloudWatch logs, and optional monitoring/PagerDuty integration.
- pytest unit tests, a Cypress counter test, signed-commit verification, CodeQL, and Syft/Grype artifact scanning.
- Workflows that attempt PR test deployments, production deployment, and cleanup when PRs close. Production approval and merge protections require GitHub configuration.

This describes the checked-in implementation, not a verification of the live deployment or repository settings. Review the [deployment requirements and known limits](docs/operations.md) before running the workflows.

## Repository map

| Location | Purpose |
| --- | --- |
| [Frontend/](Frontend/) | Resume template, stylesheet, error page, and architecture SVG |
| [Backend/](Backend/) | Counter, chatbot, PagerDuty notifier, and chatbot knowledge base |
| [Infra/](Infra/) | Terraform resources, remote-state configuration, and example inputs |
| [tests/](tests/) | Mocked Python unit tests |
| [cypress/](cypress/) | Browser test for the deployed counter |
| [.github/workflows/](.github/workflows/) | Delivery, signature checks, and CodeQL |
| [.github/scripts/](.github/scripts/) | AWS Signer artifact helper |
| [docs/](docs/) | Architecture, development, operations, and security guides |

Directory names and capitalization are part of the workflow paths. Keep generated packages, dependency folders, local credentials, and Terraform state out of version control.

## Start here

1. Follow [local development and testing](docs/development.md) to run the mocked tests without AWS credentials.
2. Read the [architecture and API behavior](docs/architecture.md) to understand the runtime and where to make changes.
3. Use the [operations guide](docs/operations.md) for deployment inputs, workflow triggers, monitoring, and cleanup.
4. Review [security and supply chain](docs/security-supply-chain.md) for GitHub protection settings and outstanding risks.

**Publishing documentation can trigger deployments.** The delivery workflow has no path filters: PR events targeting `main` deploy a test stack, closing a PR attempts cleanup, and a push to `main` starts production deployment. See the [event table](docs/operations.md#workflow-events).
