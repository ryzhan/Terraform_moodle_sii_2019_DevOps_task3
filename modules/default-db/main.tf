resource "random_id" "instance_id" {
 byte_length = 8
}

resource "google_compute_instance" "default_db" {
 name         = "moodle-db-${random_id.instance_id.hex}"
 machine_type = "f1-micro"
 zone         = "us-central1-a"

 boot_disk {
   initialize_params {
     image = "centos-7-v20190729"
   }
 }

 metadata_startup_script = ""
 
 tags = ["db-moodle"]
  
  metadata = {
   ssh-keys = "erkek:${file("~/.ssh/id_rsa.pub")}"
 }

 network_interface {
   network = "default"

   access_config {
     
   }
 }

  connection {
    user = "erkek"
    host = "${google_compute_instance.default_db.network_interface.0.access_config.0.nat_ip}"
    private_key="${file("~/.ssh/id_rsa")}"
    agent = true   
  } 
  provisioner "file" {
    source      = "scenario_db.sh"
    destination = "/tmp/scenario_db.sh"

  }

  provisioner "remote-exec" {
    inline = [
      #"export WEB_IP_LOCAL=${google_compute_instance.default_web.network_interface.0.network_ip}",
      "export DB_IP_LOCAL=${google_compute_instance.default_db.network_interface.0.network_ip}",
      "echo $WEB_IP",
      "echo $DB_IP",
      "chmod +x /tmp/scenario_db.sh",
      "sudo -E /tmp/scenario_db.sh",
    ]
    on_failure = "continue"
  
  }
}

output "ip_db_local" {
 value = "${google_compute_instance.default_db.network_interface.0.network_ip}"
}
