/*
  Create Managment Server
*/
resource "aws_instance" "management" {
    ami = "${var.aws_base_ami}"
    availability_zone = "${aws_subnet.tools_subnet.availability_zone}"
    associate_public_ip_address = false
    instance_type = "m4.large"
    key_name = "${var.aws_key_name}"
    subnet_id = "${aws_subnet.tools_subnet.id}"

    vpc_security_group_ids = [
      "${module.aws_vpc.security_group_ids["csky_dns"]}",
      "${module.aws_vpc.security_group_ids["csky_internal"]}",
      "${aws_security_group.zabbix_server.id}",
    ]

    root_block_device {
      delete_on_termination = true
      volume_type           = "gp2"
      volume_size           = "10"
    }

    ebs_block_device {
      device_name           = "/dev/sdb"
      delete_on_termination = true
      encrypted             = true
      volume_type           = "gp2"
      volume_size           = "100"
    }

    ebs_block_device {
      device_name           = "/dev/sdc"
      delete_on_termination = true
      encrypted             = true
      volume_type           = "gp2"
      volume_size           = "100"
    }
    ebs_block_device {
      device_name           = "/dev/sdf"
      delete_on_termination = true
      encrypted             = true
      volume_type           = "standard"
      volume_size           = "50"
    }
  tags {
      Name = "management.${var.base_domain_name}"
      Groups = "dns,haversack,jenkins,management,zabbix"
      Environment = "tools"
      Project = "${var.project_name}"
    }
}


/*
  Create Nexus Server
*/
resource "aws_instance" "nexus" {
    ami = "${var.aws_base_ami}"
    availability_zone = "${aws_subnet.tools_subnet.availability_zone}"
    associate_public_ip_address = false
    instance_type = "t2.medium"
    key_name = "${var.aws_key_name}"
    subnet_id = "${aws_subnet.tools_subnet.id}"

    vpc_security_group_ids = [
      "${aws_security_group.ansible_management.id}",
      "${module.aws_vpc.security_group_ids["csky_internal"]}",
      "${aws_security_group.nexus_server.id}",
      "${aws_security_group.zabbix_agent.id}"
    ]

    root_block_device {
      delete_on_termination = true
      volume_type           = "gp2"
      volume_size           = "10"
    }

    ebs_block_device {
      device_name           = "/dev/sdb"
      delete_on_termination = true
      encrypted             = true
      volume_type           = "gp2"
      volume_size           = "100"
    }

  tags {
      Name = "nexus.${var.base_domain_name}"
      Groups = "nexus"
      Environment = "tools"
      Project = "${var.project_name}"
    }
}


/*
  Create Graylog Server
*/
resource "aws_instance" "logs" {
    ami = "${var.aws_base_ami}"
    availability_zone = "${aws_subnet.tools_subnet.availability_zone}"
    associate_public_ip_address = false
    instance_type = "t2.large"
    key_name = "${var.aws_key_name}"
    subnet_id = "${aws_subnet.tools_subnet.id}"

    vpc_security_group_ids = [
      "${aws_security_group.ansible_management.id}",
      "${module.aws_vpc.security_group_ids["csky_internal"]}",
      "${aws_security_group.graylog_server.id}",
      "${aws_security_group.zabbix_agent.id}"
    ]

    root_block_device {
      delete_on_termination = true
      volume_type           = "gp2"
      volume_size           = "10"
    }

    ebs_block_device {
      device_name           = "/dev/sdb"
      delete_on_termination = true
      encrypted             = true
      volume_type           = "gp2"
      volume_size           = "100"
    }

    ebs_block_device {
      device_name           = "/dev/sdc"
      delete_on_termination = true
      encrypted             = true
      volume_type           = "gp2"
      volume_size           = "100"
    }

      ebs_block_device {
      device_name           = "/dev/sdd"
      delete_on_termination = true
      encrypted             = true
      volume_type           = "standard"
      volume_size           = "250"
    }

  tags {
      Name = "logs.${var.base_domain_name}"
      Groups = "graylog"
      Environment = "tools"
      Project = "${var.project_name}"
    }
}

/*
resource "aws_ebs_volume" "extra_graylog_volume" {
  availability_zone = "${aws_subnet.tools_subnet.availability_zone}"
  encrypted = true
  type = "standard"
  size = 250
  tags {
    Name = "Graylog Extra Volume"
  }
}

resource "aws_volume_attachment" "logs_extra_volume" {
  device_name = "/dev/sdd"
  instance_id = "${aws_instance.logs.id}"
  volume_id = "${aws_ebs_volume.extra_graylog_volume.id}"
}
*/


/*
  Create mongo-agent Server
*/
resource "aws_instance" "mongo_agent" {
  ami = "${var.aws_base_ami}"
  availability_zone = "${aws_subnet.tools_subnet.availability_zone}"
  associate_public_ip_address = false
  instance_type = "t2.small"
  key_name = "${var.aws_key_name}"
  subnet_id = "${aws_subnet.tools_subnet.id}"

  vpc_security_group_ids = [
    "${aws_security_group.ansible_management.id}",
    "${module.aws_vpc.security_group_ids["csky_internal"]}",
    "${aws_security_group.zabbix_agent.id}"
  ]

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = "10"
  }

  tags {
    Name = "mongo-agent.${var.base_domain_name}"
    Groups = "mongo_agent"
    Environment = "tools"
    Project = "${var.project_name}"
  }
}

/*
  PFsense VPN Service
*/

resource "aws_network_interface" "pfsense_LAN" {
  description = "Used for pfsense VPN as the LAN interface for the vpn"
  subnet_id = "${module.aws_vpc.subnet_ids["nat_a"]}"
  tags {
    Name = "pfsense-WAN"
  }
}

resource "aws_instance" "pfsense" {
  ami = "${var.pfsense_ami}"
  availability_zone = "${aws_subnet.pfsense_subnet.availability_zone}"
  associate_public_ip_address = true
  instance_type = "t2.small"
  key_name = "${var.aws_key_name}"
  subnet_id = "${aws_subnet.pfsense_subnet.id}"

  vpc_security_group_ids = [
    "${aws_security_group.pfsense_access.id}",
    "${aws_security_group.ansible_management.id}",
    "${module.aws_vpc.security_group_ids["csky_internal"]}",
    "${aws_security_group.zabbix_agent.id}"
  ]

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = "10"
  }

  tags {
    Name = "pfsense-vpn.${var.base_domain_name}"
    Groups = "pfsense"
    Environment = "tools"
    Project = "${var.project_name}"
  }
}

resource "aws_network_interface_attachment" "pfsense_LAN" {
  device_index = 1
  instance_id = "${aws_instance.pfsense.id}"
  network_interface_id = "${aws_network_interface.pfsense_LAN.id}"
}

resource "aws_eip" "pfsense" {
//  network_interface = "${aws_instance.pfsense.network_interface_id}"
  instance = "${aws_instance.pfsense.id}"
  tags {
    Name = "pfsense VPN"
  }
}

resource "aws_instance" "grafana" {
    ami = "${var.aws_base_ami_6-11-2018}"
    availability_zone = "${aws_subnet.tools_subnet.availability_zone}"
    associate_public_ip_address = false
    instance_type = "t2.medium"
    key_name = "${var.aws_key_name}"
    subnet_id = "${aws_subnet.tools_subnet.id}"

    vpc_security_group_ids = [
      "${module.aws_vpc.security_group_ids["csky_dns"]}",
      "${aws_security_group.ansible_management.id}",
      "${module.aws_vpc.security_group_ids["csky_internal"]}",
      "${aws_security_group.zabbix_agent.id}",
    ]

    root_block_device {
      delete_on_termination = true
      volume_type           = "gp2"
      volume_size           = "10"
    }

    tags {
      Name = "grafana.${var.base_domain_name}"
      Groups = "grafana"
      Environment = "tools"
      Project = "${var.project_name}"
    }
}



resource "aws_instance" "influx" {
  ami = "${var.aws_base_m5}"
  availability_zone = "${aws_subnet.tools_subnet.availability_zone}"
  associate_public_ip_address = false
  instance_type = "m5.large"
  key_name = "${var.aws_key_name}"
  subnet_id = "${aws_subnet.tools_subnet.id}"

  vpc_security_group_ids = [
    "${aws_security_group.ansible_management.id}",
    "${aws_security_group.influxdb_server.id}",
    "${module.aws_vpc.security_group_ids["csky_internal"]}",
    "${aws_security_group.zabbix_agent.id}",
  ]

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = "10"
  }

  ebs_block_device {
    device_name           = "/dev/sdb"
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp2"
    volume_size           = "200"
  }

  ebs_block_device {
    device_name           = "/dev/sdc"
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp2"
    volume_size           = "200"
  }

  tags {
    Name = "influx.${var.base_domain_name}"
    Groups = "influxdb"
    Environment = "tools"
    Project = "${var.project_name}"
  }
}
