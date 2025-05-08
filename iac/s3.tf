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

resource "aws_s3_bucket_policy" "site_policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

