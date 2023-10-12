# This module was created using terraform 0.11.4 at 2018/03/21.
# This module was updated to terraform 0.13.7 on 2021/09/21.

# Contains local values that are used to increase DRYness of the code.
locals {
  common_tags = merge(
    var.additional_tags,
    {
      "ProductDomain" = var.product_domain
    },
    {
      "Environment" = var.environment
    },
    {
      "ManagedBy" = "terraform"
    },
  )
}

# Get the access to the effective Account ID, User ID, and ARN in which Terraform is authorized.
data "aws_caller_identity" "current" {}

# Provides details about a specific AWS region.
data "aws_region" "current" {}

# Provides a VPC resource.
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = var.vpc_enable_dns_support
  enable_dns_hostnames = var.vpc_enable_dns_hostnames

  tags = merge(
    var.additional_vpc_tags,
    local.common_tags,
    {
      "Name" = var.vpc_name
    },
    {
      "MultiTier" = var.vpc_multi_tier ? "true" : "false"
    },
    {
      "Description" = format(
        "%s VPC for %s product domain",
        var.environment,
        var.product_domain,
      )
    },
  )
}

# Provides VPC public subnet resources (DMZ).
# One for each AZ.
resource "aws_subnet" "public" {
  count = length(var.subnet_availability_zones)

  availability_zone       = element(var.subnet_availability_zones, count.index)
  cidr_block              = cidrsubnet(var.vpc_cidr_block, "4", count.index)
  map_public_ip_on_launch = "true"
  vpc_id                  = aws_vpc.this.id

  tags = merge(
    var.additional_public_subnet_tags,
    local.common_tags,
    {
      "Name" = format(
        "%s-public-%s",
        var.vpc_name,
        substr(element(var.subnet_availability_zones, count.index), -1, 1),
      )
    },
    {
      "Tier" = "public"
    },
    {
      "Description" = format(
        "Public subnet for %s AZ on %s VPC",
        element(var.subnet_availability_zones, count.index),
        var.vpc_name,
      )
    },
  )
}

# Provides VPC app subnet resources (Private).
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_subnet" "app" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  availability_zone = element(var.subnet_availability_zones, count.index)
  cidr_block        = cidrsubnet(var.vpc_cidr_block, "3", count.index + "4")
  vpc_id            = aws_vpc.this.id

  tags = merge(
    var.additional_app_subnet_tags,
    local.common_tags,
    {
      "Name" = format(
        "%s-app-%s",
        var.vpc_name,
        substr(element(var.subnet_availability_zones, count.index), -1, 1),
      )
    },
    {
      "Tier" = "app"
    },
    {
      "Description" = format(
        "Application subnet for %s AZ on %s VPC",
        element(var.subnet_availability_zones, count.index),
        var.vpc_name,
      )
    },
  )
}

# Provides VPC data subnet resources (Private).
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_subnet" "data" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  availability_zone = element(var.subnet_availability_zones, count.index)
  cidr_block        = cidrsubnet(var.vpc_cidr_block, "4", count.index + "4")
  vpc_id            = aws_vpc.this.id

  tags = merge(
    var.additional_data_subnet_tags,
    local.common_tags,
    {
      "Name" = format(
        "%s-data-%s",
        var.vpc_name,
        substr(element(var.subnet_availability_zones, count.index), -1, 1),
      )
    },
    {
      "Tier" = "data"
    },
    {
      "Description" = format(
        "Data subnet for %s AZ on %s VPC",
        element(var.subnet_availability_zones, count.index),
        var.vpc_name,
      )
    },
  )
}

# Provides Network ACL for data subnet (Private).
# Only created when the VPC is multi-tier.
resource "aws_network_acl" "data_acl" {
  count = var.enable_data_subnet_network_acl_ingress == true ? (var.vpc_multi_tier ? "1" : "0") : "0"

  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.data.*.id
  tags = merge(
    local.common_tags,
    {
      "Name" = format("%s-data-acl", var.vpc_name)
    },
    {
      "Description" = format("Network ACL for data subnet in %s VPC", var.vpc_name)
    },
  )
}

# Allow ingress from app subnet and data subnet CIDRs
resource "aws_network_acl_rule" "data_acl_ingress" {
  count = var.enable_data_subnet_network_acl_ingress == true ? (var.vpc_multi_tier ? length(var.subnet_availability_zones) * 2 : "0") : "0"

  network_acl_id = aws_network_acl.data_acl[0].id
  rule_number    = 100 + count.index
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = element(concat(aws_subnet.app.*.cidr_block, aws_subnet.data.*.cidr_block), count.index)
  from_port      = "0"
  to_port        = "0"
}

resource "aws_network_acl_rule" "data_acl_additional_ingress" {
  count = var.enable_data_subnet_network_acl_ingress == true ? (var.vpc_multi_tier ? length(var.additional_data_subnet_network_acl_ingress) : "0") : "0"

  network_acl_id = aws_network_acl.data_acl[0].id
  rule_number    = 100 + length(var.subnet_availability_zones) * 2 + count.index
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = element(var.additional_data_subnet_network_acl_ingress, count.index)
  from_port      = "0"
  to_port        = "0"
}

resource "aws_network_acl_rule" "data_acl_egress" {
  count = var.enable_data_subnet_network_acl_ingress == true ? (var.vpc_multi_tier ? "1" : "0") : "0"

  network_acl_id = aws_network_acl.data_acl[0].id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "0"
  to_port        = "0"
}

# Provides an RDS DB subnet group resource.
# Only created when the VPC is multi-tier.
resource "aws_db_subnet_group" "this" {
  count = var.vpc_multi_tier ? "1" : "0"

  name        = "${var.vpc_name}-default-db-subnet-group"
  description = "Default DB Subnet Group on ${var.vpc_name} VPC"
  subnet_ids  = aws_subnet.data.*.id # For terraform 0.12 this line should be changed to aws_subnet.data[*].id

  tags = merge(
    local.common_tags,
    {
      "Name" = format("%s-default-db-subnet-group", var.vpc_name)
    },
    {
      "Tier" = "data"
    },
    {
      "Description" = format("Default DB Subnet Group on %s VPC", var.vpc_name)
    },
  )
}

# Provides an ElastiCache Subnet Group resource.
# Only created when the VPC is multi-tier.
resource "aws_elasticache_subnet_group" "this" {
  count = var.vpc_multi_tier ? "1" : "0"

  name        = "${var.vpc_name}-default-elasticache-subnet-group"
  description = "Default Elasticache Subnet Group on ${var.vpc_name} VPC"
  subnet_ids  = aws_subnet.data.*.id # For terraform 0.12 this line should be changed to aws_subnet.data[*].id
}

# Creates a new Amazon Redshift subnet group.
# Only created when the VPC is multi-tier.
resource "aws_redshift_subnet_group" "this" {
  count = var.vpc_multi_tier ? "1" : "0"

  name        = "${var.vpc_name}-default-redshift-subnet-group"
  description = "Default Redshift Subnet Group on ${var.vpc_name} VPC"
  subnet_ids  = aws_subnet.data.*.id # For terraform 0.12 this line should be changed to aws_subnet.data[*].id

  tags = merge(
    local.common_tags,
    {
      "Name" = format("%s-default-redshift-subnet-group", var.vpc_name)
    },
    {
      "Tier" = "data"
    },
    {
      "Description" = format("Default Redshift Subnet Group on %s VPC", var.vpc_name)
    },
  )
}

# Provides a VPC Internet Gateway resource.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      "Name" = format("%s-igw", var.vpc_name)
    },
    {
      "Description" = format("Internet gateway for %s VPC", var.vpc_name)
    },
  )
}

# Provides Elastic IP resources for NAT Gateways.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_eip" "nat" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  vpc = "true"

  tags = merge(
    local.common_tags,
    {
      "Name" = format(
        "%s-eipalloc-%s",
        var.vpc_name,
        substr(element(var.subnet_availability_zones, count.index), -1, 1),
      )
    },
    {
      "Description" = format(
        "NAT Gateway's Elastic IP for %s AZ on %s VPC",
        element(var.subnet_availability_zones, count.index),
        var.vpc_name,
      )
    },
  )
}

# Provides VPC NAT Gateway resources.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_nat_gateway" "this" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  depends_on    = [aws_internet_gateway.this]

  lifecycle {
    ignore_changes = [id]
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = format(
        "%s-nat-%s",
        var.vpc_name,
        substr(element(var.subnet_availability_zones, count.index), -1, 1),
      )
    },
    {
      "Description" = format(
        "NAT Gateway for %s AZ on %s VPC",
        element(var.subnet_availability_zones, count.index),
        var.vpc_name,
      )
    },
  )
}

# Provides a resource to manage a Default VPC Routing Table.
resource "aws_default_route_table" "this" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  tags = merge(
    local.common_tags,
    {
      "Name" = format("%s-default-rtb", var.vpc_name)
    },
    {
      "Tier" = "default"
    },
    {
      "Description" = format("Default route table for %s VPC", var.vpc_name)
    },
  )
}

# Provides a VPC routing table for public subnets.
# One is enough, we only have one IGW anyway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      "Name" = format("%s-public-rtb", var.vpc_name)
    },
    {
      "Tier" = "public"
    },
    {
      "Description" = format("Route table for public subnet on %s VPC", var.vpc_name)
    },
  )
}

# Provides a routing table entry (a route) in a VPC routing table for public subnets.
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Provides resources that each create an association between a public subnet and a routing table.
# One for each AZ.
resource "aws_route_table_association" "public" {
  count = length(var.subnet_availability_zones)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id

  lifecycle {
    ignore_changes = [id]
  }
}

# Provides VPC routing tables for app subnets.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_route_table" "app" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      "Name" = format(
        "%s-app-rtb-%s",
        var.vpc_name,
        substr(element(var.subnet_availability_zones, count.index), -1, 1),
      )
    },
    {
      "Tier" = "app"
    },
    {
      "Description" = format(
        "Route table for app subnet in %s AZ of %s VPC",
        element(var.subnet_availability_zones, count.index),
        var.vpc_name,
      )
    },
  )
}

# Provides routing table entries (routes) in VPC routing tables for app subnets.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_route" "app" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  route_table_id         = element(aws_route_table.app.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)
}

# Provides resources that each create an association between an app subnet and a routing table.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_route_table_association" "app" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  subnet_id      = element(aws_subnet.app.*.id, count.index)
  route_table_id = element(aws_route_table.app.*.id, count.index)

  lifecycle {
    ignore_changes = [id]
  }
}

# Provides VPC routing tables for data subnets.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_route_table" "data" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      "Name" = format(
        "%s-data-rtb-%s",
        var.vpc_name,
        substr(element(var.subnet_availability_zones, count.index), -1, 1),
      )
    },
    {
      "Tier" = "data"
    },
    {
      "Description" = format(
        "Route table for data subnet in %s AZ of %s VPC",
        element(var.subnet_availability_zones, count.index),
        var.vpc_name,
      )
    },
  )
}

# Provides routing table entries (routes) in VPC routing tables for DATA subnets.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_route" "data" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  route_table_id         = element(aws_route_table.data.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)
}

# Provides resources that each create an association between a data subnet and a routing table.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_route_table_association" "data" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  subnet_id      = element(aws_subnet.data.*.id, count.index)
  route_table_id = element(aws_route_table.data.*.id, count.index)

  lifecycle {
    ignore_changes = [id]
  }
}

# Provides a VPC Endpoint resource for S3.
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

# Provides a resource to create an association between S3 VPC endpoint and public routing table.
resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.public.id
}

# Provides resources that each create an association between S3 VPC endpoint and an app routing table.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_vpc_endpoint_route_table_association" "s3_app" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = element(aws_route_table.app.*.id, count.index)

  lifecycle {
    ignore_changes = [id]
  }
}

# Provides resources that each create an association between S3 VPC endpoint and a data routing table.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_vpc_endpoint_route_table_association" "s3_data" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = element(aws_route_table.data.*.id, count.index)

  lifecycle {
    ignore_changes = [id]
  }
}

# Provides a VPC Endpoint resource for DynamoDB.
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
}

# Provides a resource to create an association between DynamoDB VPC endpoint and public routing table.
resource "aws_vpc_endpoint_route_table_association" "dynamodb_public" {
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  route_table_id  = aws_route_table.public.id
}

# Provides resources that each create an association between DynamoDB VPC endpoint and an app routing table.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_vpc_endpoint_route_table_association" "dynamodb_app" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  route_table_id  = element(aws_route_table.app.*.id, count.index)

  lifecycle {
    ignore_changes = [id]
  }
}

# Provides resources that each create an association between DynamoDB VPC endpoint and a data routing table.
# One for each AZ.
# Only created when the VPC is multi-tier.
resource "aws_vpc_endpoint_route_table_association" "dynamodb_data" {
  count = var.vpc_multi_tier ? length(var.subnet_availability_zones) : "0"

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  route_table_id  = element(aws_route_table.data.*.id, count.index)

  lifecycle {
    ignore_changes = [id]
  }
}

# Provides a resource to manage the default AWS DHCP Options Set in the current region.
resource "aws_default_vpc_dhcp_options" "this" {
  depends_on = [aws_vpc.this]

  tags = merge(
    local.common_tags,
    {
      "Name" = format("%s-default-dopt", var.vpc_name)
    },
    {
      "Description" = format("Default AWS DHCP options set for %s VPC", var.vpc_name)
    },
  )
}

# Provides a resource to manage the default AWS Network ACL. 
resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.this.default_network_acl_id

  ingress {
    protocol   = "-1"
    rule_no    = "100"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "0"
    to_port    = "0"
  }

  egress {
    protocol   = "-1"
    rule_no    = "100"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = "0"
    to_port    = "0"
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = format("%s-default-acl", var.vpc_name)
    },
    {
      "Description" = format("Default network ACL for %s VPC", var.vpc_name)
    },
  )

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

# Provides a resource to manage the default AWS Security Group.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      "Name" = format("%s-default-sg", var.vpc_name)
    },
    {
      "Description" = format("Default security group for %s VPC", var.vpc_name)
    },
  )
}

# Provides a VPC Flow Log to capture IP traffic for a VPC to S3 Bucket

module "flowlogs_to_s3_naming" {
  source = "git@github.com:traveloka/terraform-aws-resource-naming.git?ref=v0.20.0"
  name_prefix = format(
    "%s-flowlogs-%s",
    aws_vpc.this.id,
    data.aws_caller_identity.current.account_id,
  )
  resource_type = "s3_bucket"
}

resource "aws_s3_bucket" "flowlogs_to_s3" {
  bucket = module.flowlogs_to_s3_naming.name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "FlowLogsRetention"
    enabled = "true"

    expiration {
      days = var.flowlogs_bucket_retention_in_days
    }

    transition {
      days          = var.transition_to_glacier_ir_in_days
      storage_class = "GLACIER_IR"
    }
  }

  logging {
    target_bucket = var.flowlogs_s3_logging_bucket_name
    target_prefix = "${module.flowlogs_to_s3_naming.name}/"
  }

  tags = merge(
    var.additional_tags,
    {
      "ProductDomain" = var.product_domain
    },
    {
      "Environment" = var.environment
    },
    {
      "ManagedBy" = "terraform"
    },
    {
      "Name" = module.flowlogs_to_s3_naming.name
    }
  )
}

resource "aws_s3_bucket_public_access_block" "flowlogs_to_s3" {
  bucket = aws_s3_bucket.flowlogs_to_s3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "flowlogs_to_s3" {
  bucket = aws_s3_bucket.flowlogs_to_s3.id
  policy = data.aws_iam_policy_document.flowlogs_to_s3.json

  depends_on = [aws_s3_bucket.flowlogs_to_s3]
}

resource "aws_flow_log" "flowlogs_to_s3" {
  log_destination      = aws_s3_bucket.flowlogs_to_s3.arn
  log_destination_type = "s3"
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"

  destination_options {
    file_format = "parquet"
  }

  max_aggregation_interval = var.flowlogs_max_aggregation_interval

  tags = merge(
    var.additional_tags,
    {
      "Name" = module.flowlogs_to_s3_naming.name
    },
    {
      "ProductDomain" = var.product_domain
    },
    {
      "Environment" = var.environment
    },
    {
      "ManagedBy" = "terraform"
    },
  )

  depends_on = [aws_s3_bucket.flowlogs_to_s3]
}

# Provides a VPC Endpoint resource for CloudWatch Logs.
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app.*.id
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.cloudwatch_logs_sg.id,
  ]

  tags = merge(
    local.common_tags,
    {
      "Name" = format("%s-cloudwatch-logs-endpoint", var.vpc_name)
    },
  )
}

# Provides a VPC Endpoint's policy for CloudWatch Logs.
resource "aws_vpc_endpoint_policy" "cloudwatch_logs" {
  vpc_endpoint_id = aws_vpc_endpoint.cloudwatch_logs.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAll",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# Provides AWS Security Group for CloudWatch Logs VPC Endpoint
module "cloudwatch_logs_sg_naming" {
  source        = "git@github.com:traveloka/terraform-aws-resource-naming.git?ref=v0.24.1"
  name_prefix   = "cloudwatch-logs-endpoint"
  resource_type = "security_group"
}

resource "aws_security_group" "cloudwatch_logs_sg" {
  name        = module.cloudwatch_logs_sg_naming.name
  vpc_id      = aws_vpc.this.id
  description = format("Security group for %s-cloudwatch-logs-endpoint", var.vpc_name)

  tags = merge(
    local.common_tags,
    {
      "Name" = format("%s-cloudwatch-logs-endpoint", var.vpc_name)
    },
    {
      "Description" = format("Security group for %s-cloudwatch-logs-endpoint", var.vpc_name)
    },
  )
}

# Provides AWS Security Group Rule for CloudWatch Logs VPC Endpoint
resource "aws_security_group_rule" "ingress_cloudwatch_logs_sg" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cloudwatch_logs_sg.id
  cidr_blocks       = [var.vpc_cidr_block]
}
