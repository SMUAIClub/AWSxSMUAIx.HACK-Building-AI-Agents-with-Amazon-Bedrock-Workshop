resource "aws_cognito_user_pool" "this" {
  name = "${var.name_prefix}-user-pool"

  deletion_protection = "ACTIVE"

  # Module 1 used the Cognito "Quick setup" flow with sign-in identifiers
  # "Email and Username": users sign up with a username, but can also sign in
  # with their email (alias), and email must be supplied and verified.
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  password_policy {
    minimum_length                   = 8
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  sign_in_policy {
    allowed_first_auth_factors = ["PASSWORD"]
  }
}

# Module 1's test user, used to log into the Amplify frontend in Module 7.
resource "aws_cognito_user" "app_user" {
  user_pool_id = aws_cognito_user_pool.this.id
  username     = var.test_user_username
  password     = var.test_user_password

  attributes = {
    email          = var.test_user_email
    email_verified = true
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name         = "${replace(title(replace(var.name_prefix, "-", " ")), " ", "")}App"
  user_pool_id = aws_cognito_user_pool.this.id

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
  supported_identity_providers = ["COGNITO"]

  callback_urls                        = var.cognito_callback_urls
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "phone"]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 5

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true
  auth_session_validity         = 3
}

resource "aws_cognito_identity_pool" "this" {
  identity_pool_name               = "cognito-identity-pool-vm"
  allow_unauthenticated_identities = false
  allow_classic_flow               = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.this.id
    provider_name           = aws_cognito_user_pool.this.endpoint
    server_side_token_check = false
  }
}

data "aws_iam_policy_document" "cognito_authenticated_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.this.id]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["authenticated"]
    }
  }
}

resource "aws_iam_role" "cognito_authenticated" {
  name               = "cognito-identity-pool-iam-role"
  assume_role_policy = data.aws_iam_policy_document.cognito_authenticated_assume.json
}

data "aws_iam_policy_document" "cognito_authenticated" {
  statement {
    effect    = "Allow"
    actions   = ["cognito-identity:GetCredentialsForIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cognito_authenticated" {
  name   = "Cognito-authenticated-${var.name_prefix}"
  policy = data.aws_iam_policy_document.cognito_authenticated.json
}

resource "aws_iam_role_policy_attachment" "cognito_authenticated" {
  role       = aws_iam_role.cognito_authenticated.name
  policy_arn = aws_iam_policy.cognito_authenticated.arn
}

data "aws_iam_policy_document" "cognito_authenticated_runtime_access" {
  statement {
    sid     = "InvokeAgentCoreRuntime"
    effect  = "Allow"
    actions = ["bedrock-agentcore:InvokeAgentRuntime"]
    resources = [
      aws_bedrockagentcore_agent_runtime.this.agent_runtime_arn,
      "${aws_bedrockagentcore_agent_runtime.this.agent_runtime_arn}/runtime-endpoint/DEFAULT",
    ]
  }
}

resource "aws_iam_role_policy" "cognito_authenticated_runtime_access" {
  name   = "AgentCoreRuntimeAccess"
  role   = aws_iam_role.cognito_authenticated.id
  policy = data.aws_iam_policy_document.cognito_authenticated_runtime_access.json
}

resource "aws_cognito_identity_pool_roles_attachment" "this" {
  identity_pool_id = aws_cognito_identity_pool.this.id

  roles = {
    authenticated = aws_iam_role.cognito_authenticated.arn
  }
}
