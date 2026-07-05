resource "aws_iam_role" "runtime" {
  name               = "VirtualMeteorologistRuntimeRole"
  assume_role_policy = data.aws_iam_policy_document.bedrock_agentcore_assume.json
}

data "aws_iam_policy_document" "runtime" {
  # bedrock:Converse / bedrock:ConverseStream do not exist as IAM actions and
  # will cause policy creation to be rejected if included — confirmed both by
  # what's actually deployed in this account and by a documented corrections
  # pass over the official guide (which still lists them by mistake).
  statement {
    sid    = "BedrockModelAccess"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    resources = [
      "arn:aws:bedrock:*::foundation-model/amazon.nova-2-lite-v1:0",
      "arn:aws:bedrock:*:*:inference-profile/us.amazon.nova-2-lite-v1:0",
    ]
  }

  statement {
    sid    = "GatewayAccess"
    effect = "Allow"
    actions = [
      "bedrock-agentcore:InvokeGateway",
      "bedrock-agentcore:GetGateway",
      "bedrock-agentcore:ListGatewayTargets",
    ]
    resources = [aws_bedrockagentcore_gateway.this.gateway_arn]
  }

  statement {
    sid    = "MemoryAccess"
    effect = "Allow"
    actions = [
      "bedrock-agentcore:CreateEvent",
      "bedrock-agentcore:ListEvents",
      "bedrock-agentcore:GetMemory",
      "bedrock-agentcore:DeleteEvent",
    ]
    resources = [aws_bedrockagentcore_memory.this.arn]
  }

  statement {
    sid    = "S3CodeAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = ["${aws_s3_bucket.agent_runtime_code.arn}/*"]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:*:log-group:/aws/bedrock-agentcore/runtimes/${replace(var.name_prefix, "-", "_")}*"]
  }
}

resource "aws_iam_policy" "runtime" {
  name   = "VirtualMeteorologistRuntimePolicy"
  policy = data.aws_iam_policy_document.runtime.json
}

resource "aws_iam_role_policy_attachment" "runtime" {
  role       = aws_iam_role.runtime.name
  policy_arn = aws_iam_policy.runtime.arn
}

resource "aws_bedrockagentcore_agent_runtime" "this" {
  agent_runtime_name = replace(var.name_prefix, "-", "_")
  role_arn           = aws_iam_role.runtime.arn

  agent_runtime_artifact {
    code_configuration {
      entry_point = ["main.py"]
      runtime     = "PYTHON_3_13"

      code {
        s3 {
          bucket = aws_s3_bucket.agent_runtime_code.bucket
          prefix = aws_s3_object.agent_runtime_code.key
        }
      }
    }
  }

  network_configuration {
    network_mode = "PUBLIC"
  }

  protocol_configuration {
    server_protocol = "HTTP"
  }

  lifecycle_configuration {
    idle_runtime_session_timeout = 900
    max_lifetime                 = 28800
  }

  environment_variables = {
    AWS_REGION  = var.aws_region
    GATEWAY_ARN = aws_bedrockagentcore_gateway.this.gateway_arn
    MEMORY_ID   = aws_bedrockagentcore_memory.this.id
    MODEL_ID    = var.model_id
  }
}
