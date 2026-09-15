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

output "ami_regions" {
  value       = var.ami_regions
  description = "list(string) ||| Regions Packer copies the AMI into, besides aws_region."
}

output "ami_org_arns" {
  value       = var.ami_org_arns
  description = "list(string) ||| Organization ARNs granted AMI launch permission at bake time."
}
