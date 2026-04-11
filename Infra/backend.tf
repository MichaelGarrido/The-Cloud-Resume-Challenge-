terraform {
  backend "s3" {
    bucket         = "michael-terraform-state-12345"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
