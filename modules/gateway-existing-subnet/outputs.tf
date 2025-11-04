output "gateway_vm_name" {
  description = "Name of the deployed CloudGuard Security Gateway"
  value       = nutanix_virtual_machine_v2.gw_vm.name
}

output "gateway_vm_id" {
  description = "ID (ext_id) of the deployed CloudGuard Security Gateway"
  value       = nutanix_virtual_machine_v2.gw_vm.id
}
