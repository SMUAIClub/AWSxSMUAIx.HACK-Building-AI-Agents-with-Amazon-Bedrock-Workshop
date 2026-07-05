# Virtual Meteorologist — Bedrock AgentCore Workshop

Terraform reconstruction of the "Build a Weather AI Agent with Amazon Bedrock
AgentCore" workshop (AWS x SMU AI & Hack), built by hand in the console.
Region is fixed to `us-east-1` (workshop account restriction).

**Event page:** [AWS x .HACK x SMUAI: Building AI Agents with Amazon Bedrock](https://luma.com/ec1c6z10)

## Architecture

![Architecture diagram: browser authenticates via Cognito and gets temporary credentials from the Identity Pool, loads the frontend from Amplify, and calls the AgentCore Runtime (Strands agent on Nova 2 Lite), which uses AgentCore Memory and the AgentCore Gateway to invoke the geo_coordinates, weather_forecast, and date_time Lambda functions.](assets/architecture.png)

## Demo
https://github.com/user-attachments/assets/dcd0cbdc-2dd9-4f19-b4b5-e9eda4cfdcdc

## Quickstart

**Prerequisites:** `terraform` (>= 1.5), `aws` CLI configured with credentials
for the target account (`us-east-1`), `pip`, `zip`. The agent runtime code and
frontend bundle are both built/zipped and uploaded locally during `apply` —
see `terraform/artifact.tf` and `terraform/amplify.tf`.

**1. Apply.** The test user's password has no default (so nothing sensitive
lives in this repo) — pass it with `-var`, or put it in a gitignored
`*.tfvars` file:

```bash
cd terraform
terraform init
terraform apply -var="test_user_password=<something satisfying the password policy>"
```

This takes ~10–15 minutes, mostly waiting on the Agent Runtime. When it
finishes, grab the values you'll need next:

```bash
terraform output
```

**2. Open the frontend.** Visit the URL in `amplify_default_domain`. The
`null_resource.deploy_frontend` deployment kicked off during `apply` usually
finishes within a minute or two of `apply` completing — if you get a 404,
wait briefly and refresh, or check status with:

```bash
aws amplify get-job --app-id <amplify_app_id> --branch-name staging --job-id <job-id-from-apply-log>
```

**3. Configure the app.** On first load it shows a setup screen — fill it in
with the Terraform outputs:

| Field | Value |
|---|---|
| User Pool ID | `cognito_user_pool_id` output |
| User Pool Client ID | `cognito_user_pool_client_id` output |
| Identity Pool ID | `cognito_identity_pool_id` output |
| Region | `us-east-1` |
| Agent Selection | `AgentCore Agent` |
| AgentCore ARN | `agent_runtime_arn` output |
| Region | `us-east-1` |

Click Save — this config is stored client-side (browser), not by Terraform.

**4. Log in.** Username is `AppUser` (or whatever `test_user_username` was set
to) with the password you passed in step 1. First login forces a password
change.

**5. Test it.** Try *"What's the weather tomorrow in Dallas, Texas?"* or
*"Can I go swimming in Chicago this weekend?"* — watch it chain
`get_current_time` → `get_coordinates` → `get_forecast` automatically.

## Module coverage

| Module | Covered | Where |
|---|---|---|
| 1. Cognito Authentication | ✅ User Pool (username+email alias, email required/verified), test user, Identity Pool | `terraform/cognito.tf` |
| 2. Lambda Functions | ✅ All 3 (`geo_coordinates`, `weather_forecast`, `date_time`) | `terraform/lambdas.tf`, `lambdas/` |
| 3. AgentCore Gateway & Targets | ✅ Gateway + all 3 targets, schemas match the official tool definitions exactly | `terraform/gateway.tf`, `terraform/gateway_targets.tf` |
| 4. AgentCore Memory | ✅ | `terraform/memory.tf` |
| 5. Agent Runtime | ✅ Role/policy + runtime resource, code built and uploaded to S3 on `apply` | `terraform/runtime.tf`, `terraform/artifact.tf`, `agent/` |
| 6. Identity Pool permissions | ✅ Inline `AgentCoreRuntimeAccess` policy on the authenticated role | `terraform/cognito.tf` |
| 7. Frontend (Amplify) | ✅ App + branch + automated bundle deploy | `terraform/amplify.tf`, `frontend/` |

## Documented bugs vs. this Terraform

A corrections doc from a full manual run-through (`agentcore-weather-agent-modules-5-7.pdf`)
flagged 4 issues in the official guide. Here's how each maps onto the IaC:

| # | Issue | Applies to this Terraform? |
|---|---|---|
| 1 | Official Module 5 policy lists `bedrock:Converse`/`bedrock:ConverseStream`, which aren't valid IAM actions and get the policy rejected | **Fixed.** `runtime.tf` only grants `InvokeModel`/`InvokeModelWithResponseStream` — matches both what's actually deployed live and this correction. (An earlier pass of this Terraform mistakenly *added* those two actions to match the official guide's text — reverted.) |
| 2 | Console button renamed "Host agent/tool" → "Create runtime" | Console-only wording change, no infra impact. |
| 3 | Module 6: identity pool's authenticated role isn't set by default in console | **Doesn't apply.** `aws_cognito_identity_pool_roles_attachment` in `cognito.tf` wires the authenticated role by reference — there's no manual step to forget. |
| 4 | Module 7 (not in official guide): the identity pool role's trust policy `cognito-identity.amazonaws.com:aud` condition can end up pointing at a stale identity pool ID, breaking sign-in | **Doesn't apply.** `cognito_authenticated_assume` in `cognito.tf` sets that condition to `aws_cognito_identity_pool.this.id` directly — always in sync, can't drift. |

This is a good illustration of why the manual console bugs (#3, #4) don't
happen in the IaC version: they're both "forgot to point X at Y" mistakes
that Terraform's resource references make structurally impossible.

## What this deploys

- **3 Lambda tools** — thin wrappers around the Open-Meteo API, `python3.13`.
- **AgentCore Gateway** (`virtual-meteorologist-gateway`) — MCP gateway, IAM
  auth, exposing the 3 Lambdas as tools (`get_coordinates`, `get_forecast`,
  `get_current_time`).
- **AgentCore Memory** — 30-day conversation memory for the agent.
- **AgentCore Runtime** (`virtual_meteorologist`) — runs `agent/main.py` (a
  Strands agent that calls the Gateway over MCP with SigV4 auth, backed by
  Amazon Nova 2 Lite), packaged from source on `apply`.
- **Cognito User Pool + test user + Identity Pool** — auth for end users to
  get temporary AWS credentials that can invoke the Runtime.
- **Amplify app + branch**, with the pre-built frontend bundle
  (`frontend/index.html` + `frontend/assets/`) deployed automatically via
  `frontend/deploy.sh` (the CLI equivalent of the console's drag-and-drop
  upload: `create-deployment` → upload zip → `start-deployment`).

## Layout

```
docs/            original lab guide, archived module-by-module (docs/README.md)
agent/           main.py (agent runtime code) + requirements.txt + build.sh
lambdas/         source for the 3 tool Lambdas
frontend/        pre-built frontend bundle (index.html + assets/) + deploy.sh
terraform/       all infra
```

The original `agent-runtime.zip` and `AWS-Amplify-Frontend.zip` downloads are
kept at the repo root for archival purposes (the exact artifacts the console
workflow produced/consumed). `agent/` and `frontend/` hold the unpacked,
source-controllable equivalents that Terraform actually builds from and
uploads on `apply` — the zips themselves aren't read by Terraform.

## Notes

- This was written against an existing workshop account
  (`467753855785`, `WSParticipantRole`) that already has the manually-created
  resources with the *same names* used here (`geo_coordinates`,
  `VirtualMeteorologistGatewayRole`, etc). Running `apply` in that same
  account will collide with the existing resources — this project is meant to
  redeploy the environment from scratch in a fresh account, not manage the
  existing one in place.
- Workshop AWS credentials are short-lived STS tokens (`AWS_SESSION_TOKEN`)
  and are not stored anywhere in this repo.
- `terraform plan` was run and validated against the real account/provider
  schema (40 resources, 0 errors); `apply` was not run.

## License

The original work in this repo (Terraform, README, workshop-analysis notes)
is [MIT licensed](LICENSE). The archived original workshop materials under
[`docs/`](docs/README.md) — and the Lambda/agent/frontend source derived from
them — remain the property of AWS and the workshop authors, included here for
reference only, not relicensed.
