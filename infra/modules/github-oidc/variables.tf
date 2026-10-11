variable "name" {
  type = string
}   
variable "github_repo" {
  type = string
}   
variable "state_bucket" {
  type = string
}
variable "ecr_repository_arn" {
  type = string
}   
variable "asg_name" {
  type = string
}
variable "image_tag_parameter_arn" {
  type = string
}
variable "db_secret_arn" {
  type = string
}