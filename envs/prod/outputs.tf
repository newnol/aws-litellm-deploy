output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "ec2_public_ip" {
  description = "EC2 Elastic IP (static public IP)"
  value       = module.ec2.elastic_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "dsql_endpoint" {
  description = "Aurora dSQL cluster endpoint"
  value       = module.dsql.cluster_endpoint
}

output "dsql_cluster_arn" {
  description = "Aurora dSQL cluster ARN"
  value       = module.dsql.cluster_arn
}

output "litellm_url" {
  description = "LiteLLM Proxy URL"
  value       = "http://${module.ec2.elastic_ip}:4000"
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.ec2.elastic_ip}"
}

output "deploy_commands" {
  description = "Quick deploy commands"
  value       = <<-EOT
    1. SSH into instance:
       ssh -i ${var.key_name}.pem ec2-user@${module.ec2.elastic_ip}

    2. Check LiteLLM status:
       docker compose -f /opt/litellm/docker-compose.yml ps

    3. View logs:
       docker compose -f /opt/litellm/docker-compose.yml logs -f

    4. Restart LiteLLM:
       docker compose -f /opt/litellm/docker-compose.yml restart

    5. Access LiteLLM:
       http://${module.ec2.elastic_ip}:4000
  EOT
}
