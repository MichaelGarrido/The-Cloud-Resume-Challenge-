# Local development and testing

[Back to the README](../README.md)

Run commands below from the repository root unless noted. CI uses Python 3.12 and Node.js 20. Terraform is required only for infrastructure checks; the workflow does not pin a Terraform CLI version. Keep the committed [provider lockfile](../Infra/.terraform.lock.hcl) when installing providers.

## Python tests

Create a local virtual environment and install the same test dependencies used by CI:

```bash
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install pytest boto3
python -m pytest -v
```

There is no Python dependency manifest in this repository; CI currently installs `pytest` and `boto3` directly. The tests mock DynamoDB and OpenAI calls and require no AWS credentials or OpenAI API key. They cover counter success/client errors, selected question validation, preflight handling, chatbot responses, missing credentials, and quota fallback. They do not exercise a real deployment or the PagerDuty notifier.

## Browser test

```bash
npm ci
CYPRESS_BASE_URL=https://your-test-distribution.cloudfront.net npm run cypress:run
```

Replace the example URL with a deployed test site's URL. Use `npm run cypress:open` with the same environment variable for the interactive runner. The only browser test verifies that the displayed counter increases after a reload; it changes the target site's counter. If `CYPRESS_BASE_URL` is omitted, [cypress.config.js](../cypress.config.js) targets the production portfolio.

## Terraform checks

```bash
terraform -chdir=Infra fmt -check
terraform -chdir=Infra init -backend=false -input=false
terraform -chdir=Infra validate
```

Initialization downloads providers and creates a local `.terraform/` directory; these checks do not apply resources or connect to the configured state backend. Review any provider-lockfile changes before committing. A successful validation does not prove the signed-artifact bootstrap or deployed behavior works.

## Where to edit

| Change | Files |
| --- | --- |
| Resume content and browser behavior | [Frontend/index.html.tpl](../Frontend/index.html.tpl) |
| Visual styling | [Frontend/styles.css](../Frontend/styles.css) |
| Portfolio facts supplied to the chatbot | [Backend/chatbot_knowledge.md](../Backend/chatbot_knowledge.md) |
| Chatbot validation, API handling, and fallback text | [Backend/chatbot_function.py](../Backend/chatbot_function.py) |
| Counter behavior | [Backend/lambda_function.py](../Backend/lambda_function.py) and [tests/test_lambda_function.py](../tests/test_lambda_function.py) |
| Resource configuration and inputs | [Infra/](../Infra/) and [Infra/variables.tf](../Infra/variables.tf) |

The frontend uses Terraform template syntax. Preserve `${api_url}` for substitution, and escape JavaScript template expressions as `$${...}` inside the `.tpl` file. There is no frontend build or local API server configured in `package.json`; opening the raw template does not supply a working API endpoint.

## Local configuration

[terraform.tfvars.example](../Infra/terraform.tfvars.example) documents many resource inputs, but is not a complete deployment configuration: it omits the required `environment` and `openai_api_key` inputs. The tracked [dev.tfvars](../Infra/dev.tfvars) and [prod.tfvars](../Infra/prod.tfvars) contain only their environment selector. Supply remaining inputs explicitly for your intended environment, using the [deployment input guide](operations.md#deployment-inputs).

Keep private values in an ignored local file or an appropriate secret store. `.gitignore` excludes local `*.tfvars`, state, plans, dependency folders, ZIP artifacts, and build output; it does not remove files that were already tracked. Do not replace the tracked environment selector files with credentials.
