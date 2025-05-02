data "archive_file" "lambda_taxis" {
  type        = "zip"
  source_dir  = "${path.module}/../taxis"
  output_path = "${path.module}/bin/taxis.zip"
}

resource "aws_iam_role" "lambda_taxis_exec_role" { //Rol Necesario para ejecutar el recurso lambda
  name = "taxis_exec_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "taxis_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" { //Vincula el rol con el policy para generar logs
  role       = aws_iam_role.lambda_taxis_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "taxis" {
  function_name    = "taxis"
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  role             = aws_iam_role.lambda_taxis_exec_role.arn // El arn es el ID para conectar el rol con el recurso
  filename         = data.archive_file.lambda_taxis.output_path
  source_code_hash = data.archive_file.lambda_taxis.output_base64sha512

  environment {
    variables = {
      HELLO = "WORLD"
    }
  }
}

resource "aws_lambda_permission" "allow_s3" { //Permiso para que el s3 pueda invocar el lambda
  statement_id  = "AllowS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.taxis.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.taxis.arn
    events              = ["s3:ObjectCreated:*"] //Se activa cuando un usuario solicita un taxi
  }

  //Garantizar que primero llame a un recurso antes de ejecutar este codigo
  depends_on = [aws_lambda_permission.allow_s3]
}
