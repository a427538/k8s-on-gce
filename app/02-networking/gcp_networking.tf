variable "gce_ssh_user" {
  default = "ansible"
}

variable "gce_ssh_pub_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

variable "gce_zone" {
  type = string
}

// Configure the Google Cloud provider
provider "google" {
  credentials = file("/root/app/adc.json")
}

resource "google_compute_network" "daas" {
  name                    = "daas"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "europe-west3" {
  name          = "daas-europe-west3"
  network       = google_compute_network.daas.name
  region        = "europe-west3"
  ip_cidr_range = "10.242.0.0/24"
}

resource "google_compute_subnetwork" "europe-west4" {
  name          = "daas-europe-west4"
  network       = google_compute_network.daas.name
  region        = "europe-west4"
  ip_cidr_range = "10.243.0.0/24"
}

resource "google_compute_firewall" "internal" {
  name    = "daas-allow-internal"
  network = google_compute_network.daas.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "tcp"
  }

  source_ranges = ["10.240.0.0/24", "10.241.0.0/24", "10.242.0.0/24", "10.243.0.0/24", "10.200.0.0/16"]
}

resource "google_compute_firewall" "external" {
  name    = "daas-allow-external"
  network = google_compute_network.daas.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "6443"]
  }

  allow {
    protocol = "tcp"
    ports    = ["8200"]
  }  

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "vault" {
  name    = "daas-allow-vault"
  network = google_compute_network.daas.name
  target_tags = ["vault"]

  allow {
    protocol = "tcp"
    ports    = ["8200"]
  }  

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "bastion-0" {
  name = "bastion-0"
}
