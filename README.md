# terraform-aws-vpc

[![Terraform Version](https://img.shields.io/badge/Terraform%20Version->=0.13.0,_<0.14.0-blue.svg)](https://releases.hashicorp.com/terraform/)
[![Release](https://img.shields.io/github/release/traveloka/terraform-aws-vpc.svg)](https://github.com/traveloka/terraform-aws-vpc/releases)
[![Last Commit](https://img.shields.io/github/last-commit/traveloka/terraform-aws-vpc.svg)](https://github.com/traveloka/terraform-aws-vpc/commits/master)
[![Issues](https://img.shields.io/github/issues/traveloka/terraform-aws-vpc.svg)](https://github.com/traveloka/terraform-aws-vpc/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/traveloka/terraform-aws-vpc.svg)](https://github.com/traveloka/terraform-aws-vpc/pulls)
[![License](https://img.shields.io/github/license/traveloka/terraform-aws-vpc.svg)](https://github.com/traveloka/terraform-aws-vpc/blob/master/LICENSE)
![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.png?v=103)

## Table of Content

- [Prerequisites](#Prerequisites)
- [Quick Start](#Quick-Start)
- [Dependencies](#Dependencies)
- [Contributing](#Contributing)
- [Contributor](#Contributor)
- [License](#License)
- [Acknowledgments](#Acknowledgments)

## Prerequisites

- [Terraform](https://releases.hashicorp.com/terraform/). This module currently tested on `0.13.7`

## Quick Start
Terraform module to create all mandatory VPC components.

This module supports either single-tier (only public subnet) or multi-tier (public-app-data subnets) VPC creation.
This module supports only up to 4 AZs.

### Multi-Tier VPC

```hcl
module "abc_dev" {
  source  = "traveloka/vpc/aws"
  version = "v0.8.0"
  
  product_domain = "abc"
  environment    = "dev"

  vpc_name       = "abc-dev"
  vpc_cidr_block = "172.16.0.0/16"

  flowlogs_s3_logging_bucket_name = "S3-bucket-name"
}
```

We use multi-tier architecture for our VPC design. This design divides the infrastructure into three layers: 
- Public tier: entrypoint for public-facing client. Using public subnet since resources in this tier will be discoverable through Internet. Examples: external load balancer, bastion, etc.
- Application Tier: this is where the business logic services life and communicate each others. This tier using private subnet, hence it's only accessible through private network.
- Database Tier: this is where databases life. Application and databases are seperated to have clear boundaries and secure access through application tier.

Benefits or having multi-tier architecture are:
- Scalable
- Gives us high availability and redundancy
- Fit with microservices architecture
- Clear boundaries between public-facing, business logic, and data storage
- Secure and reduce risk, because by default any services life at private subnet, and database only accessible through the application tier.

### Single-Tier VPC

In some cases, you will need a VPC which has only public subnets.

```hcl
module "abc_dev" {
  source  = "traveloka/vpc/aws"
  version = "v0.8.0"

  # you only need to add this line
  vpc_multi_tier = false 

  # ... omitted
}
```

In some situations (it is not always happening), you will get some errors from Terraform when you set `vpc_multi_tier = false`.
It happens because several resources were not created but stated as the outputs.
Currrently Terraform does not allow `count` inside `output` block, so now it is inevitable.
But don't worry, the errors have nothing to do with the stacks/resources/infrastructures that you created.
Just re-execute `terraform apply` and you will be fine.

### Examples

* [Multi-Tier VPC](https://github.com/traveloka/terraform-aws-vpc/tree/master/examples/multi-tier)

### Module


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.0 |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.74 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.74 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_flowlogs_to_s3_naming"></a> [flowlogs\_to\_s3\_naming](#module\_flowlogs\_to\_s3\_naming) | git@github.com:traveloka/terraform-aws-resource-naming.git | v0.20.0 |
| <a name="module_cloudwatch_logs_sg_naming"></a> [cloudwatch\_logs\_sg\_naming](#module\_cloudwatch\_logs\_sg\_naming) | git@github.com:traveloka/terraform-aws-resource-naming.git | v0.24.1 |

## Resources

| Name | Type |
|------|------|
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_default_network_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_network_acl) | resource |
| [aws_default_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table) | resource |
| [aws_default_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_default_vpc_dhcp_options.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_vpc_dhcp_options) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_elasticache_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |
| [aws_flow_log.flowlogs_to_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.data_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_rule.data_acl_additional_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.data_acl_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.data_acl_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_redshift_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_subnet_group) | resource |
| [aws_route.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_s3_bucket.flowlogs_to_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.flowlogs_to_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.flowlogs_to_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_security_group.cloudwatch_logs_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.ingress_cloudwatch_logs_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_subnet.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_policy.cloudwatch_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_policy) | resource |
| [aws_vpc_endpoint_route_table_association.dynamodb_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_vpc_endpoint_route_table_association.dynamodb_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_vpc_endpoint_route_table_association.dynamodb_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_vpc_endpoint_route_table_association.s3_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_vpc_endpoint_route_table_association.s3_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_vpc_endpoint_route_table_association.s3_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.flowlogs_to_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_app_subnet_tags"></a> [additional\_app\_subnet\_tags](#input\_additional\_app\_subnet\_tags) | A map of additional tags to add to the application subnet | `map` | `{}` | no |
| <a name="input_additional_data_subnet_network_acl_ingress"></a> [additional\_data\_subnet\_network\_acl\_ingress](#input\_additional\_data\_subnet\_network\_acl\_ingress) | List of CIDR blocks to add ingress to data subnet in multi tier VPC. | `list(string)` | `[]` | no |
| <a name="input_additional_data_subnet_tags"></a> [additional\_data\_subnet\_tags](#input\_additional\_data\_subnet\_tags) | A map of additional tags to add to the data subnet | `map` | `{}` | no |
| <a name="input_additional_public_subnet_tags"></a> [additional\_public\_subnet\_tags](#input\_additional\_public\_subnet\_tags) | A map of additional tags to add to the public subnet | `map` | `{}` | no |
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | A map of additional tags to add to all resources | `map` | `{}` | no |
| <a name="input_additional_vpc_tags"></a> [additional\_vpc\_tags](#input\_additional\_vpc\_tags) | A map of additional tags to add to the vpc | `map` | `{}` | no |
| <a name="input_enable_data_subnet_network_acl_ingress"></a> [enable\_data\_subnet\_network\_acl\_ingress](#input\_enable\_data\_subnet\_network\_acl\_ingress) | Set to true to enable ACL to ingress from app subnet to data subnet in multi tier VPC, which block ingress from public subnet to data subnet. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Type of environment these resources belong to. | `string` | n/a | yes |
| <a name="input_flow_logs_log_group_retention_period"></a> [flow\_logs\_log\_group\_retention\_period](#input\_flow\_logs\_log\_group\_retention\_period) | Specifies the number of days you want to retain log events in the specified log group. | `string` | `"14"` | no |
| <a name="input_flowlogs_bucket_retention_in_days"></a> [flowlogs\_bucket\_retention\_in\_days](#input\_flowlogs\_bucket\_retention\_in\_days) | FlowLogs bucket retention (in days) | `number` | `365` | no |
| <a name="input_flowlogs_max_aggregation_interval"></a> [flowlogs\_max\_aggregation\_interval](#input\_flowlogs\_max\_aggregation\_interval) | FlowLogs Max Aggregation Interval | `number` | `600` | no |
| <a name="input_flowlogs_s3_logging_bucket_name"></a> [flowlogs\_s3\_logging\_bucket\_name](#input\_flowlogs\_s3\_logging\_bucket\_name) | S3 bucket name to store FlowLogs S3 Bucket log | `string` | n/a | yes |
| <a name="input_product_domain"></a> [product\_domain](#input\_product\_domain) | Product domain these resources belong to. | `string` | n/a | yes |
| <a name="input_subnet_availability_zones"></a> [subnet\_availability\_zones](#input\_subnet\_availability\_zones) | List of AZs to spread VPC subnets over. | `list(string)` | <pre>[<br>  "ap-southeast-1a",<br>  "ap-southeast-1b",<br>  "ap-southeast-1c"<br>]</pre> | no |
| <a name="input_transition_to_glacier_ir_in_days"></a> [transition\_to\_glacier\_ir\_in\_days](#input\_transition\_to\_glacier\_ir\_in\_days) | Days stored in standard class before transition to glacier | `number` | `30` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | The CIDR block for the VPC. | `string` | n/a | yes |
| <a name="input_vpc_enable_dns_hostnames"></a> [vpc\_enable\_dns\_hostnames](#input\_vpc\_enable\_dns\_hostnames) | A boolean flag to enable/disable DNS hostnames in the VPC. Defaults true. | `string` | `"true"` | no |
| <a name="input_vpc_enable_dns_support"></a> [vpc\_enable\_dns\_support](#input\_vpc\_enable\_dns\_support) | A boolean flag to enable/disable DNS support in the VPC. Defaults true. | `string` | `"true"` | no |
| <a name="input_vpc_multi_tier"></a> [vpc\_multi\_tier](#input\_vpc\_multi\_tier) | Whether this VPC should have 3 tiers. True means 3-tier, false means single-tier. Defaults true. Recommended value is true. | `string` | `"true"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of the VPC. This name will be used as the prefix for all VPC components. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_account_id"></a> [aws\_account\_id](#output\_aws\_account\_id) | The AWS Account ID number of the account that owns or contains the calling entity. |
| <a name="output_aws_caller_arn"></a> [aws\_caller\_arn](#output\_aws\_caller\_arn) | The AWS ARN associated with the calling entity. |
| <a name="output_aws_caller_user_id"></a> [aws\_caller\_user\_id](#output\_aws\_caller\_user\_id) | The unique identifier of the calling entity. |
| <a name="output_db_subnet_group_arn"></a> [db\_subnet\_group\_arn](#output\_db\_subnet\_group\_arn) | The ARN of the db subnet group. |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | The db subnet group name. |
| <a name="output_eip_nat_ids"></a> [eip\_nat\_ids](#output\_eip\_nat\_ids) | List of Elastic IP allocation IDs for NAT Gateway. |
| <a name="output_eip_nat_public_ips"></a> [eip\_nat\_public\_ips](#output\_eip\_nat\_public\_ips) | List of Elastic IP  public IPs for NAT Gateway. |
| <a name="output_elasticache_subnet_group_name"></a> [elasticache\_subnet\_group\_name](#output\_elasticache\_subnet\_group\_name) | The elasticache subnet group name. |
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | The ID of the Internet Gateway. |
| <a name="output_nat_ids"></a> [nat\_ids](#output\_nat\_ids) | List of NAT Gateway IDs |
| <a name="output_nat_network_interface_ids"></a> [nat\_network\_interface\_ids](#output\_nat\_network\_interface\_ids) | List of ENI IDs of the network interface created by the NAT gateway. |
| <a name="output_nat_private_ips"></a> [nat\_private\_ips](#output\_nat\_private\_ips) | List of private IP addresses of the NAT Gateway. |
| <a name="output_redshift_subnet_group_id"></a> [redshift\_subnet\_group\_id](#output\_redshift\_subnet\_group\_id) | The Redshift Subnet group ID. |
| <a name="output_region_ec2_endpoint"></a> [region\_ec2\_endpoint](#output\_region\_ec2\_endpoint) | The EC2 endpoint for the selected region. |
| <a name="output_region_name"></a> [region\_name](#output\_region\_name) | The name of the selected region. |
| <a name="output_rtb_app_ids"></a> [rtb\_app\_ids](#output\_rtb\_app\_ids) | List of IDs of app route tables |
| <a name="output_rtb_data_ids"></a> [rtb\_data\_ids](#output\_rtb\_data\_ids) | List of IDs of data route tables |
| <a name="output_rtb_public_id"></a> [rtb\_public\_id](#output\_rtb\_public\_id) | ID of public route table |
| <a name="output_subnet_app_cidr_blocks"></a> [subnet\_app\_cidr\_blocks](#output\_subnet\_app\_cidr\_blocks) | List of cidr\_blocks of app subnets. |
| <a name="output_subnet_app_ids"></a> [subnet\_app\_ids](#output\_subnet\_app\_ids) | List of IDs of app subnets. |
| <a name="output_subnet_data_cidr_blocks"></a> [subnet\_data\_cidr\_blocks](#output\_subnet\_data\_cidr\_blocks) | List of cidr\_blocks of data subnets. |
| <a name="output_subnet_data_ids"></a> [subnet\_data\_ids](#output\_subnet\_data\_ids) | List of IDs of data subnets. |
| <a name="output_subnet_public_cidr_blocks"></a> [subnet\_public\_cidr\_blocks](#output\_subnet\_public\_cidr\_blocks) | List of cidr\_blocks of public subnets. |
| <a name="output_subnet_public_ids"></a> [subnet\_public\_ids](#output\_subnet\_public\_ids) | List of IDs of public subnets. |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC. |
| <a name="output_vpc_default_network_acl_id"></a> [vpc\_default\_network\_acl\_id](#output\_vpc\_default\_network\_acl\_id) | The ID of the network ACL created by default on VPC creation. |
| <a name="output_vpc_default_route_table_id"></a> [vpc\_default\_route\_table\_id](#output\_vpc\_default\_route\_table\_id) | The ID of the route table created by default on VPC creation. |
| <a name="output_vpc_default_security_group_id"></a> [vpc\_default\_security\_group\_id](#output\_vpc\_default\_security\_group\_id) | The ID of the security group created by default on VPC creation. |
| <a name="output_vpc_enable_classiclink"></a> [vpc\_enable\_classiclink](#output\_vpc\_enable\_classiclink) | Whether or not the VPC has Classiclink enabled. |
| <a name="output_vpc_enable_dns_hostnames"></a> [vpc\_enable\_dns\_hostnames](#output\_vpc\_enable\_dns\_hostnames) | Whether or not the VPC has DNS hostname support. |
| <a name="output_vpc_enable_dns_support"></a> [vpc\_enable\_dns\_support](#output\_vpc\_enable\_dns\_support) | Whether or not the VPC has DNS support. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC. |
| <a name="output_vpc_instance_tenancy"></a> [vpc\_instance\_tenancy](#output\_vpc\_instance\_tenancy) | Tenancy of instances spin up within VPC. |
| <a name="output_vpc_main_route_table_id"></a> [vpc\_main\_route\_table\_id](#output\_vpc\_main\_route\_table\_id) | The ID of the main route table associated with this VPC. |
| <a name="output_vpc_multi_tier"></a> [vpc\_multi\_tier](#output\_vpc\_multi\_tier) | Whether or not the VPC has Multi Tier subnets. |
| <a name="output_vpce_cloudwatch_logs_id"></a> [vpce\_cloudwatch_logs\_id](#output\_vpce\_cloudwatch_logs\_id) | The ID of VPC endpoint for Cloudwatch Logs |
| <a name="output_vpce_cloudwatch_logs_network_interface_ids"></a> [vpce\_cloudwatch_logs\_network\_interface\_ids](#output\_vpce\_cloudwatch_logs\_network\_interface\_ids) | One or more network interfaces for the VPC Endpoint. Applicable for endpoints of type `Interface`. |
| <a name="output_vpce_cloudwatch_logs_security_group_id"></a> [vpce\_cloudwatch_logs\_security_group\_id](#output\_vpce\_cloudwatch_logs\_security_group\_id) | The ID of the security group for Cloudwatch Logs VPC endpoint. |
| <a name="output_vpce_cloudwatch_logs_security_group_rule_id"></a> [vpce\_cloudwatch_logs\_security_group_rule\_id](#output\_vpce\_cloudwatch_logs\_security_group_rule\_id) | The ID of the security group rule for Cloudwatch Logs VPC endpoint. |
| <a name="output_vpce_dynamodb_cidr_blocks"></a> [vpce\_dynamodb\_cidr\_blocks](#output\_vpce\_dynamodb\_cidr\_blocks) | The list of CIDR blocks for DynamoDB service. |
| <a name="output_vpce_dynamodb_id"></a> [vpce\_dynamodb\_id](#output\_vpce\_dynamodb\_id) | The ID of VPC endpoint for DynamoDB |
| <a name="output_vpce_dynamodb_prefix_list_id"></a> [vpce\_dynamodb\_prefix\_list\_id](#output\_vpce\_dynamodb\_prefix\_list\_id) | The prefix list for the DynamoDB VPC endpoint. |
| <a name="output_vpce_s3_cidr_blocks"></a> [vpce\_s3\_cidr\_blocks](#output\_vpce\_s3\_cidr\_blocks) | The list of CIDR blocks for S3 service. |
| <a name="output_vpce_s3_id"></a> [vpce\_s3\_id](#output\_vpce\_s3\_id) | The ID of VPC endpoint for S3 |
| <a name="output_vpce_s3_prefix_list_id"></a> [vpce\_s3\_prefix\_list\_id](#output\_vpce\_s3\_prefix\_list\_id) | The prefix list for the S3 VPC endpoint. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

Apache 2 Licensed. See LICENSE for full details.

## Acknowledgement
