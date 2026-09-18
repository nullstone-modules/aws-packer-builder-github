mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRoleWithWebIdentity\"}]}"
    }
  }
}
mock_provider "ns" {}
mock_provider "random" {}
mock_provider "tls" {
  mock_data "tls_certificate" {
    defaults = {
      certificates = [
        {
          cert_pem             = "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----\n"
          is_ca                = true
          issuer               = "CN=test"
          max_path_length      = 0
          not_after            = "2030-01-01T00:00:00Z"
          not_before           = "2020-01-01T00:00:00Z"
          public_key_algorithm = "RSA"
          serial_number        = "1"
          sha1_fingerprint     = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          signature_algorithm  = "SHA256-RSA"
          subject              = "CN=test"
          version              = 3
        },
      ]
    }
  }
}

variables {
  github_repositories = ["nullstone-modules/vault-cluster"]
}

run "packer_vpc_is_one_public_subnet" {
  command = plan

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a"]
    }
  }

  assert {
    condition     = aws_vpc.packer.cidr_block == "10.255.0.0/24"
    error_message = "default VPC CIDR should be 10.255.0.0/24"
  }

  assert {
    condition     = aws_subnet.packer.cidr_block == aws_vpc.packer.cidr_block
    error_message = "the single subnet must use the VPC CIDR"
  }

  assert {
    condition     = aws_subnet.packer.map_public_ip_on_launch == true
    error_message = "builder subnet must assign public IPs"
  }

  assert {
    condition     = aws_subnet.packer.availability_zone == "us-east-1a"
    error_message = "subnet must use the first available AZ"
  }

  assert {
    condition     = aws_internet_gateway.packer.vpc_id == aws_vpc.packer.id
    error_message = "IGW must attach to the Packer VPC"
  }

  assert {
    condition     = aws_route.packer_internet.destination_cidr_block == "0.0.0.0/0"
    error_message = "public route must be 0.0.0.0/0"
  }

  assert {
    condition     = aws_route.packer_internet.gateway_id == aws_internet_gateway.packer.id
    error_message = "default route must use the Internet gateway, not NAT"
  }

  assert {
    condition     = aws_route_table_association.packer.subnet_id == aws_subnet.packer.id
    error_message = "the one subnet must use the public route table"
  }

  assert {
    condition     = output.subnet_id == aws_subnet.packer.id
    error_message = "subnet_id output must be the public subnet"
  }

  assert {
    condition     = output.vpc_id == aws_vpc.packer.id
    error_message = "vpc_id output must be the Packer VPC"
  }
}

run "network_resources_carry_name_tags" {
  command = plan

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a"]
    }
  }

  override_resource {
    target = random_string.resource_suffix
    values = {
      result = "abcde"
    }
  }

  assert {
    condition     = aws_vpc.packer.tags["Name"] == "${data.ns_workspace.this.block_ref}-abcde"
    error_message = "VPC Name tag must be the workspace resource name"
  }

  assert {
    condition     = aws_internet_gateway.packer.tags["Name"] == aws_vpc.packer.tags["Name"]
    error_message = "IGW Name tag must match the VPC"
  }

  assert {
    condition     = aws_subnet.packer.tags["Name"] == "${aws_vpc.packer.tags["Name"]}-public"
    error_message = "subnet Name tag must be <vpc>-public"
  }

  assert {
    condition     = aws_route_table.packer.tags["Name"] == "${aws_vpc.packer.tags["Name"]}-public"
    error_message = "route table Name tag must be <vpc>-public"
  }

  assert {
    condition     = alltrue([for k, v in data.ns_workspace.this.aws_tags : aws_vpc.packer.tags[k] == v])
    error_message = "VPC must keep the workspace tags alongside Name"
  }
}

run "custom_cidr_applies_to_vpc_and_subnet" {
  command = plan

  variables {
    vpc_cidr = "192.168.200.0/24"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["us-east-1a"]
    }
  }

  assert {
    condition     = aws_vpc.packer.cidr_block == "192.168.200.0/24"
    error_message = "vpc_cidr should set the VPC"
  }

  assert {
    condition     = aws_subnet.packer.cidr_block == "192.168.200.0/24"
    error_message = "vpc_cidr should set the one subnet"
  }
}

run "invalid_cidr_fails" {
  command = plan

  variables {
    vpc_cidr = "not-a-cidr"
  }

  expect_failures = [
    var.vpc_cidr,
  ]
}
