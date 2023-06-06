# variables.tf
variable "access_key" {
  default = "<PUT IN YOUR AWS ACCESS KEY>"
}
variable "secret_key" {
  default = "<PUT IN YOUR AWS SECRET KEY>"
}
variable "region" {
  default = "eu-west-3"
}
variable "availabilityZone_a" {
  default = "eu-west-3a"
}
variable "availabilityZone_b" {
  default = "eu-west-3b"
}
variable "availabilityZone_c" {
  default = "eu-west-3c"
}
variable "instanceTenancy" {
  default = "default"
}
variable "dnsSupport" {
  default = true
}
variable "dnsHostNames" {
  default = true
}
variable "vpcCIDRblock" {
  default = "10.0.0.0/16"
}
variable "publicSubnet1CIDRblock" {
  default = "10.0.1.0/24"
}
variable "publicSubnet2CIDRblock" {
  default = "10.0.2.0/24"
}
variable "publicSubnet3CIDRblock" {
  default = "10.0.3.0/24"
}
variable "privateSubnet1CIDRblock" {
  default = "10.0.4.0/24"
}
variable "privateSubnet2CIDRblock" {
  default = "10.0.5.0/24"
}
variable "privateSubnet3CIDRblock" {
  default = "10.0.6.0/24"
}
variable "destinationCIDRblock" {
  default = "0.0.0.0/0"
}
variable "ingressCIDRblock" {
  type    = list(any)
  default = ["0.0.0.0/0"]
}
variable "egressCIDRblock" {
  type    = list(any)
  default = ["0.0.0.0/0"]
}
variable "mapPublicIP" {
  default = true
}
variable "ami" {
  default = "ami-05e8e219ac7e82eba"
}
variable "itype" {
  default = "t2.micro"
}
variable "subnet" {
  default = "subnet-81896c8e"
}
variable "publicip" {
  default = true
}
variable "keyname" {
  default = "ec2-slo-key"
}
variable "securityGroupName" {
  default = "project-Security-Group"
}

# variables the Subnet list CIDR values public & private
variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
}

