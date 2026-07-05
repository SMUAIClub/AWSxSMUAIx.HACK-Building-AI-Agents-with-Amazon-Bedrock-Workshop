output "gateway_url" {
  description = "MCP endpoint URL for the AgentCore Gateway."
  value       = aws_bedrockagentcore_gateway.this.gateway_url
}

output "agent_runtime_arn" {
  description = "ARN of the AgentCore Runtime (invoke this to talk to the agent)."
  value       = aws_bedrockagentcore_agent_runtime.this.agent_runtime_arn
}

output "memory_id" {
  description = "ID of the AgentCore Memory resource."
  value       = aws_bedrockagentcore_memory.this.id
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID."
  value       = aws_cognito_user_pool.this.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool App Client ID."
  value       = aws_cognito_user_pool_client.this.id
}

output "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID (used by clients to get temporary AWS credentials for invoking the runtime)."
  value       = aws_cognito_identity_pool.this.id
}

output "agent_runtime_code_bucket" {
  description = "S3 bucket holding the built agent runtime code artifact."
  value       = aws_s3_bucket.agent_runtime_code.bucket
}

output "amplify_app_id" {
  description = "Amplify app ID. Upload the frontend zip via `aws amplify create-deployment` / `start-deployment` against this app and the staging branch."
  value       = aws_amplify_app.frontend.id
}

output "amplify_default_domain" {
  description = "Default Amplify domain for the frontend (once a deployment is uploaded)."
  value       = "${aws_amplify_branch.staging.branch_name}.${aws_amplify_app.frontend.default_domain}"
}
