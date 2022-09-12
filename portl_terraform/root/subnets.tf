/*
  Create Tools Subnet
*/
resource "aws_subnet" "tools_subnet" {
  cidr_block = "${var.tools_subnet_cidr}"
  vpc_id = "${module.aws_vpc.id}"

  tags {
    Name = "Tools Subnet"
  }
}

// Associate the 'Tools Subnet' with the 'Internal' Route Table
resource "aws_route_table_association" "tools" {
  subnet_id      = "${aws_subnet.tools_subnet.id}"
  route_table_id = "${module.aws_vpc.route_table_ids["internal"]}"
}

/*
  Subnet for Pfsense box that is public
*/

resource "aws_subnet" "pfsense_subnet" {
  cidr_block = "${var.pfsense_subnet_cidr}"
  vpc_id = "${module.aws_vpc.id}"

  tags {
    Name = "pfsense Subnet"
  }
}

resource "aws_route_table_association" "pfsense" {
  subnet_id      = "${aws_subnet.pfsense_subnet.id}"
  route_table_id = "${module.aws_vpc.route_table_ids["external"]}"
}
