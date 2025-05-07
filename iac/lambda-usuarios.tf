data "archive_file" "lambda_usuarios" {
  type        = "zip"
  source_dir  = "${path.module}/../usuarios"
  output_path = "${path.module}/bin/usuarios.zip"
}

resource "aws_iam_role" "lambda_usuarios_exec_role" { //Rol Necesario para ejecutar el recurso lambda
  name = "usuarios_exec_role"
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

resource "aws_iam_policy" "lambda_policy_usuarios" {
  name = "usuarios_policy"
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

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_usuarios" { //Vincula el rol con el policy para generar logs
  role       = aws_iam_role.lambda_usuarios_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy_usuarios.arn
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole_usuarios" { //Politica para almacenar la funcion en la vpc
    role       = aws_iam_role.lambda_usuarios_exec_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "usuarios" {
  function_name    = "usuarios"
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  role             = aws_iam_role.lambda_usuarios_exec_role.arn // El arn es el ID para conectar el rol con el recurso
  filename         = data.archive_file.lambda_usuarios.output_path
  source_code_hash = data.archive_file.lambda_usuarios.output_base64sha512

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
                          data.aws_subnet.public1-us-east-2a.id, //Definir a que subnet ira la lambda
                          data.aws_subnet.public2-us-east-2b.id
                          ]
    security_group_ids = [data.aws_security_group.lambda_sg.id] //Definir el security group
  }
  
}

resource "aws_lambda_permission" "allow_s3_usuarios" { //Permiso para que el s3 pueda invocar el lambda
  statement_id  = "AllowS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.usuarios.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}