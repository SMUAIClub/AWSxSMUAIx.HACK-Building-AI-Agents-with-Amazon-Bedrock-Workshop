# Module 7's Amplify app was deployed via "Deploy without Git" (drag-and-drop
# zip), which has no Terraform-native equivalent — aws_amplify_app only models
# the app/branch shell, not a one-off zip upload. This resource reproduces
# that shell (name, SPA rewrite rule, single production branch); the actual
# bundle upload is handled by null_resource.deploy_frontend below, via the
# same create-deployment/upload/start-deployment flow the console uses under
# the hood.
resource "aws_amplify_app" "frontend" {
  name     = "${var.name_prefix}-frontend"
  platform = "WEB"

  custom_rule {
    source = "/<*>"
    target = "/index.html"
    status = "404-200"
  }
}

resource "aws_amplify_branch" "staging" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = "staging"
  stage       = "PRODUCTION"
}

locals {
  frontend_asset_files = fileset("${path.module}/../frontend/assets", "**")
}

resource "null_resource" "deploy_frontend" {
  triggers = {
    index_html_hash = filesha256("${path.module}/../frontend/index.html")
    assets_hash = sha256(join("", [
      for f in local.frontend_asset_files : filesha256("${path.module}/../frontend/assets/${f}")
    ]))
  }

  provisioner "local-exec" {
    command = "${path.module}/../frontend/deploy.sh ${aws_amplify_app.frontend.id} ${aws_amplify_branch.staging.branch_name}"
  }

  depends_on = [aws_amplify_branch.staging]
}
