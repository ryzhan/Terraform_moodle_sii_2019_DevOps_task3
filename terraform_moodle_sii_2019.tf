provider "google" {
  credentials = "${file("arctic-plasma-248716-2ef31a9e14cc.json")}"
  project     = "arctic-plasma-248716"
  region      = "us-central1-a"
}

