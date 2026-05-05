################################################################################
# Aurora dSQL Module — Serverless PostgreSQL
################################################################################

resource "aws_dsql_cluster" "this" {
  cluster_identifier = var.cluster_identifier

  tags = {
    Name        = "${var.project_name}-${var.environment}-dsql"
    Project     = var.project_name
    Environment = var.environment
  }
}
