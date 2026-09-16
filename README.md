# Packer Builder (AWS via GitHub)
#### nullstone/aws-packer-builder-github

---

## What Does This Module Do?

Creates the AWS IAM role GitHub Actions assumes (OIDC, not access keys) to bake AMIs with Packer in this account.

It also creates the GitHub OIDC provider if this account does not already have one. Outputs are the role ARN, workspace region, and account ID. Copy regions and org launch ARNs stay on each Packer build, not on this module.

---

## When Should I Use This?

When a GitHub Actions workflow in this org needs to run Packer against this AWS account, and you do not want to hand-build the role or paste `AWS_ROLE_ARN` into repo secrets.

Create this block once per AMI-owning account. Other Packer AMIs in the same account share it by listing their repositories in `github_repositories`.

---

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `github_repositories` | list(string) | (required) | Repositories allowed to assume the role, each `owner/name`. |
| `github_oidc_provider_arn` | string | `""` | Existing GitHub OIDC provider ARN. Leave empty to create one. |

---

## Outputs

| Name | Description |
| --- | --- |
| `role_arn` | IAM role GitHub Actions assumes through OIDC. |
| `aws_region` | Region of this workspace. Bake here. |
| `aws_account_id` | Account that owns the AMIs. Other accounts set `ami_owner` to this. |

---

## How Do I Use This?

Create this block once in the AWS account that should own the AMIs. Example:

```yaml
blocks:
  aws-packer-builder:
    module: nullstone/aws-packer-builder-github
    vars:
      github_repositories:
        - nullstone-modules/vault-cluster
```

If this account already has a GitHub OIDC provider, set `github_oidc_provider_arn` to that ARN. AWS allows only one provider per URL.

The bake workflow reads the role and bake region from this workspace. Copy regions stay on the image repo (`AMI_REGIONS` or Packer `-var ami_regions=`).

```yaml
env:
  NULLSTONE_ORG: ${{ vars.NULLSTONE_ORG }}
  NULLSTONE_API_KEY: ${{ secrets.NULLSTONE_API_KEY }}
  NULLSTONE_STACK: ${{ vars.NULLSTONE_STACK }}
  NULLSTONE_BLOCK: ${{ vars.NULLSTONE_BLOCK }}
  NULLSTONE_ENV: ${{ vars.NULLSTONE_ENV }}

steps:
  - uses: nullstone-io/setup-nullstone-action@v0
  - id: packer
    run: |
      echo "role_arn=$(nullstone outputs --field=role_arn)" >> "$GITHUB_OUTPUT"
      echo "aws_region=$(nullstone outputs --field=aws_region)" >> "$GITHUB_OUTPUT"
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ steps.packer.outputs.role_arn }}
      aws-region: ${{ steps.packer.outputs.aws_region }}
```

GitHub still needs `NULLSTONE_API_KEY`. It does not need `AWS_ROLE_ARN`. `AMI_REGIONS` and `AMI_ORG_ARNS` belong on the Packer workflow, not this workspace.

---

## Trust and permissions

The role trust is GitHub OIDC only. `sub` is `repo:<owner>/<name>:*` for each listed repository, so a `workflow_dispatch` from a branch can bake. Access keys are not created.

The identity policy is Packer's amazon-ebs set, plus `ec2:CopyImage` and `ec2:ModifyImageAttribute` so a bake can copy regions and grant org launch permission. Which regions and orgs is each image's Packer config.

---

## Limitations

This module does not run Packer. It only creates the role. The AMI lookup tag (`Name = nullstone-vault` for Vault) stays in the image repo.

Creating a second GitHub OIDC provider in the same account fails. Set `github_oidc_provider_arn` when one already exists.
