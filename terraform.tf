variable "cluster_kubernetes_version" {}

variable "workers_group_ami" {}

variable "workers_group_admin_asg_desired_capacity" {}
variable "workers_group_admin_asg_min_size" {}
variable "workers_group_admin_asg_max_size" {}
variable "workers_group_admin_instance_type" {}

variable "workers_group_default_asg_desired_capacity" {}
variable "workers_group_default_asg_min_size" {}
variable "workers_group_default_asg_max_size" {}
variable "workers_group_default_instance_type" {}

variable "workers_group_default_spot_asg_desired_capacity" {}
variable "workers_group_default_spot_asg_min_size" {}
variable "workers_group_default_spot_asg_max_size" {}
variable "workers_group_default_spot_instance_type" {}
variable "workers_group_default_spot_price" {}

variable "workers_group_backend_asg_desired_capacity" {}
variable "workers_group_backend_asg_min_size" {}
variable "workers_group_backend_asg_max_size" {}
variable "workers_group_backend_instance_type" {}

#--------------------------------------------------------------
# Cluster
#--------------------------------------------------------------

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "4.0.2"
  cluster_name    = "${var.cluster_name}"
  cluster_version = "${var.cluster_kubernetes_version}"

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  subnets = [
    "${module.vpc.private_subnets}",
  ]

  vpc_id             = "${module.vpc.vpc_id}"
  worker_group_count = 4

  worker_groups = [
    {
      name                 = "${var.cluster_name}_workers_group_admin"
      instance_type        = "${var.workers_group_admin_instance_type}"
      asg_desired_capacity = "${var.workers_group_admin_asg_desired_capacity}"
      asg_min_size         = "${var.workers_group_admin_asg_min_size}"
      asg_max_size         = "${var.workers_group_admin_asg_max_size}"
      autoscaling_enabled  = true
      suspended_processes  = "AZRebalance"
      kubelet_extra_args   = "--register-with-taints=ProtectedNodes=AdminNodes:NoSchedule --node-labels=eks_worker_group=admin"
      ami_id               = "${var.workers_group_ami}"
    },
    {
      name                 = "${var.cluster_name}_workers_group_default"
      instance_type        = "${var.workers_group_default_instance_type}"
      asg_desired_capacity = "${var.workers_group_default_asg_desired_capacity}"
      asg_min_size         = "${var.workers_group_default_asg_min_size}"
      asg_max_size         = "${var.workers_group_default_asg_max_size}"
      autoscaling_enabled  = true
      suspended_processes  = "AZRebalance"
      kubelet_extra_args   = "--node-labels=eks_worker_group=default"
      ami_id               = "${var.workers_group_ami}"
    },
    {
      name                 = "${var.cluster_name}_workers_group_default_spot"
      spot_price           = "${var.workers_group_default_spot_price}"
      instance_type        = "${var.workers_group_default_spot_instance_type}"
      asg_desired_capacity = "${var.workers_group_default_spot_asg_desired_capacity}"
      asg_min_size         = "${var.workers_group_default_spot_asg_min_size}"
      asg_max_size         = "${var.workers_group_default_spot_asg_max_size}"
      autoscaling_enabled  = true
      suspended_processes  = "AZRebalance"
      kubelet_extra_args   = "--node-labels=kubernetes.io/lifecycle=spot --node-labels=eks_worker_group=default"
      ami_id               = "${var.workers_group_ami}"
    },
    {
      name                 = "${var.cluster_name}_workers_group_backend"
      instance_type        = "${var.workers_group_backend_instance_type}"
      asg_desired_capacity = "${var.workers_group_backend_asg_desired_capacity}"
      asg_min_size         = "${var.workers_group_backend_asg_min_size}"
      asg_max_size         = "${var.workers_group_backend_asg_max_size}"
      autoscaling_enabled  = true
      suspended_processes  = "AZRebalance"
      kubelet_extra_args   = "--register-with-taints=ProtectedNodes=BackendNodes:NoSchedule --node-labels=eks_worker_group=backend"
      ami_id               = "${var.workers_group_ami}"
    },
  ]

  worker_additional_security_group_ids = [
    "${aws_security_group.all_worker_mgmt.id}",
  ]

  map_roles          = "${local.map_roles}"
  map_roles_count    = "${local.map_roles_count}"
  map_users          = "${local.map_users}"
  map_users_count    = "${local.map_users_count}"
  map_accounts       = "${local.map_accounts}"
  map_accounts_count = "${local.map_accounts_count}"
}
