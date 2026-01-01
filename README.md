![GitHub Watchers](https://img.shields.io/github/watchers/CheckPointSW/terraform-nutanix-cloudguard-network-security)
![GitHub Release](https://img.shields.io/github/v/release/CheckPointSW/terraform-nutanix-cloudguard-network-security)
![GitHub Commits Since Last Commit](https://img.shields.io/github/commits-since/CheckPointSW/terraform-nutanix-cloudguard-network-security/latest/master)
![GitHub Last Commit](https://img.shields.io/github/last-commit/CheckPointSW/terraform-nutanix-cloudguard-network-security/master)
![GitHub Repo Size](https://img.shields.io/github/repo-size/CheckPointSW/terraform-nutanix-cloudguard-network-security)
![GitHub Downloads](https://img.shields.io/github/downloads/CheckPointSW/terraform-nutanix-cloudguard-network-security/total)

# Terraform Modules for CloudGuard Network Security (CGNS) — Nutanix

## Introduction
This repository provides a structured set of Terraform modules for deploying Check Point CloudGuard Network Security in Nutanix.<br>
These modules automate the creation of Security Gateways and Management servers.<br>
The repository contains:
* Terraform modules
* Community-supported content

### Prerequisites
* Terraform version v1.10.5 or later **64bit version**.
* Nutanix Prism Central 7.0 or later.
* Nutanix Terraform Provider v2.0.0 or later.
* Check Point CloudGuard Network Security QCOWs images from [CloudGuard Network for Private Cloud images
  ](https://support.checkpoint.com/results/sk/sk158292) **R81.20** or later.

## Repository Structure
`Submodules:` Contains modular, reusable, production-grade Terraform components, each with its own documentation.

`Examples:` Demonstrates how to use the modules.

**Submodules:**
* [CloudGuard Management - Existing Subnet](https://registry.terraform.io/modules/CheckPointSW/cloudguard-network-security/nutanix/latest/submodules/management-existing-subnet): Deploys a CloudGuard Management Server VM into an existing Nutanix subnet.
* [CloudGuard Gateway - Existing Subnet](https://registry.terraform.io/modules/CheckPointSW/cloudguard-network-security/nutanix/latest/submodules/gateway-existing-subnet): Deploys a CloudGuard Security Gateway VM into an existing Nutanix subnet.

**Examples:**
* [Tenant-VPC](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/nutanix/latest/examples/tenant-vpc): Deploys a complete CloudGuard Network Security setup with Management and Gateway in a tenant VPC.
* [Transit-VPC](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/nutanix/latest/examples/transit-vpc): Deploys a CloudGuard Network Security Gateway in a transit VPC setup.


***

# Best Practices for Using CloudGuard Modules

## Step 1: Use the Required Module
Add the required module in your Terraform configuration file to deploy resources. For example:

```hcl
provider "nutanix" {}

module "example_module" {
  source  = "CheckPointSW/cloudguard-network-security/nutanix//modules/{module_name}"
  version = "{chosen_version}"
  # Add the required inputs
}
```
---
## Step 2: Open the Terminal
Ensure you have [Terraform](https://developer.hashicorp.com/terraform/install) installed and navigate to the directory
where your Terraform configuration file is located using the appropriate terminal:
- **Linux**: **Terminal**.
- **Windows**: **PowerShell** or **Command Prompt**.

---

## Step 3: Set Environment Variables
Set the required environment variables, See [Nutanix Argument Reference](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs#argument-reference).

### Linux
```bash
export NUTANIX_USER="your_nutanix_username"
export NUTANIX_PASSWORD="your_nutanix_password"
export NUTANIX_ENDPOINT="your_prism_central_server"
```
### PowerShell (Windows)
```PowerShell
$env:NUTANIX_USER="your_nutanix_username"
$env:NUTANIX_PASSWORD="your_nutanix_password"
$env:NUTANIX_ENDPOINT"your_prism_central_server"
```
### Command Prompt (Windows)
```cmd
set NUTANIX_USER=your_nutanix_username
set NUTANIX_PASSWORD=your_nutanix_password
set NUTANIX_ENDPOINT=your_prism_central_server
```
---

## Step 4: Deploy with Terraform
Use Terraform commands to deploy resources securely.

### Initialize Terraform
Prepare the working directory and download required provider plugins:
```shell
terraform init
```

### Plan Deployment
Preview the changes Terraform will make:
```shell
terraform plan
```
### Apply Deployment
Apply the planned changes and deploy the resources:
```shell
terraform apply
```
Notes:
1. Type `yes` when prompted to confirm the deployment.
2. The deployment takes a few minutes to complete (depending on the deployment size, can take ~30 minutes).

## Related Products and Solutions
* CloudGuard Network Security for [VMware](https://github.com/CheckPointSW/terraform-vmware-cloudguard-network-security)
* CloudGuard Network Security for [AWS](https://github.com/CheckPointSW/terraform-aws-cloudguard-network-security)
* CloudGuard Network Security for [Azure](https://github.com/CheckPointSW/terraform-azure-cloudguard-network-security)

## References
* For more information about Check Point CloudGuard for Public Cloud, see https://www.checkpoint.com/products/iaas-public-cloud-security/
* CloudGuard documentation is available at https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk132552&
* CloudGuard Network CheckMates community is available at https://community.checkpoint.com/t5/CloudGuard-IaaS/bd-p/cloudguard-iaas

