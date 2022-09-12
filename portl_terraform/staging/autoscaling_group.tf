resource "aws_launch_configuration" "staging_admin_api" {
  name          = "${var.app_name}_${var.app_env}_admin_api_c5.large_${data.aws_ami.ecs_ami.id}"
  image_id      = "${data.aws_ami.ecs_ami.id}"
  instance_type = "c5.large"
  iam_instance_profile = "${data.aws_iam_instance_profile.instance_profile.name}"

  key_name = "${var.aws_key_name}"

  security_groups = [
    "${data.aws_security_group.csky_internal.id}",
    "${data.aws_security_group.ecs_cluster.id}",
    "${data.aws_security_group.zabbix_agent.id}"
  ]

  user_data = <<EOF
#!/bin/bash
mkdir -p /etc/ecs /etc/docker
echo 'ECS_CLUSTER=${aws_ecs_cluster.admin_api.name}' > /etc/ecs/ecs.config
echo 'ECS_ENABLE_CONTAINER_METADATA=true' >> /etc/ecs/ecs.config
echo 'ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","gelf"]' >> /etc/ecs/ecs.config
echo '{"log-driver": "gelf","log-opts": { "gelf-address": "udp://${var.graylog_server}:12201"} }' > /etc/docker/daemon.json
EOF

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = "22"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "staging_admin_api" {
  name                 = "${var.app_name}_${var.app_env}_admin_api"
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.staging_admin_api.name}"
  default_cooldown     = 600
  health_check_grace_period = 120
  max_size             = 1
  min_size             = 1
  metrics_granularity = "1Minute"
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]
  vpc_zone_identifier  = [
    "${data.aws_subnet.ecs_subnet_a.id}",
    "${data.aws_subnet.ecs_subnet_b.id}",
    "${data.aws_subnet.ecs_subnet_c.id}",
  ]

  tags = [
    {
      key                 = "Environment"
      value               = "${var.app_env}"
      propagate_at_launch = true
    },
    {
      key                 = "Groups"
      value               = "auto,${var.app_env},ecs"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "ecsN.${var.app_env}.admin"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "${var.app_name}"
      propagate_at_launch = true
    },
  ]

  lifecycle {
    create_before_destroy = true
  }
}
