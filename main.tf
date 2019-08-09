provider "google" {
  credentials = "${file("arctic-plasma-248716-2ef31a9e14cc.json")}"
  project     = "arctic-plasma-248716"
  region      = "us-central1"
}

resource "random_id" "instance_id" {
 byte_length = 8
}



resource "google_compute_network" "my_network" {
  name = "my-net"
  auto_create_subnetworks = "false"
  depends_on = ["google_compute_network.my_network"]
}

resource "google_compute_subnetwork" "my_subnetwork" {
  name          = "my-subnet"
  ip_cidr_range = "192.168.0.0/24"
  region        = "us-central1"
  network       = "${google_compute_network.my_network.self_link}"
  depends_on = ["random_id.instance_id"]
}

resource "google_compute_address" "internal_with_subnet_and_address_db" {
  name         = "my-internal-address-db"
  subnetwork   = "${google_compute_subnetwork.my_subnetwork.self_link}"
  address_type = "INTERNAL"
  address      = "192.168.0.10"
  region       = "us-central1"
  depends_on = ["google_compute_subnetwork.my_subnetwork"]
}

resource "google_compute_address" "internal_with_subnet_and_address_web" {
  name         = "my-internal-address-web"
  subnetwork   = "${google_compute_subnetwork.my_subnetwork.self_link}"
  address_type = "INTERNAL"
  address      = "192.168.0.11"
  region       = "us-central1"
  depends_on = ["google_compute_subnetwork.my_subnetwork"]
}

resource "google_compute_firewall" "default-web" {  
    name = "allow-http"
    network = "my-net"
    depends_on = ["google_compute_network.my_network"]
    allow {
        protocol = "tcp"
        ports = ["80", "22"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["web-moodle"]
}

resource "google_compute_firewall" "default-db" {  
    name = "allow-mysql"
    network = "my-net"
    depends_on = ["google_compute_network.my_network"]
    allow {
        protocol = "tcp"
        ports = ["3306", "22"]
    }

    source_ranges = ["0.0.0.0/0"]
    target_tags = ["db-moodle"]
}


resource "google_compute_instance" "default_db" {
 name         = "moodle-db-${random_id.instance_id.hex}"
 machine_type = "f1-micro"
 zone         = "us-central1-a"

 depends_on = ["google_compute_firewall.default-db"]

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
   network = "my-net"
   subnetwork = "my-subnet"
   network_ip = "${google_compute_address.internal_with_subnet_and_address_db.address}"
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
      "chmod +x /tmp/scenario_db.sh",
      "sudo -E /tmp/scenario_db.sh",
    ]
  
  }
}

resource "google_compute_instance" "default_web" {
 name         = "moodle-web-${random_id.instance_id.hex}"
 machine_type = "f1-micro"
 zone         = "us-central1-a"
 
 depends_on = ["google_compute_instance.default_db"]
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
   network = "my-net"
   subnetwork = "my-subnet"
   network_ip = "${google_compute_address.internal_with_subnet_and_address_web.address}"
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
      "chmod +x /tmp/scenario_web.sh",
      "sudo -E /tmp/scenario_web.sh",
    ]
  
  }
 
}




