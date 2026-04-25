# The Cloud Resume Challenge

Serverless resume site built with AWS S3, CloudFront, Route 53, Lambda, API Gateway, DynamoDB, Terraform, GitHub Actions, Cypress, and pytest.

## Supply Chain Security

The CI/CD pipeline now includes signed-commit verification, CodeQL, Syft SBOM generation, Grype vulnerability scanning, Lambda code signing with AWS Signer, per-PR test environments, production approval, and merged-PR test environment cleanup.

See [docs/security-supply-chain.md](docs/security-supply-chain.md) for the flow diagram, GitHub settings checklist, and remaining risks.
