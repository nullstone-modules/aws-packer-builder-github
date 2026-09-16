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
