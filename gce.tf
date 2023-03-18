resource "google_compute_instance" "mastodon" {
  machine_type = "e2-micro"
  name         = "mastodon"
  boot_disk {
    initialize_params {
      image = "ubuntu-2204-jammy-v20230302"
    }
  }
  network_interface {
    network = "default"
  }
}