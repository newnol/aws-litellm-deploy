# =============================================================================
# Aurora dSQL Module
# =============================================================================

resource "aws_dsql_cluster" "this" {
  cluster_identifier = "${var.project_name}-dsql"
  engine             = "aurora-dsql"

  tags = {
    Name = "${var.project_name}-dsql"
  }
}

# Get auth token for IAM-based authentication
data "aws_dsql_token" "this" {
  cluster_identifier = aws_dsql_cluster.this.cluster_identifier
  region             = data.aws_region.current.name
}

data "aws_region" "current" {}
