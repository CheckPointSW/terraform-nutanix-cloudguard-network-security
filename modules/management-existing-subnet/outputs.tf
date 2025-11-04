output "management_vm_name" {
  description = "Name of the Management Server VM."
  value       = nutanix_virtual_machine_v2.mgmt_vm.name
}

output "management_vm_id" {
  description = "External ID (UUID) of the Management Server VM."
  value       = nutanix_virtual_machine_v2.mgmt_vm.id
}

output "management_subnet_name" {
  description = "Name of the existing subnet where the Management VM NIC is attached."
  value       = var.mgmt_subnet_name
}
