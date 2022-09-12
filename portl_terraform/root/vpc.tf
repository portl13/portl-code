
/*
  Create a VPN Connection
*/
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = "${module.aws_vpc.id}"

  tags {
    Name = "vpn_gw"
  }
}

resource "aws_vpn_connection" "csky" {
  vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw.id}"
  customer_gateway_id = "cgw-c2e13bdc"
  type                = "ipsec.1"
  static_routes_only  = true

  tags {
    Name = "csky"
  }
}

resource "aws_vpn_connection_route" "csky_office" {
  destination_cidr_block = "192.168.96.0/20"
  vpn_connection_id      = "${aws_vpn_connection.csky.id}"
}

resource "aws_vpn_connection_route" "csky_vpn" {
  destination_cidr_block = "172.18.0.0/20"
  vpn_connection_id      = "${aws_vpn_connection.csky.id}"
}

resource "aws_vpn_connection_route" "csky_internal_dmz" {
  destination_cidr_block = "172.31.79.0/24"
  vpn_connection_id      = "${aws_vpn_connection.csky.id}"
}

resource "aws_vpn_connection_route" "csky_external_dmz" {
  destination_cidr_block = "172.31.74.128/25"
  vpn_connection_id      = "${aws_vpn_connection.csky.id}"
}


/*
  Add new routes to internal route-table
*/
resource "aws_route" "csky_office" {
  route_table_id = "${module.aws_vpc.route_table_ids["internal"]}"
  destination_cidr_block = "192.168.96.0/20"
  gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
}

resource "aws_route" "csky_vpn" {
  route_table_id = "${module.aws_vpc.route_table_ids["internal"]}"
  destination_cidr_block = "172.18.0.0/20"
  gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
}

resource "aws_route" "csky_internal_dmz" {
  route_table_id = "${module.aws_vpc.route_table_ids["internal"]}"
  destination_cidr_block = "172.31.79.0/24"
  gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
}

resource "aws_route" "csky_external_dmz" {
  route_table_id = "${module.aws_vpc.route_table_ids["internal"]}"
  destination_cidr_block = "172.31.74.128/25"
  gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
}


/*
  Add new routes to external route-table
*/
resource "aws_route" "csky_office_external" {
  route_table_id = "${module.aws_vpc.route_table_ids["external"]}"
  destination_cidr_block = "192.168.96.0/20"
  gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
}

resource "aws_route" "csky_vpn_external" {
  route_table_id = "${module.aws_vpc.route_table_ids["external"]}"
  destination_cidr_block = "172.18.0.0/20"
  gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
}

resource "aws_route" "csky_internal_dmz_external" {
  route_table_id = "${module.aws_vpc.route_table_ids["external"]}"
  destination_cidr_block = "172.31.79.0/24"
  gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
}

resource "aws_route" "csky_external_dmz_external" {
  route_table_id = "${module.aws_vpc.route_table_ids["external"]}"
  destination_cidr_block = "172.31.74.128/25"
  gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
}