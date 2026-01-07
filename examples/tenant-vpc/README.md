# Check Point CloudGuard Tenant VPC Example (Nutanix)

This Terraform example deploys a complete Check Point CloudGuard Network Security Tenant VPC environment on Nutanix Prism
Central:

- CloudGuard Network Security Management Server
- Two CloudGuard Network Security ClusterXL (2 members)
- VPC with 3 overlay subnets (Management, Data/External, HA/Sync)
- Static IP assignment per interface
- Floating IPs for management and both gateways

## Architecture Overview

Components provisioned:

1. VPC with external subnet association
2. Three overlay subnets:
    - Management Interface
    - Data / External Interface
    - HA / Sync Interface
3. Management VM (Legacy boot, QCOW2 image)
4. Two ClusterXL members with three NICs
5. Cloud‑Init (config drive) customization for first boot
6. Floating IPs bound management interface and both gateways

## Prerequisites

| Item                  | Description                                                                                                                                                                             |
|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Nutanix Prism Central | API credentials with permissions to create VPCs, subnets, VMs, floating IPs                                                                                                             |
| Images                | R81.20+ Images, Uploaded QCOW2 images for Management ("All deployment types") and Gateway ("Security Gateway only") from [SK158292](https://support.checkpoint.com/results/sk/sk158292) |
| Terraform             | v1.10.5+ **64Bit** version                                                                                                                                                              |
| Nutanix Provider      | `nutanix/nutanix` >= 2.3.1                                                                                                                                                              |
| Static IP plan        | 4 IPs: One external IP allocated for the VPC plus three additional free external IPs for floating IPs (management, member1, member2)                                                    |

## Post‑deployment configuration:

After creation, further configuration is required:
  - Configure ClusterXL object in SmartConsole - [How to add clusterXL to security management](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Network_for_Nutanix_DG/Content/Topics-Nutanix-DG-R81-10-Higher/Gateway-Deployment-HA-Transit-VPC.htm?tocpath=_____5#:~:text=Connect%20to%20the%20server%20in%20SmartConsole%20and%20create%20a%20Legacy%20ClusterXL%20cluster.)
  - Licensing - [CloudGuard Network Central License Tool Administration Guide](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Central_License_Tool_Admin_Guide/Content/Front-Matter/Front-Matter-Important-Information-Central-License-Tool.htm?tocpath=_____1)
  - Single ClusterXL VIP variable (`clusterXL_virtual_ip`) pertains to the Data subnet; ensure alignment with chosen CIDR.
  - Security Policies; you must define access/Threat Prevention policy after deployment.

## Usage

Follow best practices for using CGNS examples
on [main readme.md file](https://registry.terraform.io/modules/CheckPointSW/cloudguard-network-security/nutanix/latest).

## Example Usage

```hcl
provider "nutanix" {}

module "tenant_vpc" {
  source = "CheckPointSW/cloudguard-network-security/nutanix//examples/tenant-vpc"

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

  
  tenant_vpc_name = "TF-Tenant-VPC"
  dns_ip          = ""
  ntp_server      = "pool.ntp.org"

  clusterXL_virtual_ip = "172.16.20.20"
  network_to_reroute = "192.168.100.0/22"
  mgmt_admin_shell = "/bin/bash"
  

  subnets = {
    mgmt = {
      name            = "TF-Tenant-VPC-MGMT"
      cidr_block      = "172.16.10.0/24"
      default_gateway = "172.16.10.1"
      ip_start_range  = "172.16.10.10"
      ip_end_range    = "172.16.10.200"
      mgmt_ip         = "172.16.10.10"
      member1_ip      = "172.16.10.11"
      member2_ip      = "172.16.10.12"
    }
    data = {
      name            = "TF-Tenant-VPC-DATA"
      cidr_block      = "172.16.20.0/24"
      default_gateway = "172.16.20.1"
      ip_start_range  = "172.16.20.10"
      ip_end_range    = "172.16.20.200"
      member1_ip      = "172.16.20.11"
      member2_ip      = "172.16.20.12"
    }
    ha = {
      name            = "TF-Tenant-VPC-HA"
      cidr_block      = "172.16.30.0/24"
      default_gateway = "172.16.30.1"
      ip_start_range  = "172.16.30.10"
      ip_end_range    = "172.16.30.200"
      member1_ip      = "172.16.30.11"
      member2_ip      = "172.16.30.12"
    }
  }
  
  set_clients_subnets = true
  client_subnet_1 = {
    name            = "TF-Subnet-192.168.100.0"
    cidr_block      = "192.168.100.0/24"
    default_gateway = "192.168.100.1"
    ip_start_range  = "192.168.100.10"
    ip_end_range    = "192.168.100.200"
  }
  client_subnet_2 = {
    name            = "TF-Subnet-192.168.101.0"
    cidr_block      = "192.168.101.0/24"
    default_gateway = "192.168.101.1"
    ip_start_range  = "192.168.101.10"
    ip_end_range    = "192.168.101.200"
  }
}
```

## Inputs (Variables)

| Name                                                        | Type        | Required    | Default                                                            | Description                                                                         |
|-------------------------------------------------------------|-------------|-------------|--------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| tenant_vpc_name                                             | string      | no          | "TF-Tenant-VPC"                                                    | Tenant VPC name.                                                                    |
| cluster_name                                                | string      | **yes**     | -                                                                  | Name of the Nutanix cluster registered in Prism Central.                            |
| external_subnet_name                                        | string      | **yes**     | -                                                                  | Existing external subnet to attach to the VPC.                                      |
| subnets                                                     | map(object) | no          | see example                                                        | Map of mgmt, data and ha subnets with static IP reservations.                       |
| dns_ip                                                      | string      | no          | ""                                                                 | Optional DNS server IPv4. If empty, no DHCP DNS options are configured.             |
| ntp_server                                                  | string      | no          | pool.ntp.org                                                       | NTP server hostname or IPv4 address.                                                |
| ntp_version                                                 | number      | no          | 4                                                                  | NTP protocol version (default: 4).                                                  |
| clusterXL_virtual_ip                                        | string      | no          | see example                                                        | ClusterXL virtual IP on the data interface (data subnet).                           |
| network_to_reroute                                          | string      | no          | see example                                                        | CIDR network to reroute to the ClusterXL virtual IP.                                |
| policy_routing_priority                                     | number      | no          | 20                                                                 | Priority of the Policy Based Routing rule (higher value = higher priority).         |
| mgmt_name                                                   | string      | no          | "TF-Tenant-VPC-MGMT"                                               | Management Server VM name.                                                          |
| mgmt_description                                            | string      | no          | "Check Point CloudGuard Management Server VM created by Terraform" | Management Server VM description.                                                   |
| mgmt_image_name                                             | string      | **yes**     | -                                                                  | QCOW2 image name for the Management Server in Nutanix image library.                |
| deploy_management                                           | bool        | no          | true                                                               | Whether to deploy the Management Server (set false to skip).                        |
| mgmt_num_cpus                                               | number      | no          | 2                                                                  | Number of CPU sockets for the Management Server (>=2).                              |
| mgmt_num_cores_per_socket                                   | number      | no          | 1                                                                  | Number of cores per socket for the Management Server (>=1).                         |
| mgmt_memory_in_gb                                           | number      | no          | 8                                                                  | Management Server memory size in GB (>=8 recommended).                              |
| mgmt_disk_size_in_gb                                        | number      | no          | 100                                                                | Management Server disk size in GB (>=50, 100 recommended).                          |
| mgmt_admin_password                                         | string      | conditional | -                                                                  | Management Server admin password (required only when deploy_management=true).       |
| mgmt_maintenance_password                                   | string      | conditional | -                                                                  | Management Server maintenance password (required only when deploy_management=true). |
| mgmt_admin_shell                                            | string      | no          | "/etc/cli.sh"                                                      | Admin shell for the Management Server.                                              |
| gw_admin_password                                           | string      | **yes**     | -                                                                  | Security Gateway admin password (>=6 alphanumeric characters).                      |
| gw_maintenance_password                                     | string      | **yes**     | -                                                                  | Security Gateway maintenance password (>=6 alphanumeric characters).                |
| ftw_sic                                                     | string      | **yes**     | -                                                                  | Secure Internal Communication (SIC) key (>=8 alphanumeric characters).              |
| gw_name                                                     | string      | no          | "TF-Tenant-VPC-GW"                                                 | Base name for Security Gateway cluster members.                                     |
| gw_description                                              | string      | no          | "Security Gateway VM created by Terraform"                         | Security Gateway VM description.                                                    |
| gw_image_name                                               | string      | **yes**     | -                                                                  | QCOW2 image name for the Security Gateway in Nutanix image library.                 |
| member1_num_cpus / member2_num_cpus                         | number      | no          | 2                                                                  | Number of CPU sockets for gateway members (>=2).                                    |
| member1_num_cores_per_socket / member2_num_cores_per_socket | number      | no          | 1                                                                  | Number of cores per socket for gateway members (>=1).                               |
| member1_memory_in_gb / member2_memory_in_gb                 | number      | no          | 8                                                                  | Gateway member memory size in GB (>=8 recommended).                                 |
| member1_disk_size_in_gb / member2_disk_size_in_gb           | number      | no          | 100                                                                | Gateway member disk size in GB (>=50, 100 recommended).                             |
| member1_admin_shell / member2_admin_shell                   | string      | no          | "/etc/cli.sh"                                                      | Admin shell for gateway members.                                                    |
| set_clients_subnets                                         | boolean     | no          | true                                                               | Whether to create client_subnet_1 and client_subnet_2 objects.                      |
| client_subnet_1 / client_subnet_2                           | object      | no          | see example                                                        | Optional client overlay subnet objects created behind the Tenant VPC.               |

## References

- [Check Point CloudGuard Private Cloud Images (SK158292)](https://support.checkpoint.com/results/sk/sk158292)
- [CloudGuard Network Security for Nutanix - Recommended Topologies](https://support.checkpoint.com/results/sk/sk182972)
- [CloudGuard for Nutanix Deployment Guide](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Network_for_Nutanix_DG/Content/Front-Matter/Front-Matter-How-to-Search-in-this-Book.htm)
- [Terraform Nutanix Provider Docs](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs)

## Outputs

| Name                   | Description                                                                                        |
|------------------------|----------------------------------------------------------------------------------------------------|
| `management_vm_name`   | Name of the Management VM deployed in the Tenant VPC.                                              |
| `gateway_member1_name` | Name of the first ClusterXL gateway member.                                                        |
| `gateway_member2_name` | Name of the second ClusterXL gateway member.                                                       |
| `clusterXL_virtual_ip` | ClusterXL Virtual IP (data interface) used for Policy Based Routing or static routing.             |
| `network_to_reroute`   | Network CIDR that is rerouted to the ClusterXL Virtual IP (if Policy Based Routing is configured). |

