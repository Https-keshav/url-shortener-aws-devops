terraform {
  backend "s3" {
    bucket       = "kt-urlshortener-tfstate-027"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}