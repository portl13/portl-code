resource "aws_autoscaling_policy" "add_capacity" {
  name                   = "AddECSHost"
  scaling_adjustment     = 3
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = "${module.production_ecs.auto_scaling_group_name}"
}

resource "aws_autoscaling_policy" "reduce_capacity" {
  name                   = "RemoveECSHost"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 400
  autoscaling_group_name = "${module.production_ecs.auto_scaling_group_name}"
}
