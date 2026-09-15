variable "github_repositories" {
  type        = list(string)
  description = <<EOF
GitHub repositories allowed to assume the Packer role, each as `owner/name`.
The trust policy matches `repo:<owner>/<name>:*` so workflow_dispatch and branch pushes both work.
EOF

  validation {
    condition     = length(var.github_repositories) > 0
    error_message = "github_repositories must list at least one owner/name repository."
  }

  validation {
    condition     = alltrue([for r in var.github_repositories : can(regex("^[^/]+/[^/]+$", r))])
    error_message = "Each github_repositories entry must be owner/name."
  }
}

variable "github_oidc_provider_arn" {
  type        = string
  default     = ""
  description = <<EOF
ARN of an existing GitHub OIDC provider in this account (`token.actions.githubusercontent.com`).
Leave empty to create one. An account can have only one provider for that URL; if create fails
with EntityAlreadyExists, set this to the existing ARN.
EOF
}

variable "ami_regions" {
  type        = list(string)
  default     = []
  description = <<EOF
Regions Packer should copy the finished AMI into, besides the bake region.
Exposed as an output so the GitHub bake workflow does not need an AMI_REGIONS repo variable.
EOF
}

variable "ami_org_arns" {
  type        = list(string)
  default     = []
  description = <<EOF
Organization ARNs granted AMI launch permission at bake time (`arn:aws:organizations::ACCOUNT:organization/o-...`).
Exposed as an output so the GitHub bake workflow does not need an AMI_ORG_ARNS repo variable.
Does not make the AMI public.
EOF

  validation {
    condition = alltrue([
      for a in var.ami_org_arns : can(regex("^arn:aws:organizations::[0-9]{12}:organization/o-[a-z0-9]+$", a))
    ])
    error_message = "Each ami_org_arns entry must be an organization ARN."
  }
}
