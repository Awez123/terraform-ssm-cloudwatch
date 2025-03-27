variable "ami" {}
variable "instance_type" {}
variable "key_name" {}
variable "iam_instance_profile" {}
variable "vpc_id" {}
variable "security_group_name" {}
variable "ssh_cidr_blocks" {
  default = ["0.0.0.0/0"]
}
variable "tags" {
  type = map(string)
}
