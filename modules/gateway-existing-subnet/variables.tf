variable "cluster_name" {
  description = "Cluster entity registered to Prism Central."
  type        = string
}

variable "gw_external_subnet_name" {
  description = "Name of the target Security Gateway external subnet in Nutanix cluster."
  type = string
}


variable "gw_internal_subnet_name" {
  description = "Name of the target Security Gateway internal subnet in Nutanix cluster."
  type = string
}

# Security Gateway  variables
variable "gw_name" {
  description = "Name of the Check Point CloudGuard Security Gateway."
  type        = string
  default     = "TF-Gateway"
}

variable "gw_description" {
  description = "Description of the Check Point CloudGuard Security Gateway."
  type        = string
  default     = "Check Point CloudGuard Security Gateway VM created by Terraform"
}
variable "gw_image_name" {
  description = "Name of the Check Point CloudGuard Security Gateway image in Nutanix Images library."
  type        = string
}

variable "gw_num_cpus" {
  description = "Number of cores per socket. Value should be at least 2."
  type        = number
  default     = 2
  validation {
    condition     = var.gw_num_cpus > 1
    error_message = "Number of CPUs must be at least 2."
  }
}
variable "gw_num_cores_per_socket" {
  description = "Number of vCPU sockets. Value should be at least 1."
  type        = number
  default     = 1
  validation {
    condition     = var.gw_num_cores_per_socket >= 1
    error_message = "Number of cores per socket must be at least 1."
  }
}

variable "gw_memory_in_gb" {
  description = "Memory size in GB. 8GB is recommended."
  type        = number
  default     = 8
  validation {
    condition     = var.gw_memory_in_gb >= 8
    error_message = "Security Gateway memory must be at least 8 GB."
  }
}

variable "gw_disk_size_in_gb" {
  description = "Disk size in GB, 100 is recommended."
  type        = number
  default     = 100
  validation {
    condition     = var.gw_disk_size_in_gb >= 50
    error_message = "Security Gateway disk size must be at least 50 GB."
  }
}

variable "gw_user_data_file_path" {
  description = "Absolute path for userdata file, see sk179752 - How to configure cloud-init."
  type = string
  default = ""
}