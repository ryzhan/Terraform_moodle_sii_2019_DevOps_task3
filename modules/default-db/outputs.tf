output "ip_db" {
 value = "${google_compute_instance.default_db.network_interface.0.access_config.0.nat_ip}"
}

#output "ip_db_local" {
# value = "${google_compute_instance.default_db.network_interface.0.network_ip}"
#}
