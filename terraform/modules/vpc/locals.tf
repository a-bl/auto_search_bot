data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  avz      = data.aws_availability_zones.available.names
  new_bits = var.subnet_prefix - tonumber(regex("[[:digit:]]+$", var.vpc_cidr))

  pub_subnets = zipmap(
    local.avz,
    [
      for i in range(1, length(local.avz) + 1) :
      cidrsubnet(var.vpc_cidr, local.new_bits, i)
    ]
  )

  priv_subnets = zipmap(
    local.avz,
    [
      for i in range(1 + length(local.avz), length(local.avz) * 2 + 1) :
      cidrsubnet(var.vpc_cidr, local.new_bits, i)
    ]
  )
}
