# Latest Amazon Linux 2023 AMI, looked up from AWS's public SSM parameter
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ---------- IAM ----------
resource "aws_iam_role" "instance" {
  name = "${var.name}-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Lets you open a shell with SSM Session Manager instead of SSH
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "app" {
  name = "${var.name}-app-access"
  role = aws_iam_role.instance.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "EcrPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = var.ecr_repository_arn
      },
      {
        Sid      = "ReadDbSecret"
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = var.secret_arn
      },
      {
        Sid      = "ReadImageTag"
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = var.image_tag_parameter_arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.instance.name
}

# ---------- Launch template ----------
resource "aws_launch_template" "this" {
  name_prefix            = "${var.name}-lt-"
  image_id               = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.app_sg_id]
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 only
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    region              = var.region
    secret_arn          = var.secret_arn
    registry            = split("/", var.ecr_repository_url)[0]
    image               = "${var.ecr_repository_url}:${var.image_tag}"
    app_port            = var.app_port
    base_url            = "http://${var.alb_dns_name}"
    ecr_repository_url  = var.ecr_repository_url
    image_tag_parameter = var.image_tag_parameter_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.name}-app" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------- Auto Scaling Group ----------
resource "aws_autoscaling_group" "this" {
  name                      = "${var.name}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_size
  vpc_zone_identifier       = var.public_subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      auto_rollback          = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-app"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60
  }
}

