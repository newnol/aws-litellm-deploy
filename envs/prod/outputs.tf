output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_url" {
  description = "Application URL via ALB"
  value       = module.alb.alb_url
}

output "alb_dns_name" {
  description = "ALB DNS name (for Cloudflare CNAME)"
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL (push Docker images here)"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}

output "db_credentials_secret_arn" {
  description = "Secrets Manager ARN for DB credentials"
  value       = module.secrets.db_credentials_secret_arn
}

output "api_keys_secret_arn" {
  description = "Secrets Manager ARN for API keys (fill in Console)"
  value       = module.secrets.api_keys_secret_arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS"
  value       = module.ecs.log_group_name
}

output "deploy_commands" {
  description = "Quick deploy commands"
  value       = <<-EOT
    
    1. Push image to ECR:
       aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.ecr.repository_url}
       docker build -t ${module.ecr.repository_url}:latest .
       docker push ${module.ecr.repository_url}:latest

    2. Force new deployment:
       aws ecs update-service --cluster ${module.ecs.cluster_name} --service ${module.ecs.service_name} --force-new-deployment

    3. View logs:
       aws logs tail ${module.ecs.log_group_name} --follow

    4. Set API key in Secrets Manager:
       Go to AWS Console → Secrets Manager → ${module.secrets.api_keys_secret_arn}
  EOT
}
