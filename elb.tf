#Security group for load balancer
resource "aws_security_group" "poc-lb" {
  name = "poc_lb_sg"
  description = "Security Group for POC Load Balancer"
  vpc_id = "${aws_vpc.poc_vpc.id}"
}

# Allow incoming traffic on port 80 from ALL.
resource "aws_security_group_rule" "poc_lb_ingress_80" {
  security_group_id = "${aws_security_group.poc-lb.id}"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# Allow outgoing traffic from port 80.
resource "aws_security_group_rule" "poc_lb_egress_80" {
  security_group_id = "${aws_security_group.poc-lb.id}"
  type = "egress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.WebServerSG.id}"
}

#
# Load balancer
#
resource "aws_elb" "poc-lb" {
  name = "poc-lb"
  security_groups = ["${aws_security_group.poc-lb.id}"]
  subnets = ["${aws_subnet.pub_sub.*.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 10
    timeout = 25
    target = "HTTP:80/"
    interval = 30
  }

  idle_timeout = 60
  cross_zone_load_balancing = true
  connection_draining = true
  connection_draining_timeout = 30
  internal = false

  tags {
    Name = "poc-lb"
  }
}


#
# Launch config
#

data "template_file" "poc_lc_ud" {
  template = "${file("./user-data/bootstrap-userdata.template.sh")}"
}

resource "aws_launch_configuration" "pocweb" {
    lifecycle {
      create_before_destroy = true
    }
    name_prefix = "poc-"
    iam_instance_profile = "${aws_iam_instance_profile.poc_profile.name}"
    key_name = "${var.ssh_key_name}"
    user_data = "${data.template_file.poc_lc_ud.rendered}"
    security_groups = ["${aws_security_group.WebServerSG.id}"] 
    image_id = "${var.ami_id}"
    instance_type = "${var.instance_type}"
}


#
# Autoscaling Group
#
resource "aws_autoscaling_group" "pocasg" {
  lifecycle {
      create_before_destroy = true
  }
  name = "poc-asg"
  vpc_zone_identifier = ["${aws_subnet.pub_sub.*.id}"]
  max_size = "${var.poc-asg-max}"
  min_size = "${var.poc-asg-min}"
  health_check_grace_period = 300
  health_check_type = "ELB"
  force_delete = "false"
  termination_policies = ["OldestInstance"]
  load_balancers = ["${aws_elb.poc-lb.id}"]
  launch_configuration = "${aws_launch_configuration.pocweb.name}"
}
