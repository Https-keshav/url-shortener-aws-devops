variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_sg_ids" {
  description = "Security groups allowed to connect on port 5432"
  type        = list(string)
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "allocated_storage" {
  type    = number
  default = 20
}