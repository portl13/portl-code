/*
  Create Mongo EC2 Instances
*/
resource "aws_instance" "mongo1_m5" {
  ami = "${var.aws_base_m5}"
  availability_zone = "${data.aws_subnet.ecs_subnet_a.availability_zone}"
  associate_public_ip_address = false
  instance_type = "r5.large"
  key_name = "${var.aws_key_name}"
  subnet_id = "${data.aws_subnet.ecs_subnet_a.id}"

  vpc_security_group_ids = [
    "${aws_security_group.mongo.id}",
    "${data.aws_security_group.csky_internal.id}",
    "${data.aws_security_group.zabbix_agent.id}"
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
    Name = "mongo1.prod.${var.base_domain_name}"
    Environment = "${var.app_env}"
    Project = "${var.project_name}"
    Groups = "${var.app_env},mongo"
  }

  volume_tags {
    Name = "mongo1.prod.${var.base_domain_name}_data"
  }
}

resource "aws_instance" "mongo2_m5" {
  ami = "${var.aws_base_m5}"
  availability_zone = "${data.aws_subnet.ecs_subnet_b.availability_zone}"
  associate_public_ip_address = false
  instance_type = "r5.large"
  key_name = "${var.aws_key_name}"
  subnet_id = "${data.aws_subnet.ecs_subnet_b.id}"

  vpc_security_group_ids = [
    "${aws_security_group.mongo.id}",
    "${data.aws_security_group.csky_internal.id}",
    "${data.aws_security_group.zabbix_agent.id}"
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
    Name = "mongo2.prod.${var.base_domain_name}"
    Environment = "${var.app_env}"
    Project = "${var.project_name}"
    Groups = "${var.app_env},mongo"
  }

  volume_tags {
    Name = "mongo2.prod.${var.base_domain_name}_data"
  }
}

resource "aws_instance" "mongo3_m5" {
  ami = "${var.aws_base_m5}"
  availability_zone = "${data.aws_subnet.ecs_subnet_c.availability_zone}"
  associate_public_ip_address = false
  instance_type = "r5.large"
  key_name = "${var.aws_key_name}"
  subnet_id = "${data.aws_subnet.ecs_subnet_c.id}"

  vpc_security_group_ids = [
    "${aws_security_group.mongo.id}",
    "${data.aws_security_group.csky_internal.id}",
    "${data.aws_security_group.zabbix_agent.id}"
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
    Name = "mongo3.prod.${var.base_domain_name}"
    Environment = "${var.app_env}"
    Project = "${var.project_name}"
    Groups = "${var.app_env},mongo"
  }

  volume_tags {
    Name = "mongo3.prod.${var.base_domain_name}_data"
  }
}

resource "aws_dlm_lifecycle_policy" "mongo_backup" {
  description        = "mongo prod backup"
  execution_role_arn = "arn:aws:iam::031057183607:role/service-role/AWSDataLifecycleManagerDefaultRole"
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "1 month of daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["23:45"]
      }

      retain_rule {
        count = 30
      }

      tags_to_add {
        Schedule-Name = "Mongo3 Daily Backup"
        Lifecycle = "True"
      }

      copy_tags = false
    }

    target_tags {
      Name = "${aws_instance.mongo3_m5.tags.Name}"
    }
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
    "${data.aws_security_group.csky_internal.id}",
    "${data.aws_security_group.zabbix_agent.id}"
  ]

  tags {
    Name = "task.prod.${var.base_domain_name}"
    Environment = "production"
    Project = "portl"
    Groups = "production,task"
  }
}
