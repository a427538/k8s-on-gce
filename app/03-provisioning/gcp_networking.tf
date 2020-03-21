resource "google_dns_managed_zone" "private-zone" {
  name        = "private-zone-k8s-totopos"
  dns_name    = "k8s.totopos.de."
  description = "Private k8s.totopos.de DNS zone"
  labels = {
    foo = "bar"
  }

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.network.self_link
    }
  }
}

resource "google_dns_managed_zone" "public-zone" {
  name        = "public-zone-k8s-totopos"
  dns_name    = "k8s.totopos.de."
  description = "Public k8s.totopos.de DNS zone"
  labels = {
    foo = "bar"
  }
}

resource "google_compute_network" "network" {
  name                    = var.gce_network
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = var.gce_subnetwork
  network       = google_compute_network.network.name
  region        = var.gce_region
  ip_cidr_range = "10.174.0.0/24"
}

resource "google_compute_route" "default" {
  name        = "default"
  depends_on = [google_compute_instance.bastion]
  tags        = [ "no-ip" ]
  dest_range  = "0.0.0.0/0"
  network     = google_compute_network.network.self_link
  next_hop_ip = google_compute_instance.bastion.network_interface[0].network_ip
  priority    = 800
}

resource "google_compute_firewall" "internal" {
  name    = "${var.gce_network}-allow-internal"
  network = google_compute_network.network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "tcp"
  }

  source_ranges = ["10.174.0.0/24"]
}

resource "google_compute_firewall" "external" {
  name    = "${var.gce_network}-allow-external"
  network = google_compute_network.network.name

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

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "bastion" {
  name = "bastion"
}