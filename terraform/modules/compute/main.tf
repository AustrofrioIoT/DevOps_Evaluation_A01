# Lambda & API Gateway

# SG Lambda
resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-lambda-sg"
  description = "Security group para la funcion Lambda"
  vpc_id      = var.vpc_id

  # Egress allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-lambda-sg"
  }
}

# IAM Role Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role"

  # Trust Policy: Permite que el servicio Lambda asuma este rol.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# VPC Access Policy
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# SSM Access Policy
resource "aws_iam_role_policy_attachment" "lambda_ssm" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# Lambda Function
resource "aws_lambda_function" "app" {
  function_name = "${var.project_name}-api"
  handler       = "src/index.handler" # Archivo donde está el código y nombre de la función exportada
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  # Archivo comprimido con el código y dependencias.
  filename         = "${path.root}/lambda_payload.zip"
  source_code_hash = filebase64sha256("${path.root}/lambda_payload.zip")

  # VPC Config
  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # Envs
  environment {
    variables = {
      NODE_ENV     = "production"
      PROJECT_NAME = var.project_name
      DB_HOST      = var.db_host
      DB_PASSWORD  = var.db_password
    }
  }

  tags = {
    Name = "${var.project_name}-lambda"
  }
}

# API Gateway (HTTP)
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"
}

# Stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

# Integration Lambda
resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  integration_uri        = aws_lambda_function.app.invoke_arn
  payload_format_version = "2.0"
}

# Proxy Route
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Lambda Invoke Permission
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

output "lambda_sg_id" {
  value = aws_security_group.lambda_sg.id
}

output "api_url" {
  value = aws_apigatewayv2_api.main.api_endpoint
}
