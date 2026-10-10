output "ecr_repository_url" {
  value = module.ecr.repository_url
}
output "db_endpoint" {
  value = module.rds.endpoint
}
output "db_secret_arn" {
  value = module.rds.secret_arn
}
output "app_sg_id" {
  value = aws_security_group.app.id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}
output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
output "alb_dns_name" {
  value = module.alb.dns_name
}
output "asg_name" {
  value = module.asg.asg_name
}