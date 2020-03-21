resource "google_compute_instance" "bastion" {
  name           = "bastion"
  depends_on = [google_compute_subnetwork.subnetwork]
  machine_type   = "e2-micro"
  can_ip_forward = true
  // zone           = var.gce_zone
  deletion_protection = false

  tags = [var.gce_network, "haproxy", "bastion"]

  boot_disk {
    initialize_params {
      type = "pd-standard"
      image = "ubuntu-os-cloud/ubuntu-minimal-1804-bionic-v20200220"
      size = "50"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.self_link
    // network_ip = "10.243.0.2"

    access_config {
      nat_ip = google_compute_address.bastion.address
    }
  }

  service_account {
    email  = var.gce_sa_email
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
    enable-oslogin = false
  }

  metadata_startup_script = file("03-provisioning/startup-bastion.sh")

}

resource "google_dns_record_set" "bastion_private" {
  name = "bastion.${google_dns_managed_zone.private-zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.private-zone.name

  rrdatas = [google_compute_instance.bastion.network_interface[0].network_ip]
}

resource "google_dns_record_set" "bastion_public" {
  name = "bastion.${google_dns_managed_zone.public-zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.public-zone.name

  rrdatas = [google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip]
}