# Packer Build (AWS)
#### nullstone/aws-packer-build

---

## What Does This Module Do?

Creates the AWS IAM role GitHub Actions assumes (OIDC, not access keys) to bake AMIs with Packer in this account.

It also creates the GitHub OIDC provider if this account does not already have one. Outputs are what a bake workflow needs: role ARN, region, optional AMI copy regions, and optional org launch ARNs.

---

## When Should I Use This?

When a GitHub Actions workflow in this org needs to run Packer against this AWS account, and you do not want to hand-build the role or paste `AWS_ROLE_ARN` into repo secrets.

The Vault cluster bake is the first consumer. Other Packer AMIs in the same account can share this block by listing their repositories in `github_repositories`.

---

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `github_repositories` | list(string) | (required) | Repositories allowed to assume the role, each `owner/name`. |
| `github_oidc_provider_arn` | string | `""` | Existing GitHub OIDC provider ARN. Leave empty to create one. |
| `ami_regions` | list(string) | `[]` | Extra regions Packer copies the AMI into. |
| `ami_org_arns` | list(string) | `[]` | Organization ARNs granted launch permission at bake time. Not public. |

---

## Outputs

| Name | Description |
| --- | --- |
| `role_arn` | IAM role GitHub Actions assumes through OIDC. |
| `aws_region` | Region of this workspace. Bake here. |
| `aws_account_id` | Account that owns the AMIs. Other accounts set `ami_owner` to this. |
| `ami_regions` | Extra copy regions, for the bake workflow. |
| `ami_org_arns` | Org launch ARNs, for the bake workflow. |

---

## How Do I Use This?

Create this block once in the AWS account that should own the AMIs. Example Nullstone config:

```yaml
datastores:
  packer-build:
    module: nullstone/aws-packer-build
    vars:
      github_repositories:
        - nullstone-modules/vault-cluster
      ami_regions:
        - us-west-2
      ami_org_arns:
        - arn:aws:organizations::123456789012:organization/o-example
```

If this account already has a GitHub OIDC provider, set `github_oidc_provider_arn` to that ARN. AWS allows only one provider per URL.

The bake workflow reads outputs with the Nullstone CLI instead of GitHub AWS secrets:

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
      echo "ami_regions=$(nullstone outputs --field=ami_regions)" >> "$GITHUB_OUTPUT"
      echo "ami_org_arns=$(nullstone outputs --field=ami_org_arns)" >> "$GITHUB_OUTPUT"
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ steps.packer.outputs.role_arn }}
      aws-region: ${{ steps.packer.outputs.aws_region }}
```

GitHub still needs `NULLSTONE_API_KEY` and the workspace pointers (`NULLSTONE_ORG`, `NULLSTONE_STACK`, `NULLSTONE_BLOCK`, `NULLSTONE_ENV`). It does not need `AWS_ROLE_ARN`, `AWS_REGION`, `AMI_REGIONS`, or `AMI_ORG_ARNS`.

---

## Trust and permissions

The role trust is GitHub OIDC only. `sub` is `repo:<owner>/<name>:*` for each listed repository, so a `workflow_dispatch` from a branch can bake. Access keys are not created.

The identity policy is Packer's amazon-ebs set, plus `ec2:CopyImage` and `ec2:ModifyImageAttribute` so the bake can copy regions and grant org launch permission.

---

## Limitations

This module does not run Packer. It only creates the role and publishes bake settings as outputs. The AMI lookup tag (`Name = nullstone-vault` for Vault) stays in the image repo.

Creating a second GitHub OIDC provider in the same account fails. Set `github_oidc_provider_arn` when one already exists.
