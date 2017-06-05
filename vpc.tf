#Create VPC
resource "aws_vpc" "poc_vpc" {
	cidr_block = "${var.vpc_cidr_block}"
        enable_dns_support = true
        enable_dns_hostnames = true
	tags {
	    Name = "POC_VPC"
	}
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
	vpc_id = "${aws_vpc.poc_vpc.id}"
	tags {
	    Name = "igw-POC_VPC"
	}
}

##NAT Gateway
resource "aws_eip" "nat_ip" {
	vpc = true
}

##
resource "aws_nat_gateway" "nat" {
        count = 1
	allocation_id = "${aws_eip.nat_ip.id}"
	subnet_id = "${element(aws_subnet.pub_sub.*.id, count.index)}"
}

#Public Subnets provides 256 private subnet addresses
resource "aws_subnet" "pub_sub" {
        count = "${length(split(",", var.public_cidr_blocks))}"
	vpc_id = "${aws_vpc.poc_vpc.id}"
	cidr_block = "${element(split(",",var.public_cidr_blocks),count.index)}"
        availability_zone = "${var.region}${element(split(",",var.zones),count.index)}"
        map_public_ip_on_launch = true
        tags {
           Name = "Public Subnet ${count.index + 1}"
        }
}


#Private Subnet provides 256 private subnet addresses
resource "aws_subnet" "priv_sub" {
        count = "${length(split(",", var.private_cidr_blocks))}"
	vpc_id = "${aws_vpc.poc_vpc.id}"
	cidr_block = "${element(split(",",var.private_cidr_blocks),count.index)}"
        availability_zone = "${var.region}${element(split(",",var.zones),count.index)}"
        tags {
           Name = "Private Subnet ${count.index + 1}"
        }
}

#Route table 
resource "aws_route_table" "public" {
	vpc_id = "${aws_vpc.poc_vpc.id}"
	tags {
	    Name = "route-table-public-POC_VPC"
	}
}

#Routes for private and public subnets
resource "aws_route" "public_internet" {
	route_table_id = "${aws_route_table.public.id}"
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_internet_gateway.igw.id}"
	depends_on = ["aws_route_table.public"]
}

resource "aws_route_table" "private" {
	vpc_id = "${aws_vpc.poc_vpc.id}"
	tags {
	    Name = "route-table-private-POC_VPC"
	}
}

##
resource "aws_route" "private_internet" {
	route_table_id = "${aws_route_table.private.id}"
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = "${aws_nat_gateway.nat.id}"
	depends_on = ["aws_route_table.private"]
}

#Route table association 

resource "aws_route_table_association" "public" {
        count = "${length(split(",", var.public_cidr_blocks))}" 
        subnet_id = "${element(aws_subnet.pub_sub.*.id, count.index)}"
	route_table_id = "${aws_route_table.public.id}"
}

##
resource "aws_route_table_association" "private" {
        count = "${length(split(",", var.private_cidr_blocks))}" 
        subnet_id = "${element(aws_subnet.priv_sub.*.id, count.index)}"
	route_table_id = "${aws_route_table.private.id}"
}

#
# Security Groups
#

resource "aws_security_group" "WebServerSG" {
  name = "webserver_sg"
  description = "Security Group for Web Servers"
  vpc_id = "${aws_vpc.poc_vpc.id}"
  tags {
            Name = "WebSG-POC_VPC"
        }
}

resource "aws_security_group" "DBServerSG" {
  name = "dbserver_sg"
  description = "Security Group for Database Servers"
  vpc_id = "${aws_vpc.poc_vpc.id}"
  tags {
            Name = "DbSG-POC_VPC"
        }
}

resource "aws_security_group_rule" "webserversg_ingress_80" {
  # Allow port 80 from anywhere.
  security_group_id = "${aws_security_group.WebServerSG.id}"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "webserversg_ingress_22" {
  # Allow port 22 from anywhere.
  security_group_id = "${aws_security_group.WebServerSG.id}"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "webserversg_egress_icmp" {
  # Allow ping from instances.
  security_group_id = "${aws_security_group.WebServerSG.id}"
  type = "egress"
  from_port = -1 
  to_port = -1
  protocol = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "webserversg_egress_all" {
  # Allow outbound traffic from instances.
  security_group_id = "${aws_security_group.WebServerSG.id}"
  type = "egress"
  from_port = 0 
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "dbserversg_ingress_22" {
  # Allow port 22 from public subnet.
  security_group_id = "${aws_security_group.DBServerSG.id}"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.WebServerSG.id}"
}

resource "aws_security_group_rule" "dbserversg_ingress_3306" {
  # Allow port 3306 from public subnet.
  security_group_id = "${aws_security_group.DBServerSG.id}"
  type = "ingress"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.WebServerSG.id}"
}

resource "aws_security_group_rule" "dbserversg_egress_all" {
  # Allow outbound traffic from instances.
  security_group_id = "${aws_security_group.DBServerSG.id}"
  type = "egress"
  from_port = 0 
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "dbserversg_ingress_icmp" {
  # Allow ping to instances.
  security_group_id = "${aws_security_group.DBServerSG.id}"
  type = "ingress"
  from_port = -1 
  to_port = -1
  protocol = "icmp"
  source_security_group_id = "${aws_security_group.WebServerSG.id}"
}


