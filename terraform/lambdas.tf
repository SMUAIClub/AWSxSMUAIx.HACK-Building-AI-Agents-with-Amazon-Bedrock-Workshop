locals {
  lambda_tools = {
    geo_coordinates = {
      source_dir  = "${path.module}/../lambdas/geo_coordinates"
      description = "Geocoding tool that converts city or place names into latitude and longitude coordinates"
    }
    weather_forecast = {
      source_dir  = "${path.module}/../lambdas/weather_forecast"
      description = "Weather forecast tool that returns current conditions, hourly, and daily forecasts using coordinates"
    }
    date_time = {
      source_dir  = "${path.module}/../lambdas/date_time"
      description = "Returns the current date and time for a given IANA timezone"
    }
  }
}

data "archive_file" "lambda_tool" {
  for_each = local.lambda_tools

  type        = "zip"
  source_dir  = each.value.source_dir
  output_path = "${path.module}/.build/${each.key}.zip"
}

resource "aws_iam_role" "lambda_tool" {
  for_each = local.lambda_tools

  name               = "${replace(each.key, "_", "-")}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_tool_basic_execution" {
  for_each = local.lambda_tools

  role       = aws_iam_role.lambda_tool[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "tool" {
  for_each = local.lambda_tools

  function_name    = each.key
  description      = each.value.description
  role             = aws_iam_role.lambda_tool[each.key].arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  architectures    = ["x86_64"]
  timeout          = 3
  memory_size      = 128
  filename         = data.archive_file.lambda_tool[each.key].output_path
  source_code_hash = data.archive_file.lambda_tool[each.key].output_base64sha256
}
