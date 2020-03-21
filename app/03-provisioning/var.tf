// Configure the Google Cloud provider
provider "google" {
  credentials = file("/root/app/adc.json")
}

variable "gce_ssh_user" {
  default = "ansible"
}

variable "gce_ssh_pub_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

variable "gce_project" {
  type = string
}

variable "gce_region" {
  type = string
}

variable "gce_zone" {
  type = string
}

variable "gce_network" {
  type = string
}

variable "gce_subnetwork" {
  type = string
}

variable "gce_sa_email" {
  type = string
}
