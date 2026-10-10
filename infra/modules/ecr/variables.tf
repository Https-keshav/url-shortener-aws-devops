variable "name" {
  description = "Repository name"
  type        = string
}

variable "keep_last_images" {
  description = "How many images to keep before old ones expire"
  type        = number
  default     = 10
}