
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
  mgmt_admin_password       = "[Credentials]"
  mgmt_maintenance_password = "[Credentials]"
  gw_admin_password         = "[Credentials]"
  gw_maintenance_password   = "[Credentials]"
  ftw_sic                   = "[Credentials]"


  
  tenant_vpc_name = "TF-Tenant-VPC"
  dns_ip          = ""
  ntp_server      = "pool.ntp.org"


  clusterXL_virtual_ip = "172.16.20.20"
  network_to_reroute = "192.168.100.0/22"
  mgmt_admin_shell = "/etc/cli.sh"
  


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
