resource "random_id" "instance_id" {
 byte_length = 8
}

resource "google_compute_instance" "default_web" {
 name         = "moodle-web-${random_id.instance_id.hex}"
 machine_type = "f1-micro"
 zone         = "us-central1-a"
 
 
 boot_disk {
   initialize_params {
     image = "centos-7-v20190729"
   }
 }
 
 metadata = {
   ssh-keys = "erkek:${file("~/.ssh/id_rsa.pub")}"
 }
 
 tags = ["web-moodle","http-server"]
 
 network_interface {
   network = "default"
   
   access_config {
     
   }
 }

connection {
    user = "erkek"
    host = "${google_compute_instance.default_web.network_interface.0.access_config.0.nat_ip}"
    private_key="${file("~/.ssh/id_rsa")}"
    agent = true   
  } 
  provisioner "file" {
    source      = "scenario_web.sh"
    destination = "/tmp/scenario_web.sh"

  }

 provisioner "remote-exec" {
   inline = [
      "export WEB_IP_NAT=${google_compute_instance.default_web.network_interface.0.access_config.0.nat_ip}",
     # "export DB_IP_LOCAL=${module.db-moodle.ip_db_local}",
      "echo $WEB_IP_NAT",
      "echo $DB_IP_LOCAL",
      "chmod +x /tmp/scenario_web.sh",
      "sudo -E /tmp/scenario_web.sh",
    ]
   on_failure = "continue"
  
  }
 
}