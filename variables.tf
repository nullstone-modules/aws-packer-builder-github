variable "github_repositories" {
  type        = list(string)
  description = <<EOF
GitHub repositories allowed to assume the Packer role, each as `owner/name`.
The trust policy matches both `repo:<owner>/<name>:*` (legacy OIDC subject) and
`repo:<owner>@*/<name>@*:*` (immutable subject used by repos created after 2026-07-15).
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

variable "vpc_cidr" {
  type        = string
  default     = "10.255.0.0/24"
  description = "CIDR for the Packer VPC and its single public subnet."

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
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
