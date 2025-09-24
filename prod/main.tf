provider "aws" {
  region = var.region
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "${var.lambda_name}_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach basic execution policy so Lambda can write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Zip the Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# Lambda function
resource "aws_lambda_function" "test_lambda" {
  function_name = var.lambda_name
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  handler = "lambda_function.lambda_handler"
  runtime = "python3.9"
  role    = aws_iam_role.lambda_exec.arn
}

# Output Lambda ARN
output "lambda_arn" {
  value = aws_lambda_function.test_lambda.arn
}
