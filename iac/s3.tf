resource "aws_s3_bucket" "bucket" {
    bucket = "taxis-bucket"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.usuarios.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "usuarios/"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.taxis.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "taxis/"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.viajes.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "viajes/"
  }

  depends_on = [
    aws_lambda_permission.allow_s3_usuarios,
    aws_lambda_permission.allow_s3,
    aws_lambda_permission.allow_s3_viajes
  ]
}
