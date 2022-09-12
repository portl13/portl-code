/*
  Create Mongo EC2 Instances
*/
resource "aws_instance" "mongo1m5" {
    ami = "${var.aws_base_m5}"
    availability_zone = "${data.aws_subnet.ecs_subnet_a.availability_zone}"
    associate_public_ip_address = false
    instance_type = "r5.large"
    key_name = "${var.aws_key_name}"
    subnet_id = "${data.aws_subnet.ecs_subnet_a.id}"

    vpc_security_group_ids = [
      "${aws_security_group.mongo.id}",
      "${data.aws_security_group.csky_internal.id}",
      "${data.terraform_remote_state.root.zabbix_agent_security_group_id}"
    ]

    root_block_device {
      delete_on_termination = true
//      encrypted             = true
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
      Name = "mongo1.${var.base_domain_name}"
      Environment = "${var.app_env}"
      Project = "${var.app_name}"
      Groups = "${var.app_env},mongo"
    }

    volume_tags {
      Name = "mongo1.${var.base_domain_name}_data"
    }
}

resource "aws_instance" "mongo2m5" {
    ami = "${var.aws_base_m5}"
    availability_zone = "${data.aws_subnet.ecs_subnet_b.availability_zone}"
    associate_public_ip_address = false
    instance_type = "r5.large"
    key_name = "${var.aws_key_name}"
    subnet_id = "${data.aws_subnet.ecs_subnet_b.id}"

    vpc_security_group_ids = [
      "${aws_security_group.mongo.id}",
      "${data.aws_security_group.csky_internal.id}",
      "${data.terraform_remote_state.root.zabbix_agent_security_group_id}"
    ]

    root_block_device {
      delete_on_termination = true
//      encrypted             = true
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
      Name = "mongo2.${var.base_domain_name}"
      Environment = "${var.app_env}"
      Project = "${var.app_name}"
      Groups = "${var.app_env},mongo"
    }

    volume_tags {
      Name = "mongo2.${var.base_domain_name}_data"
    }
}

resource "aws_instance" "mongo3m5" {
    ami = "${var.aws_base_m5}"
    availability_zone = "${data.aws_subnet.ecs_subnet_c.availability_zone}"
    associate_public_ip_address = false
    instance_type = "r5.large"
    key_name = "${var.aws_key_name}"
    subnet_id = "${data.aws_subnet.ecs_subnet_c.id}"

    vpc_security_group_ids = [
      "${aws_security_group.mongo.id}",
      "${data.aws_security_group.csky_internal.id}",
      "${data.terraform_remote_state.root.zabbix_agent_security_group_id}"
    ]

    root_block_device {
      delete_on_termination = true
//      encrypted             = true
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
      Name = "mongo3.${var.base_domain_name}"
      Environment = "${var.app_env}"
      Project = "${var.app_name}"
      Groups = "${var.app_env},mongo"
    }

    volume_tags {
      Name = "mongo3.${var.base_domain_name}_data"
    }
}

resource "aws_instance" "task" {
  ami = "${var.aws_base_ami_6-11-2018}"
  availability_zone = "${data.aws_subnet.ecs_subnet_a.availability_zone}"
  associate_public_ip_address = false
  instance_type = "t2.micro"
  key_name = "${var.aws_key_name}"
  subnet_id = "${data.aws_subnet.ecs_subnet_a.id}"

  vpc_security_group_ids = [
    "${data.aws_security_group.csky_internal.id}"
  ]

  tags {
    Name = "task.${var.base_domain_name}"
    Environment = "staging"
    Project = "portl"
    Groups = "staging,task"
  }
}
