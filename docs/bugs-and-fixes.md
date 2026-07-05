# Summary of Bugs & Fixes

Found during a full run-through of Modules 5–7, documented in
[agentcore-weather-agent-modules-5-7.pdf](agentcore-weather-agent-modules-5-7.pdf).
These are folded inline into the relevant module docs as **BUG / FIX**
callouts; this table is just the quick-reference index.

| # | Module | Issue | Fix |
|---|---|---|---|
| 1 | 5 — Tab 1 (IAM Policy) | `bedrock:Converse` / `bedrock:ConverseStream` are not valid IAM actions | Remove both from the `BedrockModelAccess` policy statement |
| 2 | 5 — Tab 2 (Deploy) | Button "Host agent/tool" renamed | Click **Create runtime** instead |
| 3 | 6 — Identity Pool | Authenticated role not set by default | **User access** → **Edit role** → **Use an existing role** → `cognito-identity-pool-iam-role` → **Save** |
| 4 | 7 — Amplify (not in original guide) | Identity pool role's trust policy has a stale `cognito-identity.amazonaws.com:aud` ID, breaking sign-in | **IAM → Roles → `cognito-identity-pool-iam-role`** (`service-role/`) **→ Trust relationships → Edit** → replace the `aud` ID with the Identity Pool ID from Cognito |

## How these map onto the Terraform reconstruction

See the [Terraform README](../README.md#documented-bugs-vs-this-terraform)
for the full breakdown, but in short:

- **#1 is fixed** in `terraform/runtime.tf` — only grants `InvokeModel` /
  `InvokeModelWithResponseStream`, matching both this correction and what's
  actually deployed live.
- **#2** is a console-only wording change with no infrastructure impact.
- **#3 and #4 don't apply** to the Terraform version at all. Both are
  "forgot to point X at Y" mistakes possible only when wiring resources
  together by hand in the console — `aws_cognito_identity_pool_roles_attachment`
  and the `cognito_authenticated_assume` policy document reference the
  actual resource IDs directly, so there's no manual step to forget and no
  way for the values to drift out of sync.
