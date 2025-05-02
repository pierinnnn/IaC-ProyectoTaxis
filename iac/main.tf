terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" { //Keys del ROOT
    region = "us-east-2"
    access_key = ""
    secret_key = ""
}
// En la terminal keys del iam (temporales)

