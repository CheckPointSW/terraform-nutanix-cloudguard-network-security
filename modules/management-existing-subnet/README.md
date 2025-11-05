# Check Point CloudGuard Management Module (Existing Subnet)

This Terraform module deploys a Check Point CloudGuard Network Security Management Server VM into an **existing** Nutanix subnet
(no VPC or subnet creation).
It is intended for scenarios where network topology (VPC / overlay subnets) is pre‑provisioned,
and you only need to roll out the Management plane.

## Architecture Overview

Components provisioned by this module:

1. Lookup existing Nutanix cluster (`cluster_name`)
2. Lookup existing management subnet (`mgmt_subnet_name`)
3. Lookup an existing QCOW2 management image (`mgmt_image_name`)
4. Deploy one Management Server VM (legacy boot)
5. (Optional) Apply Cloud‑Init guest customization from a provided user‑data file

VPCs, subnets, floating IPs, gateways - those are assumed to exist / be managed externally.

## Prerequisites

| Item                  | Description                                                                                                                           |
|-----------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| Nutanix Prism Central | API credentials with permissions to read cluster, subnets, images and create VMs                                                      |
| Image                 | R81.20+ Management QCOW2 image uploaded ("All deployment types") from [SK158292](https://support.checkpoint.com/results/sk/sk158292)  |
| Existing Subnet       | Target Nutanix subnet name supplying connectivity for the Management Server VM                                                        |
| Terraform             | v1.10.5+ **64Bit** version                                                                                                            |
| Nutanix Provider      | `nutanix/nutanix` >= 2.3.1                                                                                                            |
| User‑Data (optional)  | Cloud‑Init file (plain text) if you wish to customize first boot (see [sk179752](https://support.checkpoint.com/results/sk/sk179752)) |

## Post‑deployment configuration

After the VM is created, you must still perform standard Check Point Management setup and onboarding tasks:

- Initial login and first‑time wizard (if not automated via user‑data) – set SIC, hostname, etc.
- Licensing – [CloudGuard Network Central License Tool Administration Guide](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Central_License_Tool_Admin_Guide/Content/Front-Matter/Front-Matter-Important-Information-Central-License-Tool.htm)
- Create / import Security Gateways and define security policies

## Usage

Follow module usage best practices described in the main
[CloudGuard Network Security Nutanix module documentation](https://registry.terraform.io/modules/CheckPointSW/cloudguard-network-security/nutanix/latest).

## Example Usage

```hcl
provider "nutanix" {}

module "cloudguard_mgmt" {
  source = "CheckPointSW/cloudguard-network-security/nutanix//modules/management-existing-subnet"

  # Required parameters
  cluster_name      = "MyCluster"
  mgmt_subnet_name  = "Existing-MGMT-Subnet"
  mgmt_image_name   = "cp-mgmt.qcow2"

  # Optional overrides
  mgmt_name                = "TF-MGMT"
  mgmt_description         = "Terraform Deployed CloudGuard Management"
  mgmt_num_cpus            = 2
  mgmt_num_cores_per_socket= 1
  mgmt_memory_in_gb        = 8
  mgmt_disk_size_in_gb     = 100

  # Provide user-data file path (absolute) to enable cloud-init customization
  mgmt_user_data_file_path = "C:/terraform/userdata/mgmt_cloud_init"
}
```

## Inputs (Variables)

| Name                      | Type   | Required | Default                                                            | Description                                                                                                  |
|---------------------------|--------|----------|--------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| cluster_name              | string | **yes**  | -                                                                  | Name of the Nutanix cluster registered in Prism Central.                                                     |
| mgmt_subnet_name          | string | **yes**  | -                                                                  | Name of existing Nutanix subnet where the Management VM NIC will attach.                                     |
| mgmt_image_name           | string | **yes**  | -                                                                  | QCOW2 image name for the Management Server in Nutanix image library.                                         |
| mgmt_name                 | string | no       | "TF-MGMT"                                                          | Management VM name.                                                                                          |
| mgmt_description          | string | no       | "Check Point CloudGuard Management Server VM created by Terraform" | Management VM description.                                                                                   |
| mgmt_num_cpus             | number | no       | 2                                                                  | Number of CPU sockets for the Management Server (>=2).                                                       |
| mgmt_num_cores_per_socket | number | no       | 1                                                                  | Number of cores per socket for the Management Server (>=1).                                                  |
| mgmt_memory_in_gb         | number | no       | 8                                                                  | Management Server memory size in GB (>=8 recommended).                                                       |
| mgmt_disk_size_in_gb      | number | no       | 100                                                                | Management Server disk size in GB (>=50, 100 recommended).                                                   |
| mgmt_user_data_file_path  | string | no       | ""                                                                 | Absolute path to user‑data (cloud‑init) file. If empty, guest customization is skipped.                      |

## References

- [Check Point CloudGuard Private Cloud Images (SK158292)](https://support.checkpoint.com/results/sk/sk158292)
- [sk179752 – How to configure cloud-init](https://support.checkpoint.com/results/sk/sk179752)
- [CloudGuard Network Central License Tool Admin Guide](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Central_License_Tool_Admin_Guide/Content/Front-Matter/Front-Matter-Important-Information-Central-License-Tool.htm)
- [Terraform Nutanix Provider Docs](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs)
