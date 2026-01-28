##### Data Sources #######
data "nutanix_subnet" "external_subnet" {
  subnet_name = var.external_subnet_name
}

data "nutanix_cluster" "cluster" {
  name = var.cluster_name
}

data "nutanix_image" "gw_image" {
  image_name = var.gw_image_name
}

data "nutanix_image" "mgmt_image" {
  count      = var.deploy_management ? 1 : 0
  image_name = var.mgmt_image_name
}

resource "htpasswd_password" "mgmt_password" {
  count    = var.deploy_management ? 1 : 0
  password = var.mgmt_maintenance_password
}

##### Locals #######

locals {
  maintenance_hash = var.deploy_management ? replace(try(htpasswd_password.mgmt_password[0].sha512, "placeholder"), "$", "\\$") : null

  mgmt_userdata = var.deploy_management ? templatefile("${path.module}/cloud_config/mgmt_cloud_config.yaml", {
    mgmt_admin_password      = var.mgmt_admin_password
    ftw_sic                  = var.ftw_sic
    hostname                 = var.mgmt_name
    ntp_server               = var.ntp_server
    ntp_version              = var.ntp_version
    maintenance_hash         = local.maintenance_hash
    admin_shell              = var.mgmt_admin_shell
    admin_password_duplicate = var.mgmt_admin_password
  }) : null

  member1_userdata = templatefile("${path.module}/cloud_config/gw_cloud_config.yaml", {
    admin_password      = var.gw_admin_password
    maintenance_password= var.gw_maintenance_password
    ftw_sic             = var.ftw_sic
    hostname            = format("%s-1", var.gw_name)
    admin_shell         = var.member1_admin_shell
    mgmt_gateway        = var.transit_subnets["mgmt"].default_gateway
    data_gateway        = var.transit_subnets["data"].default_gateway
    ntp_server          = var.ntp_server
  })

  member2_userdata = templatefile("${path.module}/cloud_config/gw_cloud_config.yaml", {
    admin_password      = var.gw_admin_password
    maintenance_password= var.gw_maintenance_password
    ftw_sic             = var.ftw_sic
    hostname            = format("%s-2", var.gw_name)
    admin_shell         = var.member2_admin_shell
    mgmt_gateway        = var.transit_subnets["mgmt"].default_gateway
    data_gateway        = var.transit_subnets["data"].default_gateway
    ha_ip               = var.transit_subnets["ha"].member2_ip
    ntp_server          = var.ntp_server
  })

}

###### Resources #######

resource "nutanix_vpc_v2" "transit_vpc" {
  name        = var.transit_vpc_name
  description = "Transit VPC created by Terraform"
  vpc_type    = "TRANSIT"

  external_subnets {
    subnet_reference     = data.nutanix_subnet.external_subnet.id
    active_gateway_count = 1 # Number of active gateways for the external subnet
  }
  dynamic "common_dhcp_options" {
    for_each = var.dns_ip != "" ? [var.dns_ip] : []
    content {
      domain_name_servers {
        ipv4 {
          value = common_dhcp_options.value
        }
      }
    }
  }

}



resource "nutanix_subnet_v2" "transit_vpc_subnets" {
  for_each      = { for s in var.transit_subnets : s.name => s }
  name          = each.value.name
  description   = "Subnet ${each.value.name} managed by Terraform"
  vpc_reference = nutanix_vpc_v2.transit_vpc.id
  subnet_type   = "OVERLAY"
  ip_config {
    ipv4 {
      ip_subnet {
        ip {
          value = split("/", each.value.cidr_block)[0]
        }
        prefix_length = tonumber(split("/", each.value.cidr_block)[1])
      }
      default_gateway_ip {
        value = each.value.default_gateway
      }
      pool_list {
        start_ip {
          value = each.value.ip_start_range
        }
        end_ip {
          value = each.value.ip_end_range
        }
      }
    }
  }
}
resource "nutanix_subnet_v2" "transit_subnet_for_tenant_vpcs" {
  name           = var.transit_to_tenant_subnet.name
  description    = "Subnet ${var.transit_to_tenant_subnet.name} managed by Terraform"
  vpc_reference  = nutanix_vpc_v2.transit_vpc.id
  subnet_type    = "OVERLAY"
  is_external    = true
  is_nat_enabled = false
  ip_config {
    ipv4 {
      ip_subnet {
        ip {
          value = split("/", var.transit_to_tenant_subnet.cidr_block)[0]
        }
        prefix_length = tonumber(split("/", var.transit_to_tenant_subnet.cidr_block)[1])
      }
      default_gateway_ip {
        value = var.transit_to_tenant_subnet.default_gateway
      }
      pool_list {
        start_ip {
          value = var.transit_to_tenant_subnet.ip_start_range
        }
        end_ip {
          value = var.transit_to_tenant_subnet.ip_end_range
        }
      }
    }
  }
}

resource "nutanix_vpc_v2" "tenant_vpc_A" {
  name        = format("%s-A", var.tenant_vpc_name)
  description = "Tenant VPC created by Terraform"
  vpc_type    = "REGULAR"

  external_subnets {
    subnet_reference     = nutanix_subnet_v2.transit_subnet_for_tenant_vpcs.ext_id
    active_gateway_count = 1 # Number of active gateways for the external subnet
  }
  externally_routable_prefixes {
    ipv4 {
      ip {
        value = split("/", var.tenant_vpcs_subnets["vpc_A"].cidr_block)[0]
      }
      prefix_length = tonumber(split("/", var.tenant_vpcs_subnets["vpc_A"].cidr_block)[1])
    }
  }
  dynamic "common_dhcp_options" {
    for_each = var.dns_ip != "" ? [var.dns_ip] : []
    content {
      domain_name_servers {
        ipv4 {
          value = common_dhcp_options.value
        }
      }
    }
  }
  depends_on = [
    nutanix_subnet_v2.transit_subnet_for_tenant_vpcs,
  nutanix_vpc_v2.transit_vpc]
}

resource "nutanix_subnet_v2" "tenant_subnet_vpc_A" {
  name          = var.tenant_vpcs_subnets["vpc_A"].name
  description   = "Subnet ${var.tenant_vpcs_subnets["vpc_A"].name} managed by Terraform"
  vpc_reference = nutanix_vpc_v2.tenant_vpc_A.ext_id
  subnet_type   = "OVERLAY"
  ip_config {
    ipv4 {
      ip_subnet {
        ip {
          value = split("/", var.tenant_vpcs_subnets["vpc_A"].cidr_block)[0]
        }
        prefix_length = tonumber(split("/", var.tenant_vpcs_subnets["vpc_A"].cidr_block)[1])
      }
      default_gateway_ip {
        value = var.tenant_vpcs_subnets["vpc_A"].default_gateway
      }
      pool_list {
        start_ip {
          value = var.tenant_vpcs_subnets["vpc_A"].ip_start_range
        }
        end_ip {
          value = var.tenant_vpcs_subnets["vpc_A"].ip_end_range
        }
      }
    }
  }
  depends_on = [nutanix_vpc_v2.tenant_vpc_A]
}

resource "nutanix_vpc_v2" "tenant_vpc_B" {
  name        = format("%s-B", var.tenant_vpc_name)
  description = "Tenant VPC created by Terraform"
  vpc_type    = "REGULAR"

  external_subnets {
    subnet_reference     = nutanix_subnet_v2.transit_subnet_for_tenant_vpcs.ext_id
    active_gateway_count = 1 # Number of active gateways for the external subnet
  }
  externally_routable_prefixes {
    ipv4 {
      ip {
        value = split("/", var.tenant_vpcs_subnets["vpc_B"].cidr_block)[0]
      }
      prefix_length = tonumber(split("/", var.tenant_vpcs_subnets["vpc_B"].cidr_block)[1])
    }
  }
  dynamic "common_dhcp_options" {
    for_each = var.dns_ip != "" ? [var.dns_ip] : []
    content {
      domain_name_servers {
        ipv4 {
          value = common_dhcp_options.value
        }
      }
    }
  }
  depends_on = [
    nutanix_subnet_v2.transit_subnet_for_tenant_vpcs,
  nutanix_vpc_v2.transit_vpc]
}

resource "nutanix_subnet_v2" "tenant_subnet_vpc_B" {
  name          = var.tenant_vpcs_subnets["vpc_B"].name
  description   = "Subnet ${var.tenant_vpcs_subnets["vpc_B"].name} managed by Terraform"
  vpc_reference = nutanix_vpc_v2.tenant_vpc_B.id
  subnet_type   = "OVERLAY"
  ip_config {
    ipv4 {
      ip_subnet {
        ip {
          value = split("/", var.tenant_vpcs_subnets["vpc_B"].cidr_block)[0]
        }
        prefix_length = tonumber(split("/", var.tenant_vpcs_subnets["vpc_B"].cidr_block)[1])
      }
      default_gateway_ip {
        value = var.tenant_vpcs_subnets["vpc_B"].default_gateway
      }
      pool_list {
        start_ip {
          value = var.tenant_vpcs_subnets["vpc_B"].ip_start_range
        }
        end_ip {
          value = var.tenant_vpcs_subnets["vpc_B"].ip_end_range
        }
      }
    }
  }
  depends_on = [nutanix_vpc_v2.tenant_vpc_B]
}


resource "nutanix_static_routes" "scn_transit_vpc" {
  vpc_uuid = nutanix_vpc_v2.transit_vpc.id

  static_routes_list {
    destination = "0.0.0.0/0"
    # required ext subnet uuid for next hop
    external_subnet_reference_uuid = data.nutanix_subnet.external_subnet.id
  }
}

resource "nutanix_static_routes" "scn_tenant_vpc_A" {
  vpc_uuid = nutanix_vpc_v2.tenant_vpc_A.ext_id

  static_routes_list {
    destination = "0.0.0.0/0"
    # required ext subnet uuid for next hop
    external_subnet_reference_uuid = nutanix_subnet_v2.transit_subnet_for_tenant_vpcs.ext_id
  }
}

resource "nutanix_static_routes" "scn_tenant_vpc_B" {
  vpc_uuid = nutanix_vpc_v2.tenant_vpc_B.ext_id

  static_routes_list {
    destination = "0.0.0.0/0"
    # required ext subnet uuid for next hop
    external_subnet_reference_uuid = nutanix_subnet_v2.transit_subnet_for_tenant_vpcs.ext_id
  }
}

resource "nutanix_pbr_v2" "policy_base_routing_transit_vpc" {
  name        = "Policy Routing Transit-VPC"
  description = "Policy Base Routing for transit VPC to route traffic to ClusterXL VIP."
  priority    = var.policy_routing_priority
  vpc_ext_id  = nutanix_vpc_v2.transit_vpc.id
  policies {
    policy_match {
      source {
        address_type = "SUBNET"
        subnet_prefix {
          ipv4 {
            ip {
              value         = split("/", var.network_to_reroute)[0]
              prefix_length = split("/", var.network_to_reroute)[1]
            }
          }
        }
      }
      destination {
        address_type = "ANY"
      }
      protocol_type = "ANY"
    }
    policy_action {
      action_type = "REROUTE"
      reroute_params {
        reroute_fallback_action = "NO_ACTION"
        service_ip {
          ipv4 {
            value = var.clusterXL_virtual_ip
          }
        }
      }
    }
    is_bidirectional = true
  }
  depends_on = [
    nutanix_vpc_v2.transit_vpc,
    nutanix_subnet_v2.transit_vpc_subnets
  ]
}

resource "nutanix_virtual_machine_v2" "mgmt_vm" {
  count                = var.deploy_management ? 1 : 0
  name                 = var.mgmt_name
  description          = var.mgmt_description != "" ? var.mgmt_description : ""
  num_sockets          = var.mgmt_num_cpus != 2 ? var.mgmt_num_cpus : 2
  num_cores_per_socket = var.mgmt_num_cores_per_socket != 1 ? var.mgmt_num_cores_per_socket : 1

  memory_size_bytes = (var.mgmt_memory_in_gb != 0 ? var.mgmt_memory_in_gb : 8) * pow(1024, 3)
  cluster {
    ext_id = data.nutanix_cluster.cluster.id
  }

  /*
  Indicates whether the VM is an agent VM or not. When their host enters maintenance mode, once the normal
   VMs are evacuated, the agent VMs are powered off. When the host is restored, agent VMs are powered on
    before the normal VMs are restored. In other words, agent VMs cannot be HA-protected or live migrated.
  */
  is_agent_vm = true

  dynamic "guest_customization" {
    for_each = var.deploy_management ? [1] : []
    content {
      config {
        cloud_init {
          cloud_init_script {
            user_data {
              value = base64encode(local.mgmt_userdata != null && local.mgmt_userdata != "" ? local.mgmt_userdata : "#cloud-config\n")
            }
          }
        }
      }
    }
  }

  boot_config {
    legacy_boot {
      boot_order = ["DISK", "CDROM", "NETWORK"]
    }
  }

  disks {
    disk_address {
      bus_type = "SCSI"
      index    = 0
    }
    backing_info {
      vm_disk {
        disk_size_bytes = (var.mgmt_disk_size_in_gb != 0 ? var.mgmt_disk_size_in_gb : 100) * pow(1024, 3)
        data_source {
          reference {
            image_reference {
              image_ext_id = data.nutanix_image.mgmt_image[0].id
            }
          }
        }
      }
    }
  }

  nics {
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = nutanix_subnet_v2.transit_vpc_subnets[var.transit_subnets["mgmt"].name].id
      }
      ipv4_config {
        should_assign_ip = true
        ip_address {
          value = var.transit_subnets["mgmt"].mgmt_ip
        }
      }
    }
  }

  power_state = "ON"
  depends_on  = [nutanix_vpc_v2.transit_vpc]
  lifecycle {
    ignore_changes = [
      disks,
      guest_customization,
      cd_roms
    ]
  }
}

resource "nutanix_virtual_machine_v2" "member1_vm" {
  name                 = "${var.gw_name}-1"
  description          = var.gw_description
  num_sockets          = var.member1_num_cpus != 2 ? var.member1_num_cpus : 2
  num_cores_per_socket = var.member1_num_cores_per_socket != 1 ? var.member1_num_cores_per_socket : 1

  memory_size_bytes = (var.member1_memory_in_gb != 0 ? var.member1_memory_in_gb : 8) * pow(1024, 3)

  cluster {
    ext_id = data.nutanix_cluster.cluster.id
  }

  /*
  Indicates whether the VM is an agent VM or not. When their host enters maintenance mode, once the normal
   VMs are evacuated, the agent VMs are powered off. When the host is restored, agent VMs are powered on
    before the normal VMs are restored. In other words, agent VMs cannot be HA-protected or live migrated.
  */
  is_agent_vm = true

  guest_customization {
    config {
      cloud_init {
        cloud_init_script {
          user_data {
            value = base64encode(local.member1_userdata != "" ? local.member1_userdata : "#cloud-config\n")
          }
        }
      }
    }
  }

  boot_config {
    legacy_boot {
      boot_order = ["DISK", "CDROM", "NETWORK"]
    }
  }

  disks {
    disk_address {
      bus_type = "SCSI"
      index    = 0
    }
    backing_info {
      vm_disk {
        disk_size_bytes = (var.member1_disk_size_in_gb != 0 ? var.member1_disk_size_in_gb : 100) * pow(1024, 3)
        data_source {
          reference {
            image_reference {
              image_ext_id = data.nutanix_image.gw_image.id
            }
          }
        }
      }
    }
  }

  nics {
    # First NIC on MGMT subnet
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = nutanix_subnet_v2.transit_vpc_subnets[var.transit_subnets["mgmt"].name].id
      }
      ipv4_config {
        should_assign_ip = true
        ip_address {
          value = var.transit_subnets["mgmt"].member1_ip
        }
      }
    }
  }
  nics {
    # Second NIC on DATA subnet
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = nutanix_subnet_v2.transit_vpc_subnets[var.transit_subnets["data"].name].id
      }
      ipv4_config {
        should_assign_ip = true
        ip_address {
          value = var.transit_subnets["data"].member1_ip
        }
      }
    }
  }
  nics {
    # Third NIC on HA subnet
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = nutanix_subnet_v2.transit_vpc_subnets[var.transit_subnets["ha"].name].id
      }
      ipv4_config {
        should_assign_ip = true
        ip_address {
          value = var.transit_subnets["ha"].member1_ip
        }
      }
    }
  }

  power_state = "ON"
  depends_on  = [nutanix_vpc_v2.transit_vpc]
  lifecycle {
    ignore_changes = [
      disks,
      guest_customization,
      cd_roms
    ]
  }
}

resource "nutanix_virtual_machine_v2" "member2_vm" {
  name                 = "${var.gw_name}-2"
  description          = var.gw_description
  num_sockets          = var.member2_num_cpus != 2 ? var.member2_num_cpus : 2
  num_cores_per_socket = var.member2_num_cores_per_socket != 1 ? var.member2_num_cores_per_socket : 1

  memory_size_bytes = (var.member2_memory_in_gb != 0 ? var.member2_memory_in_gb : 8) * pow(1024, 3)

  cluster {
    ext_id = data.nutanix_cluster.cluster.id
  }

  /*
  Indicates whether the VM is an agent VM or not. When their host enters maintenance mode, once the normal
   VMs are evacuated, the agent VMs are powered off. When the host is restored, agent VMs are powered on
    before the normal VMs are restored. In other words, agent VMs cannot be HA-protected or live migrated.
  */
  is_agent_vm = true

  guest_customization {
    config {
      cloud_init {
        cloud_init_script {
          user_data {
            value = base64encode(local.member2_userdata != "" ? local.member2_userdata : "#cloud-config\n")
          }
        }
      }
    }
  }

  boot_config {
    legacy_boot {
      boot_order = ["DISK", "CDROM", "NETWORK"]
    }
  }

  disks {
    disk_address {
      bus_type = "SCSI"
      index    = 0
    }
    backing_info {
      vm_disk {
        disk_size_bytes = (var.member2_disk_size_in_gb != 0 ? var.member2_disk_size_in_gb : 100) * pow(1024, 3)
        data_source {
          reference {
            image_reference {
              image_ext_id = data.nutanix_image.gw_image.id
            }
          }
        }
      }
    }
  }

  nics {
    # First NIC on MGMT subnet
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = nutanix_subnet_v2.transit_vpc_subnets[var.transit_subnets["mgmt"].name].id
      }
      ipv4_config {
        should_assign_ip = true
        ip_address {
          value = var.transit_subnets["mgmt"].member2_ip
        }
      }
    }
  }
  nics {
    # Second NIC on DATA subnet
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = nutanix_subnet_v2.transit_vpc_subnets[var.transit_subnets["data"].name].id
      }
      ipv4_config {
        should_assign_ip = true
        ip_address {
          value = var.transit_subnets["data"].member2_ip
        }
      }
    }
  }
  nics {
    # Third NIC on HA subnet
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = nutanix_subnet_v2.transit_vpc_subnets[var.transit_subnets["ha"].name].id
      }
      ipv4_config {
        should_assign_ip = true
        ip_address {
          value = var.transit_subnets["ha"].member2_ip
        }
      }
    }
  }

  power_state = "ON"
  depends_on  = [nutanix_vpc_v2.transit_vpc]
  lifecycle {
    ignore_changes = [
      disks,
      guest_customization,
      cd_roms
    ]
  }
}



####### Floating IPs #######
# Floating IP for Management VM
resource "nutanix_floating_ip_v2" "mgmt_fip" {
  count                    = var.deploy_management ? 1 : 0
  name                      = "${var.mgmt_name}-fip"
  description               = "Floating IP for Management VM"
  external_subnet_reference = data.nutanix_subnet.external_subnet.id
  association {
    vm_nic_association {
      vm_nic_reference = nutanix_virtual_machine_v2.mgmt_vm[0].nics[0].ext_id
    }
  }
  depends_on = [nutanix_virtual_machine_v2.mgmt_vm]
}

# Floating IP for Gateway 1
resource "nutanix_floating_ip_v2" "member1_fip" {
  name                      = "${var.gw_name}-1-fip"
  description               = "Floating IP for GW 1"
  external_subnet_reference = data.nutanix_subnet.external_subnet.id
  association {
    vm_nic_association {
      vm_nic_reference = nutanix_virtual_machine_v2.member1_vm.nics[0].ext_id
    }
  }
  depends_on = [nutanix_virtual_machine_v2.member1_vm]
}


# Floating IP for Gateway 2
resource "nutanix_floating_ip_v2" "member2_fip" {
  name                      = "${var.gw_name}-2-fip"
  description               = "Floating IP for GW 2"
  external_subnet_reference = data.nutanix_subnet.external_subnet.id
  association {
    vm_nic_association {
      vm_nic_reference = nutanix_virtual_machine_v2.member2_vm.nics[0].ext_id
    }
  }
  depends_on = [nutanix_virtual_machine_v2.member2_vm]
}
