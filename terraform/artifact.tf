resource "random_id" "code_bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "agent_runtime_code" {
  bucket = "bedrock-agentcore-runtime-${data.aws_caller_identity.current.account_id}-${var.aws_region}-${random_id.code_bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "agent_runtime_code" {
  bucket = aws_s3_bucket.agent_runtime_code.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "agent_runtime_code" {
  bucket = aws_s3_bucket.agent_runtime_code.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "agent_runtime_code" {
  bucket = aws_s3_bucket.agent_runtime_code.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Builds main.py + pinned dependencies (as ARM64 wheels, matching what
# AgentCore Runtime executes on) into a deployable zip. Requires `pip` and
# `zip` on the machine running `terraform apply`.
resource "null_resource" "build_agent_runtime" {
  triggers = {
    main_py_hash      = filesha256("${path.module}/../agent/main.py")
    requirements_hash = filesha256("${path.module}/../agent/requirements.txt")
    build_script_hash = filesha256("${path.module}/../agent/build.sh")
  }

  provisioner "local-exec" {
    command = "${path.module}/../agent/build.sh"
  }
}

resource "aws_s3_object" "agent_runtime_code" {
  bucket = aws_s3_bucket.agent_runtime_code.id
  key    = "agent-runtime.zip"
  source = "${path.module}/../agent/.build/agent-runtime.zip"

  # Derived from the build inputs rather than filemd5() on the built zip:
  # the zip doesn't exist yet on a first `terraform apply`, and filemd5()
  # is evaluated at plan time, before the null_resource has run.
  etag = sha256(join("", values(null_resource.build_agent_runtime.triggers)))

  depends_on = [null_resource.build_agent_runtime]
}
