// Lambda function for order processing (Part III)
// This Lambda function subscribes directly to SNS, eliminating the need for SQS and ECS workers

resource "aws_lambda_function" "order_processor_lambda" {
  filename         = "${path.module}/../lambda/lambda.zip"
  function_name    = "order-processor-lambda"
  role            = var.lambda_execution_role_arn
  handler         = "bootstrap"  // Go custom runtime uses "bootstrap" as handler
  runtime         = "provided.al2"  // Go custom runtime
  memory_size     = 512
  timeout         = 10  // 10 seconds (3s processing + buffer)

  source_code_hash = filebase64sha256("${path.module}/../lambda/lambda.zip")

  environment {
    variables = {
      PAYMENT_SIM_SECONDS = "3"
    }
  }

  tags = {
    project = "ordersync"
    env     = "dev"
    part    = "III"
  }
}

// Allow SNS to invoke Lambda
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_processor_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.order_events.arn
}

// Subscribe Lambda to SNS topic
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.order_events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.order_processor_lambda.arn
}

// CloudWatch Log Group for Lambda (retention: 7 days)
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.order_processor_lambda.function_name}"
  retention_in_days = 7

  tags = {
    project = "ordersync"
    env     = "dev"
  }
}
