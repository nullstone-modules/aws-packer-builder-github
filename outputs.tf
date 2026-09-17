output "role_arn" {
  value       = aws_iam_role.packer.arn
  description = "string ||| IAM role ARN for GitHub Actions to assume via OIDC and run Packer."
}

output "aws_region" {
  value       = data.aws_region.this.region
  description = "string ||| AWS region of this workspace. The bake runs here."
}

output "aws_account_id" {
  value       = data.aws_caller_identity.this.account_id
  description = "string ||| AWS account ID that owns baked AMIs. Other accounts set ami_owner to this."
}

output "vpc_id" {
  value       = aws_vpc.packer.id
  description = "string ||| VPC for Packer builder instances."
}

output "subnet_id" {
  value       = aws_subnet.packer.id
  description = "string ||| Public subnet for Packer builder instances. Pass to amazon-ebs subnet_id."
}
