variable "name" {
  type = string
}
variable "region" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "app_sg_id" {
  type = string
}
variable "target_group_arn" {
  type = string
}
variable "ecr_repository_url" {
  type = string
}
variable "ecr_repository_arn" {
  type = string
}
variable "secret_arn" {
  type = string
}
variable "alb_dns_name" {
  type = string
}
variable "app_port" {
  type = number
}
variable "instance_type" {
  type = string
}
variable "image_tag" {
  type    = string
  default = "latest"
}
variable "min_size" {
  type    = number
  default = 1
}
variable "max_size" {
  type    = number
  default = 3
}
variable "desired_size" {
  type    = number
  default = 2
}
variable "image_tag_parameter_name" {
  type = string
}
variable "image_tag_parameter_arn" {
  type = string
}
