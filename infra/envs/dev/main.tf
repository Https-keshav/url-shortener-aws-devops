locals {
  name = "url-shortener-dev"
}

module "vpc" {
  source               = "../../modules/vpc"
  name                 = "url-shortener-dev"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
}



resource "aws_security_group" "app" {
  name        = "${local.name}-app-sg"
  description = "App instances (ingress from ALB added in Phase 3)"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # needed to reach ECR, Secrets Manager, SSM
  }
}

module "ecr" {
  source = "../../modules/ecr"
  name   = local.name
}

module "rds" {
  source = "../../modules/rds"

  name               = local.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  allowed_sg_ids     = [aws_security_group.app.id]
  db_name            = var.db_name
  db_username        = var.db_username
  instance_class     = var.db_instance_class
  engine_version     = var.db_engine_version
}

module "alb" {
  source            = "../../modules/alb"
  name              = local.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  target_port       = var.app_port
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  description                  = "App traffic from alb"
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = module.alb.sg_id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

module "asg" {
  source = "../../modules/asg"

  name               = local.name
  region             = var.region
  public_subnet_ids  = module.vpc.public_subnet_ids
  app_sg_id          = aws_security_group.app.id
  target_group_arn   = module.alb.target_group_arn
  ecr_repository_url = module.ecr.repository_url
  ecr_repository_arn = module.ecr.repository_arn
  secret_arn         = module.rds.secret_arn
  alb_dns_name       = module.alb.dns_name
  app_port           = var.app_port
  instance_type      = var.instance_type
}
