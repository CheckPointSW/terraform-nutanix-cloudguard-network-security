# Check Point CloudGuard Gateway Module (Existing Subnet)

This Terraform module deploys a Check Point CloudGuard Network Security Gateway (single gateway or first member for
later clustering) VM into an **existing** Nutanix subnet.
It is intended for scenarios where network topology (VPC / overlay subnets) is already provisioned and you only need to
roll out a Security Gateway.

## Architecture Overview

Components provisioned by this module:

1. Lookup existing Nutanix cluster (`cluster_name`)
2. Lookup existing external & internal gateway subnets (`gw_external_subnet_name`, `gw_internal_subnet_name`)
3. Lookup an existing QCOW2 gateway image (`gw_image_name`)
4. Deploy one Gateway VM (legacy boot) with two NICs (external, internal)
5. (Optional) Apply Cloud‑Init guest customization from a provided user‑data file

VPCs, subnets, floating IPs, gateways - those are assumed to exist / be managed externally.

## Prerequisites

| Item                  | Description                                                                                                          |
|-----------------------|----------------------------------------------------------------------------------------------------------------------|
| Nutanix Prism Central | API credentials with permissions to read cluster, subnets, images and create VMs                                     |
| Image                 | R81.20+ Gateway QCOW2 image uploaded ("Gateway") from [SK158292](https://support.checkpoint.com/results/sk/sk158292) |
| Existing Subnets      | Names of the existing external and internal Nutanix subnets for the Gateway VM NICs                                  |
| Terraform             | v1.10.5+ **64Bit** version                                                                                           |
| Nutanix Provider      | `nutanix/nutanix` >= 2.3.1                                                                                           |
| User‑Data (optional)  | Cloud‑Init file (plain text) to automate first boot configuration (admin password, SIC, hostname, etc.)              |

## Post‑deployment configuration

unless automated via user‑data: After the VM is created, you must still perform the standard Security Gateway first‑time
configuration.

- Initial login and first‑time wizard (if not automated via user‑data) – set SIC, hostname, etc.

## Usage

Follow module usage best practices described in the main
[CloudGuard Network Security Nutanix module documentation](https://registry.terraform.io/modules/CheckPointSW/cloudguard-network-security/nutanix/latest).

## Example Usage

```hcl
provider "nutanix" {}

module "cloudguard_gw" {
  source = "CheckPointSW/cloudguard-network-security/nutanix//modules/gateway-existing-subnet"

  # Required parameters
  cluster_name            = "MyCluster"
  gw_image_name           = "cp-gateway.qcow2"
  gw_external_subnet_name = "MY-EXTERNAL-SUBNET"
  gw_internal_subnet_name = "MY-INTERNAL-SUBNET"

  # Optional overrides
  gw_name                 = "TF-GW"
  gw_description          = "Terraform Deployed CloudGuard Gateway"
  gw_num_cpus             = 2
  gw_num_cores_per_socket = 1
  gw_memory_in_gb         = 8
  gw_disk_size_in_gb = 100

  # Optional user-data file path (absolute) for cloud-init customization
  gw_user_data_file_path = "C:/terraform/userdata/gw_cloud_init"
}
```

## Inputs (Variables)

| Name                    | Type   | Required | Default                                                  | Description                                                                             |
|-------------------------|--------|----------|----------------------------------------------------------|-----------------------------------------------------------------------------------------|
| cluster_name            | string | **yes**  | -                                                        | Name of the Nutanix cluster registered in Prism Central.                                |
| gw_external_subnet_name | string | **yes**  | -                                                        | Name of existing external (WAN / uplink) Nutanix subnet for the first Gateway NIC.      |
| gw_internal_subnet_name | string | **yes**  | -                                                        | Name of existing internal (LAN / trusted) Nutanix subnet for the second Gateway NIC.    |
| gw_image_name           | string | **yes**  | -                                                        | QCOW2 image name for the Security Gateway in Nutanix image library.                     |
| gw_name                 | string | no       | "TF-GW"                                                  | Gateway VM name.                                                                        |
| gw_description          | string | no       | "Check Point CloudGuard Gateway VM created by Terraform" | Gateway VM description.                                                                 |
| gw_num_cpus             | number | no       | 2                                                        | Number of CPU sockets for the Gateway (>=2).                                            |
| gw_num_cores_per_socket | number | no       | 1                                                        | Number of cores per socket (>=1).                                                       |
| gw_memory_in_gb         | number | no       | 8                                                        | Gateway memory size in GB (>=4, 8 recommended).                                         |
| gw_disk_size_in_gb      | number | no       | 100                                                      | Gateway disk size in GB (>=50, 100 recommended).                                        |
| gw_user_data_file_path  | string | no       | ""                                                       | Absolute path to user‑data (cloud‑init) file. If empty, guest customization is skipped. |

## Outputs

| Name                | Description                                    |
|---------------------|------------------------------------------------|
| gateway_vm_name     | Name of the deployed CloudGuard Gateway VM     |
| gateway_vm_id       | ID (ext_id) of the deployed Gateway VM         |
| gateway_power_state | Current power state of the deployed Gateway VM |

## References

- [Check Point CloudGuard Private Cloud Images (SK158292)](https://support.checkpoint.com/results/sk/sk158292)
- [sk179752 – How to configure cloud-init](https://support.checkpoint.com/results/sk/sk179752)
- [Terraform Nutanix Provider Docs](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs)
- [Check Point CloudGuard Network Security Documentation](https://sc1.checkpoint.com)
