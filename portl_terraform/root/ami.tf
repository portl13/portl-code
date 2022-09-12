resource "aws_ami" "base_m5" {
  name = "m5_6_11_2018_${var.aws_base_ami_6-11-2018}"
  virtualization_type = "hvm"
  root_device_name = "/dev/xvda"
  ena_support = true

  ebs_block_device {
    device_name = "/dev/xvda"
    snapshot_id = "snap-0f26e3e96e649766f"
    volume_size = 10
  }
}