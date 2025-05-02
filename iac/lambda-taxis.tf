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

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" { //Politica para crear la vpc
    role       = aws_iam_role.lambda_taxis_exec_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
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
      DB_HOST     = "db-taxis-viajes-usuarios.cbmia0266pjz.us-east-2.rds.amazonaws.com" //endpoint
      DB_USER     = "IACgrupo7" //master username
      DB_PASSWORD = "grupo7_rds" //password
      DB_NAME     = "db-taxis-viajes-usuarios"
    }
  }

  vpc_config {
    subnet_ids         = [
                          data.aws_subnet.public1-us-east-2a.id, //Solo 2 subnets
                          data.aws_subnet.public2-us-east-2b.id
                          ]
    security_group_ids = [data.aws_security_group.lambda_sg.id]
  }
  
}

data "aws_subnet" "public1-us-east-2a" {
  id = "subnet-0f3b032d13c823454"
}

data "aws_subnet" "public2-us-east-2b" {
  id = "subnet-0a9a32b0b128ed6c3"
}

data "aws_subnet" "private1-us-east-2a" {
  id = "subnet-0ca0a62770356adba"
}

data "aws_subnet" "private2-us-east-2b" {
  id = "subnet-09b3130da42f77519"
}

data "aws_security_group" "lambda_sg" {
  id = "sg-01a5fdf9b8fe18508"
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
