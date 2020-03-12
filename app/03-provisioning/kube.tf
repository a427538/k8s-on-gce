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
    ports    = ["22", "6443"]
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

  // metadata_startup_script = file("startup-bastion.sh")
  metadata_startup_script = "#!/bin/bash -xe\n\n# Enable ip forwarding and nat\nsysctl -w net.ipv4.ip_forward=1\n\n# Make forwarding persistent.\nsed -i= 's/^[# ]*net.ipv4.ip_forward=[[:digit:]]/net.ipv4.ip_forward=1/g' /etc/sysctl.conf\n\niptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE\n\napt-get update\n\n# Install nginx for instance http health check\napt-get install -y nginx\n\nENABLE_SQUID=\"false\"\n\nif [[ \"$ENABLE_SQUID\" == \"true\" ]]; then\n  apt-get install -y squid3\n\n  cat - > /etc/squid/squid.conf <<'EOM'\nshutdown_lifetime 3 seconds\n\nhttp_access allow all\n\nhttp_port 3128\nhttp_port 3129 transparent\n\n# Anonymous proxy settings\nvia off\nforwarded_for off\n\nrequest_header_access Allow allow all \nrequest_header_access Authorization allow all \nrequest_header_access WWW-Authenticate allow all \nrequest_header_access Proxy-Authorization allow all \nrequest_header_access Proxy-Authenticate allow all \nrequest_header_access Cache-Control allow all \nrequest_header_access Content-Encoding allow all \nrequest_header_access Content-Length allow all \nrequest_header_access Content-Type allow all \nrequest_header_access Date allow all \nrequest_header_access Expires allow all \nrequest_header_access Host allow all \nrequest_header_access If-Modified-Since allow all \nrequest_header_access Last-Modified allow all \nrequest_header_access Location allow all \nrequest_header_access Pragma allow all \nrequest_header_access Accept allow all \nrequest_header_access Accept-Charset allow all \nrequest_header_access Accept-Encoding allow all \nrequest_header_access Accept-Language allow all \nrequest_header_access Content-Language allow all \nrequest_header_access Mime-Version allow all \nrequest_header_access Retry-After allow all \nrequest_header_access Title allow all \nrequest_header_access Connection allow all \nrequest_header_access Proxy-Connection allow all \nrequest_header_access User-Agent allow all \nrequest_header_access Cookie allow all \nrequest_header_access All deny all\nEOM\n\n  systemctl reload squid\nfi\n" => "#!/bin/bash -xe\n\n# Enable ip forwarding and nat\nsysctl -w net.ipv4.ip_forward=1\n\n# Make forwarding persistent.\nsed -i= 's/^[# ]*net.ipv4.ip_forward=[[:digit:]]/net.ipv4.ip_forward=1/g' /etc/sysctl.conf\n\niptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE\n\napt-get update\n\n# Install nginx for instance http health check\napt-get install -y nginx\n\nENABLE_SQUID=\"false\"\n\nif [[ \"$$ENABLE_SQUID\" == \"true\" ]]; then\n  apt-get install -y squid3\n\n  cat - > /etc/squid/squid.conf <<'EOM'\nshutdown_lifetime 3 seconds\n\nhttp_access allow all\n\nhttp_port 3128\nhttp_port 3129 transparent\n\n# Anonymous proxy settings\nvia off\nforwarded_for off\n\nrequest_header_access Allow allow all \nrequest_header_access Authorization allow all \nrequest_header_access WWW-Authenticate allow all \nrequest_header_access Proxy-Authorization allow all \nrequest_header_access Proxy-Authenticate allow all \nrequest_header_access Cache-Control allow all \nrequest_header_access Content-Encoding allow all \nrequest_header_access Content-Length allow all \nrequest_header_access Content-Type allow all \nrequest_header_access Date allow all \nrequest_header_access Expires allow all \nrequest_header_access Host allow all \nrequest_header_access If-Modified-Since allow all \nrequest_header_access Last-Modified allow all \nrequest_header_access Location allow all \nrequest_header_access Pragma allow all \nrequest_header_access Accept allow all \nrequest_header_access Accept-Charset allow all \nrequest_header_access Accept-Encoding allow all \nrequest_header_access Accept-Language allow all \nrequest_header_access Content-Language allow all \nrequest_header_access Mime-Version allow all \nrequest_header_access Retry-After allow all \nrequest_header_access Title allow all \nrequest_header_access Connection allow all \nrequest_header_access Proxy-Connection allow all \nrequest_header_access User-Agent allow all \nrequest_header_access Cookie allow all \nrequest_header_access All deny all\nEOM\n\n  systemctl reload squid\nfi\n"
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

  metadata_startup_script = "apt-get install -y python"
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

