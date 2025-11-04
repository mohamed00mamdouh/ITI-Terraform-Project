terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket-unique" # change
    key     = "projects/secure-webapp/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
  required_version = ">= 1.0"
}
