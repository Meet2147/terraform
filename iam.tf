#### IAM role for any instance to create it's tag 
resource "aws_iam_role" "poc_role" {
    name = "poc_role-${var.region}"
    assume_role_policy = "${file("./policies/default-assume.json")}"
}

resource "aws_iam_instance_profile" "poc_profile" {
    name = "poc_profile-${var.region}"
    roles = ["${aws_iam_role.poc_role.name}"]
}

#### Creates Policy ####
resource "aws_iam_policy" "tag_edit" {
    name = "edit-tag-instance"
    policy = "${file("./policies/tag_policy.json")}"
}

##### Attaches Roles to tag_edit Policy ########
resource "aws_iam_policy_attachment" "tag_access" {
    name = "tag-access-attachment"
    roles = [
      "${aws_iam_role.poc_role.name}"
    ]
    policy_arn = "${aws_iam_policy.tag_edit.arn}"
}
