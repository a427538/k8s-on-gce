variable "gce_ssh_user" {
  default = "root"
}

variable "gce_ssh_pub_key_file" {
  default = "~/.ssh/google_compute_engine.pub"
}

variable "gce_zone" {
  type = string
}

// Configure the Google Cloud provider
provider "google" {
  credentials = file("/root/app/adc.json")
}

resource "google_compute_network" "default" {
  name                    = "kubernetes-the-easy-way"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "default" {
  name          = "kubernetes"
  network       = google_compute_network.default.name
  ip_cidr_range = "10.240.0.0/24"
}

resource "google_compute_firewall" "internal" {
  name    = "kubernetes-the-easy-way-allow-internal"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "tcp"
  }

  source_ranges = ["10.240.0.0/24", "10.200.0.0/16"]
}

resource "google_compute_firewall" "external" {
  name    = "kubernetes-the-easy-way-allow-external"
  network = google_compute_network.default.name

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

resource "google_compute_address" "default" {
  name = "kubernetes-the-easy-way"
}

resource "google_compute_instance" "nfs" {
  count          = 1
  name           = "nfs-${count.index}"
  machine_type   = "e2-micro"
  can_ip_forward = true
  zone           = var.gce_zone

  labels = {
    hostgroup = "nfs"
  }

  tags = ["kubernetes-the-easy-way", "nfs"]

  boot_disk {
    initialize_params {
      type = "pd-standard"
      image = "ubuntu-os-cloud/ubuntu-minimal-1804-bionic-v20200220"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.name
    // network_ip = "10.240.0.3${count.index}"

    // access_config {
    //   // Ephemeral IP
    // }
  }

  service_account {
    email  = "terraform@stich-karl-my-k8s.iam.gserviceaccount.com"
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = "apt-get install -y python"
}

resource "google_compute_instance" "bastion" {
  count          = 1
  name           = "bastion-${count.index}"
  machine_type   = "e2-micro"
  can_ip_forward = true
  zone           = var.gce_zone

  tags = ["kubernetes-the-easy-way", "haproxy", "bastion"]

  boot_disk {
    initialize_params {
      type = "pd-standard"
      image = "ubuntu-os-cloud/ubuntu-minimal-1804-bionic-v20200220"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.name
    network_ip = "10.240.0.254"

    access_config {
      nat_ip = google_compute_address.default.address
    }
  }

  service_account {
    email  = "terraform@stich-karl-my-k8s.iam.gserviceaccount.com"
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = file("03-provisioning/startup-bastion.sh")

}

resource "google_compute_instance" "node" {
  count          = 6
  name           = "node-${count.index}"
  machine_type   = "e2-micro"
  can_ip_forward = true

  tags = ["kubernetes-the-easy-way"]

  boot_disk {
    initialize_params {
      type = "pd-standard"
      image = "ubuntu-os-cloud/ubuntu-minimal-1804-bionic-v20200220"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.name
    // network_ip = "10.240.0.1${count.index}"
// 
    // access_config {
    //   // Ephemeral IP
    // }
  }

  service_account {
    email  = "terraform@stich-karl-my-k8s.iam.gserviceaccount.com"
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = file("03-provisioning/startup-node.sh")
}

//resource "google_compute_instance_template" "controller" {
//
//  machine_type   = "e2-micro"
//  can_ip_forward = true
//
//  labels = {
//    hostgroup = "controller"
//    kubespray-0 = "kube-node"
//    kubespray-1 = "kube-master"
//    kubespray-2 = "etcd"
//  }
//
//  tags = ["kubernetes-the-easy-way", "controller", "kube-master", "etcd"]
//  name_prefix = "controller-"
//
//  scheduling {
//    preemptible       = false
//    automatic_restart = true
//  }
//
//  // Create a new boot disk from an image
//  disk {
//    source_image = "ubuntu-os-cloud/ubuntu-minimal-1804-bionic-v20200220"
//    auto_delete  = true
//    boot         = true
//    disk_type    = "pd-standard"
//  }
//
//  network_interface {
//    subnetwork = google_compute_subnetwork.default.name
//
//    access_config {
//      // Ephemeral IP
//    }
//  }  
//  
//  service_account {
//    email  = "terraform@stich-karl-my-k8s.iam.gserviceaccount.com"
//    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
//  }
//
//  metadata = {
//    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
//  }
//
//  metadata_startup_script = "apt-get install -y python"
//
//  lifecycle {
//    create_before_destroy = true
//  }
//}

//resource "google_compute_instance_template" "worker" {
//
//  machine_type   = "e2-micro"
//  can_ip_forward = true
//
//  labels = {
//    hostgroup = "worker"
//    kubespray-0 = "kube-node"
//  }
//
//  tags = ["kubernetes-the-easy-way", "worker", "kube-node"]
//  name_prefix = "worker-"
//
//  scheduling {
//    preemptible       = true
//    automatic_restart = false
//  }
//
//  // Create a new boot disk from an image
//  disk {
//    source_image = "ubuntu-os-cloud/ubuntu-minimal-1804-bionic-v20200220"
//    auto_delete  = true
//    boot         = true
//    disk_type    = "pd-standard"
//  }
//
//  network_interface {
//    subnetwork = google_compute_subnetwork.default.name
//
//    access_config {
//      // Ephemeral IP
//    }
//  }  
//  
//  service_account {
//    email  = "terraform@stich-karl-my-k8s.iam.gserviceaccount.com"
//    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
//  }
//
//  metadata = {
//    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
//  }
//
//  metadata_startup_script = "apt-get install -y python"
//
//  lifecycle {
//    create_before_destroy = true
//  }
//
//resource "google_compute_region_instance_group_manager" "controller" {
//  name               = "mig-controller"
//  base_instance_name = "controller"
//  
//  version {
//    instance_template  = google_compute_instance_template.controller.self_link
//  }
//
//  region             = "europe-west3"
//  distribution_policy_zones  = ["europe-west3-a", "europe-west3-b", "europe-west3-c"]
//
//  target_size        = 3
//  wait_for_instances = true
//
//  timeouts {
//    create = "15m"
//    update = "15m"
//  }
//
//  update_policy {
//    type                         = "PROACTIVE"
//    instance_redistribution_type = "PROACTIVE"
//    minimal_action               = "RESTART"
//    max_unavailable_fixed        = 3
//    min_ready_sec                = 50    
//  }  
//  
//  lifecycle {
//    create_before_destroy = true
//  }
//
//resource "google_compute_region_instance_group_manager" "worker" {
//  name               = "mig-worker"
//  base_instance_name = "worker"
//  
//  version {
//    instance_template  = google_compute_instance_template.worker.self_link
//  }
//
//  region             = "europe-west3"
//  distribution_policy_zones  = ["europe-west3-a", "europe-west3-b"]
//
//  target_size        = 2
//  wait_for_instances = true
//
//  timeouts {
//    create = "15m"
//    update = "15m"
//  }
//
//  update_policy {
//    type                         = "PROACTIVE"
//    instance_redistribution_type = "PROACTIVE"
//    minimal_action               = "RESTART"
//    max_unavailable_fixed        = 2
//    min_ready_sec                = 50    
//  }  
//  
//  lifecycle {
//    create_before_destroy = true
//  }
//}

