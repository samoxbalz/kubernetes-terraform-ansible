terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
    service_account_key_file = file("~/sa-terraform-key.json")
    cloud_id  = "b1ginnt3vvb48cipo0jf"
    folder_id = "b1gmmfjj7c22rg8okcgi"
    zone      = "ru-central1-a"
}

resource "yandex_vpc_network" "envoy-net" {
  name = "envoy-net"
}

resource "yandex_vpc_subnet" "envoy-subnet-master" {
  name           = "envoy-subnet-master"
  v4_cidr_blocks = ["10.240.1.0/27"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.envoy-net.id
}

resource "yandex_vpc_subnet" "envoy-subnet-worker" {
  name           = "envoy-subnet-worker"
  v4_cidr_blocks = ["10.240.2.0/27"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.envoy-net.id
}

resource "yandex_vpc_subnet" "envoy-subnet-pod-cidr" {
  name           = "envoy-subnet-pod-cidr"
  v4_cidr_blocks = ["10.124.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.envoy-net.id
}

resource "yandex_vpc_subnet" "envoy-subnet-service-cidr" {
  name           = "envoy-subnet-service-cidr"
  v4_cidr_blocks = ["10.96.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.envoy-net.id
}

resource "yandex_vpc_subnet" "cilium-pod-subnet-cidr" {
  name           = "cilium-pod-subnet-cidr"
  v4_cidr_blocks = ["10.112.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.envoy-net.id
}

resource "yandex_compute_instance" "kube-master" {
  name = "kube-master"
  hostname = "kube-master"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd83n3uou8m03iq9gavu"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.envoy-subnet-master.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "kube-node-1" {
  name = "kube-node-1"
  hostname = "kube-node-1"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd83n3uou8m03iq9gavu"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.envoy-subnet-worker.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "kube-node-2" {
  name = "kube-node-2"
  hostname = "kube-node-2"
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd83n3uou8m03iq9gavu"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.envoy-subnet-worker.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "ya_cloud"
  content = templatefile("inventory.tpl", {
    master = yandex_compute_instance.kube-master.network_interface[0].nat_ip_address
    nodes = [yandex_compute_instance.kube-node-1.network_interface[0].nat_ip_address, yandex_compute_instance.kube-node-2.network_interface[0].nat_ip_address]
  })
}