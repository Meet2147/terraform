#Userdata file which installs nginx on web instance.
data "template_file" "poc_web_ud" {
  template = "${file("./user-data/bootstrap-userdata.web-template.sh")}"
}

#Create indepedent web instance 
resource "aws_instance" "web-poc" {
   count = "1"
   ami = "${var.ami_id}"
   instance_type = "${var.instance_type}"
   key_name = "${var.ssh_key_name}"
   subnet_id = "${element(aws_subnet.pub_sub.*.id, count.index)}"
   user_data = "${data.template_file.poc_web_ud.rendered}"
   iam_instance_profile = "${aws_iam_instance_profile.poc_profile.name}" 
   vpc_security_group_ids = ["${aws_security_group.WebServerSG.id}"]
   availability_zone = "${var.region}${element(split(",",var.zones),count.index)}"
   tags {
    Name = "Web-instance ${count.index + 1}"
  }
}

#Attach Elastic IP to instance
resource "aws_eip" "ip" {
    instance = "${aws_instance.web-poc.id}"
}

#Attach instance to ELB
resource "aws_elb_attachment" "web" {
    elb      = "${aws_elb.poc-lb.id}"
    instance = "${aws_instance.web-poc.id}"
    }

#Userdata file which installs mysql on db instance.
data "template_file" "poc_db_ud" {
  template = "${file("./user-data/bootstrap-userdata.db-template.sh")}"
}
#Create mysql db instance in private subnet
resource "aws_instance" "db-poc" {
   count = "1"
   ami = "${var.ami_id}"
   instance_type = "${var.instance_type}"
   key_name = "${var.ssh_key_name}"
   subnet_id = "${element(aws_subnet.priv_sub.*.id, count.index)}"
   user_data = "${data.template_file.poc_db_ud.rendered}"
   iam_instance_profile = "${aws_iam_instance_profile.poc_profile.name}"
   vpc_security_group_ids = ["${aws_security_group.DBServerSG.id}"]
   availability_zone = "${var.region}${element(split(",",var.zones),count.index)}"
   tags {
    Name = "DB-instance ${count.index + 1}"
  }
}
