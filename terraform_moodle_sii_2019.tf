provider "google" {
  credentials = "${file("arctic-plasma-248716-2ef31a9e14cc.json")}"
  project     = "arctic-plasma-248716"
  region      = "us-central1"
}


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
      "export WEB_IP=${google_compute_instance.default_web.network_interface.0.network_ip}",
      "export DB_IP=${google_compute_instance.default_db.network_interface.0.network_ip}",
      "echo $WEB_IP",
      "echo $DB_IP",
      "chmod +x /tmp/scenario_db.sh",
      "sudo -E /tmp/scenario_db.sh",
    ]
  
  }
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
 
 metadata_startup_script = ""

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
      "export WEB_IP=${google_compute_instance.default_web.network_interface.0.network_ip}",
      "export DB_IP=${google_compute_instance.default_db.network_interface.0.network_ip}",
      "echo $IP_WEB",
      "echo $IP_DB",
      "chmod +x /tmp/scenario_web.sh",
      "sudo -E /tmp/scenario_web.sh",
    ]
  
  }
 
}


resource "google_compute_firewall" "default_web" {  
    name = "allow-http"
    network = "default"

    allow {
        protocol = "tcp"
        ports = ["80"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["web-moodle"]
}

resource "google_compute_firewall" "default_db" {  
    name = "allow-mysql"
    network = "default"

    allow {
        protocol = "tcp"
        ports = ["3306"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["db-moodle"]
}



