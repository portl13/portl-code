resource "aws_security_group" "app_lb" {
    name = "app_lb"
    description = "Allow tcp/22, icmp from Management Server"
    vpc_id = "${module.aws_vpc.id}"

    tags {
        Name = "app_lb"
    }

    ingress {
        from_port = 9000
        to_port = 9000
        protocol = "tcp"
        cidr_blocks = [
          "${module.aws_vpc.subnet_cidrs["nat_a"]}",
          "${module.aws_vpc.subnet_cidrs["nat_b"]}",
          "${module.aws_vpc.subnet_cidrs["nat_c"]}",
        ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [
          "0.0.0.0/0",
        ]
    }
}

resource "aws_security_group" "ansible_management" {
    name = "ansible_management"
    description = "Allow tcp/22, icmp from Management Server"
    vpc_id = "${module.aws_vpc.id}"

    tags {
        Name = "ansible_management"
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [
          "${aws_instance.management.private_ip}/32"
        ]
    }

    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = [
          "${aws_instance.management.private_ip}/32"
        ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [
          "0.0.0.0/0",
        ]
    }
}

resource "aws_security_group" "graylog_server" {
    name = "graylog_server"
    description = "Allow udp/10514, tcp/10514, udp/12201, tcp/12201 from VPC."
    vpc_id = "${module.aws_vpc.id}"

    tags {
        Name = "graylog_server"
    }

    ingress {
        from_port = 10514
        to_port = 10514
        protocol = "tcp"
        cidr_blocks = [
          "${var.vpc_cidr}"
        ]
    }

    ingress {
        from_port = 10514
        to_port = 10514
        protocol = "udp"
        cidr_blocks = [
          "${var.vpc_cidr}"
        ]
    }

    ingress {
        from_port = 12201
        to_port = 12201
        protocol = "tcp"
        cidr_blocks = [
          "${var.vpc_cidr}"
        ]
    }

    ingress {
        from_port = 12201
        to_port = 12201
        protocol = "udp"
        cidr_blocks = [
          "${var.vpc_cidr}"
        ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [
          "0.0.0.0/0",
        ]
    }
}

resource "aws_security_group" "influxdb_server" {
    name = "influxdb_server"
    description = "Allow tcp/2003, tcp/8086, tcp/8088 from VPC."
    vpc_id = "${module.aws_vpc.id}"

    tags {
        Name = "influxdb_server"
    }

    ingress {
        from_port = 2003
        to_port = 2003
        protocol = "tcp"
        cidr_blocks = [
            "${var.vpc_cidr}"
        ]
    }

    ingress {
        from_port = 8086
        to_port = 8086
        protocol = "tcp"
        cidr_blocks = [
            "${var.vpc_cidr}"
        ]
    }

    ingress {
        from_port = 8088
        to_port = 8088
        protocol = "tcp"
        cidr_blocks = [
            "${var.vpc_cidr}"
        ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [
            "0.0.0.0/0",
        ]
    }
}


resource "aws_security_group" "nexus_server" {
    name = "nexus_server"
    description = "Allow udp/10514, tcp/10514, udp/12201, tcp/12201 from VPC."
    vpc_id = "${module.aws_vpc.id}"

    tags {
        Name = "nexus_server"
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [
          "${var.vpc_cidr}"
        ]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [
          "${var.vpc_cidr}"
        ]
    }

    ingress {
        from_port = 8081
        to_port = 8081
        protocol = "tcp"
        cidr_blocks = [
          "${var.vpc_cidr}"
        ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [
          "0.0.0.0/0",
        ]
    }
}

resource "aws_security_group" "zabbix_agent" {
    name = "zabbix_agent"
    description = "Allow tcp/10050-10051, icmp from Tools Network"
    vpc_id = "${module.aws_vpc.id}"

    tags {
        Name = "zabbix_agent"
    }

    ingress {
        from_port = 10050
        to_port = 10051
        protocol = "tcp"
        cidr_blocks = [
          "${var.pfsense_subnet_cidr}",
          "${aws_subnet.tools_subnet.cidr_block}"
        ]
    }

    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = [
          "${var.pfsense_subnet_cidr}"

        ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [
          "0.0.0.0/0",
        ]
    }
}

resource "aws_security_group" "zabbix_server" {
    name = "zabbix_server"
    description = "Allow tcp/10050-10051, icmp from VPC"
    vpc_id = "${module.aws_vpc.id}"

    tags {
        Name = "zabbix_server"
    }

    ingress {
        from_port = 10050
        to_port = 10051
        protocol = "tcp"
        cidr_blocks = [
          "${var.vpc_cidr}"
        ]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [
          "${var.vpc_cidr}"
        ]
    }

    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = [
          "${var.vpc_cidr}"
        ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [
          "0.0.0.0/0",
        ]
    }
}

resource "aws_security_group" "vpn_subnet_access" {
    name = "vpn_subnet_access"
    description = "Allows customers connected to the VPN to access admin & admin-api"
    vpc_id = "${module.aws_vpc.id}"

    tags {
        Name = "pfsense_vpn"
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp" cidr_blocks = [
            "${var.pfsense_subnet_cidr}"
        ]
    }

        ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [
            "${var.pfsense_subnet_cidr}"
        ]
    }

/*
    ingress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
*/

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
}

resource "aws_security_group" "pfsense_access" {
  name = "pfsense_access"
  description = "SG to manage & connect to the vpn tunnel provided by pfsense"
  vpc_id = "${module.aws_vpc.id}"

    ingress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }
}
