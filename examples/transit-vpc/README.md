# Check Point CloudGuard Transit VPC Example (Nutanix)

This Terraform example deploys a full Check Point CloudGuard Network Security Transit VPC environment on Nutanix Prism
Central and two attached Tenant VPCs to demonstrate a hub-and-spoke (transit) topology. It provisions the security
management plane, a ClusterXL high‑availability gateway pair inside the Transit VPC, a dedicated transit-to-tenant
subnet, and two sample tenant VPCs (A & B) that route north/south and east/west traffic via the transit security layer.

## Architecture Overview

Components provisioned by this example:

1. Transit VPC with external subnet association
2. Three overlay subnets inside Transit VPC:
    - Management Interface subnet (MGMT)
    - Data / External Interface subnet (DATA)
    - HA / Sync Interface subnet (HA)
3. A dedicated overlay subnet (transit-to-tenant) for attaching downstream tenant VPCs
4. Two simple Tenant VPCs (A & B) each with one overlay subnet
5. **Policy Based Routing** (PBR) in Transit VPC to reroute specified networks to the ClusterXL Virtual IP
6. CloudGuard Network Security Management Server VM (legacy boot, QCOW2 image)
7. Two CloudGuard Security Gateway VMs (ClusterXL members) with three NICs (MGMT/DATA/HA)
8. Cloud‑Init (config drive) customization for first boot for management and both gateways
9. Floating IPs bound to the first NIC (MGMT) of Management, member 1, and member 2

The two sample tenant VPCs emulate spokes; their default routes point toward the transit subnet, enabling centralized
inspection. Adjust, extend, or remove tenant VPC creation if integrating with existing environments.

## Prerequisites

| Item                  | Description                                                                                                                                                                             |
|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Nutanix Prism Central | API credentials with permissions to create VPCs, subnets, VMs, floating IPs, static routes, and policy based routing                                                                    |
| Images                | R81.20+ Images, uploaded QCOW2 images for Management ("All deployment types") and Gateway ("Security Gateway only") from [SK158292](https://support.checkpoint.com/results/sk/sk158292) |
| Terraform             | v1.10.5+ **64Bit** version                                                                                                                                                              |
| Nutanix Provider      | `nutanix/nutanix` >= 2.3.1                                                                                                                                                              |
| External Subnet       | Existing external subnet supplying egress and floating IP association                                                                                                                   |
| Static IP plan        | IP allocations for: 3 internal transit subnets (MGMT/DATA/HA)                                                                                                                           |

## Post‑deployment configuration:

- Configure ClusterXL object in
  SmartConsole - [How to add clusterXL to security management](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Network_for_Nutanix_DG/Content/Topics-Nutanix-DG-R81-10-Higher/Gateway-Deployment-HA-Transit-VPC.htm?tocpath=_____5#:~:text=Connect%20to%20the%20server%20in%20SmartConsole%20and%20create%20a%20Legacy%20ClusterXL%20cluster.)
-
Licensing - [CloudGuard Network Central License Tool Administration Guide](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Central_License_Tool_Admin_Guide/Content/Front-Matter/Front-Matter-Important-Information-Central-License-Tool.htm?tocpath=_____1)
- Single ClusterXL VIP variable (`clusterXL_virtual_ip`) pertains to the Data subnet; ensure alignment with chosen CIDR.
- Security Policies; you must define access/Threat Prevention policy after deployment.

## Usage

Follow best practices for using CGNS examples
on [main readme.md file](https://registry.terraform.io/modules/CheckPointSW/cloudguard-network-security/nutanix/latest).

## Example Usage

```hcl
provider "nutanix" {}

module "transit_vpc" {
  source = "CheckPointSW/cloudguard-network-security/nutanix//examples/transit-vpc"

  #Required parameters
  cluster_name              = "MyCluster"
  external_subnet_name      = "External-Network"
  mgmt_image_name           = "cp-mgmt.qcow2"
  gw_image_name             = "cp-gw.qcow2"
  mgmt_admin_password       = "AdminPassword123!"
  mgmt_maintenance_password = "MaintPassword123!"
  gw_admin_password         = "GwAdminPassword123!"
  gw_maintenance_password   = "GwMaintPassword123!"
  ftw_sic                   = "MyStrongSICKey123!"


  transit_vpc_name = "TF-Transit-VPC"
  tenant_vpc_name  = "TF-Tenant-VPC"
  dns_ip           = ""
  ntp_server       = "pool.ntp.org"

  clusterXL_virtual_ip = "172.16.20.20"
  network_to_reroute   = "192.168.0.0/23"
  
  transit_subnets = {
    mgmt = {
      name            = "TF-Transit-VPC-MGMT"
      cidr_block      = "172.16.10.0/24"
      default_gateway = "172.16.10.1"
      ip_start_range  = "172.16.10.10"
      ip_end_range    = "172.16.10.200"
      mgmt_ip         = "172.16.10.10"
      member1_ip      = "172.16.10.11"
      member2_ip      = "172.16.10.12"
    }
    data = {
      name            = "TF-Transit-VPC-DATA"
      cidr_block      = "172.16.20.0/24"
      default_gateway = "172.16.20.1"
      ip_start_range  = "172.16.20.10"
      ip_end_range    = "172.16.20.200"
      member1_ip      = "172.16.20.11"
      member2_ip      = "172.16.20.12"
    }
    ha = {
      name            = "TF-Transit-VPC-HA"
      cidr_block      = "172.16.30.0/24"
      default_gateway = "172.16.30.1"
      ip_start_range  = "172.16.30.10"
      ip_end_range    = "172.16.30.200"
      member1_ip      = "172.16.30.11"
      member2_ip      = "172.16.30.12"
    }
  }

  transit_to_tenant_subnet = {
    name            = "TF-Transit-VPC-Subnet"
    cidr_block      = "172.16.200.0/24"
    default_gateway = "172.16.200.1"
    ip_start_range  = "172.16.200.10"
    ip_end_range    = "172.16.200.200"
  }

  tenant_vpcs_subnets = {
    vpc_A = {
      name            = "TF-Subnet-192.169.0.0"
      cidr_block      = "192.169.0.0/24"
      default_gateway = "192.169.0.1"
      ip_start_range  = "192.169.0.10"
      ip_end_range    = "192.169.0.200"
    }
    vpc_B = {
      name            = "TF-Subnet-192.169.1.0"
      cidr_block      = "192.169.1.0/24"
      default_gateway = "192.169.1.1"
      ip_start_range  = "192.169.1.10"
      ip_end_range    = "192.169.1.200"
    }
  }
}
```

## Inputs (Variables)

| Name                                                        | Type        | Required    | Default                                     | Description                                                                         |
|-------------------------------------------------------------|-------------|-------------|---------------------------------------------|-------------------------------------------------------------------------------------|
| transit_vpc_name                                            | string      | no          | "TF-Transit-VPC"                            | Transit VPC name.                                                                   |
| tenant_vpc_name                                             | string      | no          | "TF-Tenant-VPC"                             | Base name used for sample tenant VPCs (A & B).                                      |
| cluster_name                                                | string      | **yes**     | -                                           | Name of the Nutanix cluster registered in Prism Central.                            |
| external_subnet_name                                        | string      | **yes**     | -                                           | Existing external subnet to attach to the VPC.                                      |
| transit_subnets                                             | map(object) | no          | see example                                 | Map of mgmt, data and ha subnets with static IP reservations.                       |
| transit_to_tenant_subnet                                    | object      | no          | see example                                 | Subnet bridging transit VPC to downstream tenant VPCs.                              |
| tenant_vpcs_subnets                                         | map(object) | no          | see example                                 | Map defining single overlay subnet per sample tenant VPC (A & B).                   |
| dns_ip                                                      | string      | no          | ""                                          | Optional DNS server IPv4. If empty, no DHCP DNS options are configured.             |
| ntp_server                                                  | string      | no          | pool.ntp.org                                | NTP server hostname or IPv4 address.                                                |
| ntp_version                                                 | number      | no          | 4                                           | NTP protocol version (default: 4).                                                  |
| clusterXL_virtual_ip                                        | string      | no          | 172.16.20.20                                | ClusterXL virtual IP on the data interface (data subnet).                           |
| network_to_reroute                                          | string      | no          | 192.168.0.0/23                              | CIDR network to reroute to the ClusterXL virtual IP.                                |
| policy_routing_priority                                     | number      | no          | 20                                          | Priority of the Policy Based Routing rule (higher value = higher priority).         |
| mgmt_name                                                   | string      | no          | "TF-Transit-VPC-MGMT"                       | Management Server VM name.                                                          |
| mgmt_description                                            | string      | no          | "Management Server VM created by Terraform" | Management Server VM description.                                                   |
| mgmt_image_name                                             | string      | **yes**     | -                                           | QCOW2 image name for the Management Server in Nutanix image library.                |
| deploy_management                                           | bool        | no          | true                                        | Whether to deploy the Management Server (set false to skip).                        |
| mgmt_num_cpus                                               | number      | no          | 2                                           | Number of CPU sockets for the Management Server (>=2).                              |
| mgmt_num_cores_per_socket                                   | number      | no          | 1                                           | Number of cores per socket for the Management Server (>=1).                         |
| mgmt_memory_in_gb                                           | number      | no          | 8                                           | Management Server memory size in GB (>=8 recommended).                              |
| mgmt_disk_size_in_gb                                        | number      | no          | 100                                         | Management Server disk size in GB (>=50, 100 recommended).                          |
| mgmt_admin_password                                         | string      | conditional | -                                           | Management Server admin password (required only when deploy_management=true).       |
| mgmt_maintenance_password                                   | string      | conditional | -                                           | Management Server maintenance password (required only when deploy_management=true). |
| mgmt_admin_shell                                            | string      | no          | "/etc/cli.sh"                               | Admin shell for the Management Server.                                              |
| gw_name                                                     | string      | no          | "TF-Transit-VPC-GW"                         | Base name for Security Gateway cluster members.                                     |
| gw_description                                              | string      | no          | "Security Gateway VM created by Terraform"  | Security Gateway VM description.                                                    |
| gw_image_name                                               | string      | **yes**     | -                                           | QCOW2 image name for the Security Gateway in Nutanix image library.                 |
| gw_admin_password                                           | string      | **yes**     | -                                           | Security Gateway admin password (>=6 alphanumeric characters).                      |
| gw_maintenance_password                                     | string      | **yes**     | -                                           | Security Gateway maintenance password (>=6 alphanumeric characters).                |
| member1_num_cpus / member2_num_cpus                         | number      | no          | 2                                           | Number of CPU sockets for gateway members (>=2).                                    |
| member1_num_cores_per_socket / member2_num_cores_per_socket | number      | no          | 1                                           | Number of cores per socket for gateway members (>=1).                               |
| member1_memory_in_gb / member2_memory_in_gb                 | number      | no          | 8                                           | Gateway member memory size in GB (>=8 recommended).                                 |
| member1_disk_size_in_gb / member2_disk_size_in_gb           | number      | no          | 100                                         | Gateway member disk size in GB (>=50, 100 recommended).                             |
| member1_admin_shell / member2_admin_shell                   | string      | no          | "/etc/cli.sh"                               | Admin shell for gateway members.                                                    |
| ftw_sic                                                     | string      | **yes**     | -                                           | Secure Internal Communication (SIC) key (>=8 alphanumeric characters).              |

## References

- [Check Point CloudGuard Private Cloud Images (SK158292)](https://support.checkpoint.com/results/sk/sk158292)
- [CloudGuard Network Security for Nutanix - Recommended Topologies](https://support.checkpoint.com/results/sk/sk182972)
- [CloudGuard for Nutanix Deployment Guide](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Network_for_Nutanix_DG/Content/Front-Matter/Front-Matter-How-to-Search-in-this-Book.htm)
- [Terraform Nutanix Provider Docs](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs)

## Outputs

| Name | Description |
|------|-------------|
| `management_vm_name` | Name of the Management VM deployed in the Transit VPC. |
| `gateway_member1_name` | Name of the first ClusterXL gateway member. |
| `gateway_member2_name` | Name of the second ClusterXL gateway member. |
| `clusterXL_virtual_ip` | ClusterXL Virtual IP (data interface) used for Policy Based Routing. |
| `network_to_reroute` | Network CIDR that is rerouted to the ClusterXL Virtual IP. |

