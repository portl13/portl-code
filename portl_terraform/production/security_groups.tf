resource "aws_security_group" "mongo" {
    name = "mongo_production"
    description = "Allow tcp/27017, from Production/ Management"
    vpc_id = "${data.terraform_remote_state.root.vpc_id}"

    tags {
        Name = "mongo_production"
    }

    ingress {
        from_port = 27017
        to_port = 27017
        protocol = "tcp"
        cidr_blocks = [
          "${data.aws_subnet.ecs_subnet_a.cidr_block}",
          "${data.aws_subnet.ecs_subnet_b.cidr_block}",
          "${data.aws_subnet.ecs_subnet_c.cidr_block}",
          "${data.aws_subnet.tools_subnet.cidr_block}"
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