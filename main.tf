data "scaleway_instance_image" "postgresql_image" {
  name = "ubuntu-pgsql-tde"
}

resource "scaleway_vpc_private_network" "pn" {}

resource "scaleway_instance_server" "postgres" {
  count = 3
  type  = "DEV1-M"
  image = data.scaleway_instance_image.postgresql_image.id
  private_network {
    pn_id = scaleway_vpc_private_network.pn.id
  }
}
