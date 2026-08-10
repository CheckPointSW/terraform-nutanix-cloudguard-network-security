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

output "gateway_member1_floating_ip" {
  description = "Floating IP for the first gateway member"
  value       = nutanix_floating_ip_v2.member1_fip.floating_ip[0].ipv4[0].value
}

output "gateway_member2_floating_ip" {
  description = "Floating IP for the second gateway member"
  value       = nutanix_floating_ip_v2.member2_fip.floating_ip[0].ipv4[0].value
}

output "management_vm_floating_ip" {
  description = "Floating IP for the management VM (null if not deployed)"
  value       = var.deploy_management ? nutanix_floating_ip_v2.mgmt_fip[0].floating_ip[0].ipv4[0].value : null
}