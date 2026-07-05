terraform {
  backend "s3" {
    bucket         = "yash-ecs-oneagent-tfstate"
    key            = "ecs-oneagent/terraform.tfstate"
    region         = "ap-south-2"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
