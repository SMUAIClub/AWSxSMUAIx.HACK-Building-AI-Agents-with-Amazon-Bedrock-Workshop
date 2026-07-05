resource "aws_iam_role" "gateway" {
  name               = "VirtualMeteorologistGatewayRole"
  assume_role_policy = data.aws_iam_policy_document.bedrock_agentcore_assume.json
}

data "aws_iam_policy_document" "gateway" {
  statement {
    sid       = "GetGateway"
    effect    = "Allow"
    actions   = ["bedrock-agentcore:GetGateway"]
    resources = ["arn:aws:bedrock-agentcore:${var.aws_region}:${data.aws_caller_identity.current.account_id}:gateway/${var.name_prefix}-gateway*"]
  }

  statement {
    sid       = "LambdaInvoke"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [for fn in aws_lambda_function.tool : fn.arn]
  }
}

resource "aws_iam_policy" "gateway" {
  name   = "VirtualMeteorologistGatewayPolicy"
  policy = data.aws_iam_policy_document.gateway.json
}

resource "aws_iam_role_policy_attachment" "gateway" {
  role       = aws_iam_role.gateway.name
  policy_arn = aws_iam_policy.gateway.arn
}

resource "aws_bedrockagentcore_gateway" "this" {
  name            = "${var.name_prefix}-gateway"
  role_arn        = aws_iam_role.gateway.arn
  authorizer_type = "AWS_IAM"
  protocol_type   = "MCP"
  exception_level = "DEBUG"

  protocol_configuration {
    mcp {
      supported_versions = ["2025-03-26"]
    }
  }
}
