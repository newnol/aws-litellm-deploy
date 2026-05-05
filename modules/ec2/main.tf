# =============================================================================
# EC2 Module
# =============================================================================

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance
resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.instance_profile_name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    dsql_endpoint      = var.dsql_endpoint
    litellm_master_key = var.litellm_master_key
  }))

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-ec2"
  }
}
