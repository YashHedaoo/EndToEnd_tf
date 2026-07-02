terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "ecs-oneagent/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
