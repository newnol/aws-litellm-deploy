################################################################################
# IAM Module — EC2 instance role (CloudWatch, dSQL)
################################################################################

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# EC2 Role
resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-${var.environment}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# SSM policy (for remote management)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# dSQL connect policy
data "aws_iam_policy_document" "dsql_connect" {
  statement {
    actions = ["dsql:Connect"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "dsql_connect" {
  name        = "${var.project_name}-${var.environment}-dsql-connect"
  description = "Allow connecting to Aurora dSQL"
  policy      = data.aws_iam_policy_document.dsql_connect.json
}

resource "aws_iam_role_policy_attachment" "dsql_connect" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.dsql_connect.arn
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}
