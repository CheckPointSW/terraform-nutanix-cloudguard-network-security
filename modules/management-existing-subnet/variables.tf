variable "cluster_name" {
  description = "Name of the Nutanix cluster registered in Prism Central."
  type        = string
}

variable "mgmt_subnet_name" {
  description = "Name of existing Nutanix subnet where the Management VM NIC will attach."
  type        = string
}

# Management Server variables
variable "mgmt_name" {
  description = "Management Server VM name."
  type        = string
  default     = "TF-MGMT"
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

variable "mgmt_user_data_file_path" {
  description = "Absolute path to user-data (cloud-init) file. If empty, guest customization is skipped."
  type        = string
  default     = ""
}