##### Data Sources #######
data "nutanix_subnet" "external_subnet" {
  subnet_name = var.gw_external_subnet_name
}

data "nutanix_subnet" "internal_subnet" {
  subnet_name = var.gw_internal_subnet_name
}

data "nutanix_cluster" "cluster" {
  name = var.cluster_name
}

data "nutanix_image" "gw_image" {
  image_name = var.gw_image_name
}

##### Locals #######

locals {
  # Read file from root module directory
  gw_userdata = var.gw_user_data_file_path != "" ? file(var.gw_user_data_file_path) : null
}

###### Resources #######

resource "nutanix_virtual_machine_v2" "gw_vm" {
  name                 = var.gw_name
  description          = var.gw_description != "" ? var.gw_description : ""
  num_sockets          = var.gw_num_cpus != 2 ? var.gw_num_cpus : 2
  num_cores_per_socket = var.gw_num_cores_per_socket != 1 ? var.gw_num_cores_per_socket : 1

  memory_size_bytes = (var.gw_memory_in_gb != 0 ? var.gw_memory_in_gb : 8) * pow(1024, 3)
  cluster {
    ext_id = data.nutanix_cluster.cluster.id
  }

  /*
  Indicates whether the VM is an agent VM or not. When their host enters maintenance mode, once the normal
   VMs are evacuated, the agent VMs are powered off. When the host is restored, agent VMs are powered on
    before the normal VMs are restored. In other words, agent VMs cannot be HA-protected or live migrated.
  */
  is_agent_vm = true

  // will use guest_customization only if provided userdata file
  dynamic "guest_customization" {
    for_each = local.gw_userdata != null ? [1] : []
    content {
      config {
        cloud_init {
          cloud_init_script {
            user_data {
              value = base64encode(local.gw_userdata)
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
        disk_size_bytes = (var.gw_disk_size_in_gb != 0 ? var.gw_disk_size_in_gb : 100) * pow(1024, 3)
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
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = data.nutanix_subnet.external_subnet.id
      }
    }
  }

  nics {
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = data.nutanix_subnet.internal_subnet.id
      }
    }
  }

  power_state = "ON"
  lifecycle {
    ignore_changes = [
      disks, # Ignore changes to disks to prevent recreation
      guest_customization
    ]
  }
}
