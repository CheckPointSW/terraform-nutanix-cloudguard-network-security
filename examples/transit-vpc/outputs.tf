output "management_vm_name" {
  description = "Name of the Management VM (null if not deployed)"
  value       = var.deploy_management ? var.mgmt_name : null
}

output "gateway_member1_name" {
  description = "Name of the first gateway member"
  value       = "${var.gw_name}-1"
}

output "gateway_member2_name" {
  description = "Name of the second gateway member"
  value       = "${var.gw_name}-2"
}

output "clusterXL_virtual_ip" {
  description = "ClusterXL Virtual IP for data interface"
  value       = var.clusterXL_virtual_ip
}

output "network_to_reroute" {
  description = "Network routed to ClusterXL VIP"
  value       = var.network_to_reroute
}
