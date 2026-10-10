variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_engine_version" {
  type = string
}

variable "app_port" {
  type = number
}

variable "instance_type" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}
