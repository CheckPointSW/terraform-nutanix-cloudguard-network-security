terraform {
  # 64-bit binary only supported
  # Download from: https://releases.hashicorp.com/terraform/
  required_version = ">= 1.10.5"
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "2.3.1"
    }
  }
}
