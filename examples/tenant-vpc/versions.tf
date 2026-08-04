terraform {
  required_version = ">= 1.10.5"
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "2.4.2"
    }
    htpasswd = {
      source  = "loafoe/htpasswd"
      version = "1.2.1"
    }
  }
}
