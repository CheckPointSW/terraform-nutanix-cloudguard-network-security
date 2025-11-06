variable "transit_vpc_name" {
  description = "Transit VPC name."
  type        = string
  default     = "TF-Transit-VPC"
}

variable "tenant_vpc_name" {
  description = "Base name used for sample downstream tenant VPCs (A & B)."
  type        = string
  default     = "TF-Tenant-VPC"
}

variable "cluster_name" {
  description = "Name of the Nutanix cluster registered in Prism Central."
  type        = string
}

variable "transit_subnets" {
  description = "Map of management, data and HA subnets with static IP reservations for ClusterXL members and management."
  type = map(object({
    name            = string
    cidr_block      = string
    default_gateway = string
    ip_start_range  = string
    ip_end_range    = string
    mgmt_ip         = optional(string, null) # mgmt_ip is optional to allow non-mgmt subnets
    member1_ip      = string
    member2_ip      = string
  }))
  default = {
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
}

variable "transit_to_tenant_subnet" {
  description = "Subnet bridging transit VPC to downstream tenant VPCs (egress / attachment)."
  type = object({
    name            = string
    cidr_block      = string
    default_gateway = string
    ip_start_range  = string
    ip_end_range    = string
  })
  default = {
    name            = "TF-Transit-VPC-Subnet"
    cidr_block      = "172.16.200.0/24"
    default_gateway = "172.16.200.1"
    ip_start_range  = "172.16.200.10"
    ip_end_range    = "172.16.200.200"
  }
}

variable "tenant_vpcs_subnets" {
  description = "Map defining single overlay subnet per sample tenant VPC (A & B)."
  type = map(object({
    name            = string
    cidr_block      = string
    default_gateway = string
    ip_start_range  = string
    ip_end_range    = string
  }))
  default = {
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

variable "dns_ip" {
  description = "Optional DNS server IPv4 address. If empty, DHCP common_dhcp_options are omitted."
  type        = string
  default     = ""
}

variable "ntp_server" {
  description = "NTP server hostname or IPv4 address."
  type        = string
  default     = "pool.ntp.org"
}

variable "ntp_version" {
  description = "NTP protocol version (default: 4)."
  type        = number
  default     = 4
}
variable "external_subnet_name" {
  description = "Name of existing external subnet providing egress and floating IP allocations."
  type        = string
}

###############################
# Management Server variables #
###############################
variable "mgmt_name" {
  description = "Management Server VM name."
  type        = string
  default     = "TF-Transit-VPC-MGMT"
}

variable "mgmt_description" {
  description = "Management Server VM description."
  type        = string
  default     = "Check Point CloudGuard Management Server VM created by Terraform"
}
variable "mgmt_image_name" {
  description = "QCOW2 image name for the Management Server in Nutanix image library."
  type        = string
}

variable "deploy_management" {
  description = "Whether to deploy the Management Server resources (VM + floating IP) in the Transit VPC. Set false to skip management deployment."
  type        = bool
  default     = true
}

variable "mgmt_num_cpus" {
  description = "Number of CPU sockets for the Management Server (>=2)."
  type        = number
  default     = 2
  validation {
    condition     = var.mgmt_num_cpus > 1
    error_message = "Number of CPUs must be at least 2."
  }
}
variable "mgmt_num_cores_per_socket" {
  description = "Number of cores per socket for the Management Server (>=1)."
  type        = number
  default     = 1
  validation {
    condition     = var.mgmt_num_cores_per_socket >= 1
    error_message = "Number of cores per socket must be at least 1."
  }
}

variable "mgmt_memory_in_gb" {
  description = "Management Server memory size in GB (>=8 recommended)."
  type        = number
  default     = 8
  validation {
    condition     = var.mgmt_memory_in_gb >= 8
    error_message = "Management memory must be at least 8 GB."
  }
}

variable "mgmt_disk_size_in_gb" {
  description = "Management Server disk size in GB (>=50, 100 recommended)."
  type        = number
  default     = 100
  validation {
    condition     = var.mgmt_disk_size_in_gb >= 50
    error_message = "Management disk size must be at least 50 GB."
  }
}

variable "mgmt_admin_shell" {
  type        = string
  description = "Admin shell for the Management Server (one of /etc/cli.sh, /bin/bash, /bin/csh, /bin/sh, /bin/tcsh, /user/bin/scponly, /sbin/nologin)."
  default     = "/etc/cli.sh"
  validation {
    condition     = contains(["/etc/cli.sh", "/bin/bash", "/bin/csh", "/bin/sh", "/bin/tcsh", "/user/bin/scponly", "/sbin/nologin"], var.mgmt_admin_shell)
    error_message = "mgmt_admin_shell must be one of: /etc/cli.sh, /bin/bash, /bin/csh, /bin/sh, /bin/tcsh, /user/bin/scponly, /sbin/nologin. "
  }
}

variable "ftw_sic" {
  description = "Secure Internal Communication (SIC) key (>=8 alphanumeric characters)."
  type        = string
  sensitive   = true
}

variable "mgmt_admin_password" {
  description = "Management Server admin password (>=6 alphanumeric characters)."
  type        = string
  sensitive   = true
}

variable "mgmt_maintenance_password" {
  description = "Management Server maintenance password (>=6 alphanumeric characters)."
  type        = string
  sensitive   = true
}
###############################
# Security Gateway variables #
###############################
variable "gw_name" {
  description = "Base name for Security Gateway cluster members."
  type        = string
  default     = "TF-Transit-VPC-GW"
}

variable "gw_description" {
  description = "Security Gateway VM description."
  type        = string
  default     = "Security Gateway VM created by Terraform"
}
variable "gw_image_name" {
  description = "QCOW2 image name for the Security Gateway in Nutanix image library."
  type        = string
}

variable "member1_num_cpus" {
  description = "Number of CPU sockets for gateway member1 (>=2)."
  type        = number
  default     = 2
  validation {
    condition     = var.member1_num_cpus > 1
    error_message = "Number of CPUs must be at least 2."
  }
}
variable "member1_num_cores_per_socket" {
  description = "Number of cores per socket for gateway member1 (>=1)."
  type        = number
  default     = 1
  validation {
    condition     = var.member1_num_cores_per_socket >= 1
    error_message = "Number of cores per socket must be at least 1."
  }
}


variable "member1_memory_in_gb" {
  description = "Gateway member1 memory size in GB (>=8 recommended)."
  type        = number
  default     = 8 # Will use 8GB default in resource
  validation {
    condition     = var.member1_memory_in_gb >= 8
    error_message = "Gateway memory must be at least 8 GB."
  }
}

variable "member1_disk_size_in_gb" {
  description = "Gateway member1 disk size in GB (>=50, 100 recommended)."
  type        = number
  default     = 100
  validation {
    condition     = var.member1_disk_size_in_gb >= 50
    error_message = "Gateway disk size must be at least 50 GB."
  }
}

variable "member1_admin_shell" {
  type        = string
  description = "Admin shell for gateway member1 (one of /etc/cli.sh, /bin/bash, /bin/csh, /bin/sh, /bin/tcsh, /user/bin/scponly, /sbin/nologin)."
  default     = "/etc/cli.sh"
  validation {
    condition     = contains(["/etc/cli.sh", "/bin/bash", "/bin/csh", "/bin/sh", "/bin/tcsh", "/user/bin/scponly", "/sbin/nologin"], var.member1_admin_shell)
    error_message = "member1_admin_shell must be one of: /etc/cli.sh, /bin/bash, /bin/csh, /bin/sh, /bin/tcsh, /user/bin/scponly, /sbin/nologin. "
  }
}

variable "gw_admin_password" {
  description = "Security Gateway admin password (>=6 alphanumeric characters)."
  type        = string
  sensitive   = true
}
variable "gw_maintenance_password" {
  description = "Security Gateway maintenance password (>=6 alphanumeric characters)."
  type        = string
  sensitive   = true
}

variable "member2_num_cpus" {
  description = "Number of CPU sockets for gateway member2 (>=2)."
  type        = number
  default     = 2
  validation {
    condition     = var.member2_num_cpus > 1
    error_message = "Number of CPUs must be at least 2."
  }
}
variable "member2_num_cores_per_socket" {
  description = "Number of cores per socket for gateway member2 (>=1)."
  type        = number
  default     = 1
  validation {
    condition     = var.member2_num_cores_per_socket >= 1
    error_message = "Number of cores per socket must be at least 1."
  }
}

variable "member2_memory_in_gb" {
  description = "Gateway member2 memory size in GB (>=8 recommended)."
  type        = number
  default     = 8 # Will use 8GB default in resource
  validation {
    condition     = var.member2_memory_in_gb >= 8
    error_message = "Gateway memory must be at least 8 GB."
  }
}

variable "member2_disk_size_in_gb" {
  description = "Gateway member2 disk size in GB (>=50, 100 recommended)."
  type        = number
  default     = 100
  validation {
    condition     = var.member2_disk_size_in_gb >= 50
    error_message = "Gateway disk size must be at least 50 GB."
  }
}

variable "member2_admin_shell" {
  type        = string
  description = "Admin shell for gateway member2 (one of /etc/cli.sh, /bin/bash, /bin/csh, /bin/sh, /bin/tcsh, /user/bin/scponly, /sbin/nologin)."
  default     = "/etc/cli.sh"
  validation {
    condition     = contains(["/etc/cli.sh", "/bin/bash", "/bin/csh", "/bin/sh", "/bin/tcsh", "/user/bin/scponly", "/sbin/nologin"], var.member2_admin_shell)
    error_message = "member2_admin_shell must be one of: /etc/cli.sh, /bin/bash, /bin/csh ,/bin/sh, /bin/tcsh, /user/bin/scponly, /sbin/nologin. "
  }
}

variable "clusterXL_virtual_ip" {
  description = "ClusterXL virtual IP address on the data interface (Data subnet)."
  type        = string
  default     = "172.16.20.20"
}

variable "network_to_reroute" {
  description = "CIDR network to reroute to the ClusterXL virtual IP."
  type        = string
  default     = "192.168.0.0/23"
}

variable "policy_routing_priority" {
  description = "Priority of the Policy Based Routing rule (higher value = higher priority)."
  type        = number
  default     = 20
}
