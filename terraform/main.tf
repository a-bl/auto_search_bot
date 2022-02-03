module "vpc" {
  source = "./modules/vpc"

  app_name   = var.app_name
  aws_region = var.aws_region
  env        = var.env
  vpc_cidr   = var.vpc_cidr
}

module "ecs" {
  source = "./modules/ecs"

  api_token      = var.api_token
  app_name       = var.app_name
  aws_region     = var.aws_region
  env            = var.env
  telegram_token = var.telegram_token

  priv_ids = module.vpc.priv_ids
  pub_ids  = module.vpc.pub_ids
  sg_id    = module.vpc.sg_id
  vpc_id   = module.vpc.vpc_id

  depends_on = [module.vpc]
}

module "codebuild" {
  source = "./modules/codebuild"

  app_name              = var.app_name
  aws_region            = var.aws_region
  env                   = var.env
  github_repo_full_name = var.github_repo_full_name
  github_token          = var.github_token

  ecr_name         = module.ecs.ecr_name
  ecs_cluster_name = module.ecs.ecs_cluster_name
  ecs_service_name = module.ecs.ecs_service_name
  priv_ids         = module.vpc.priv_ids
  sg_id            = module.vpc.sg_id
  vpc_id           = module.vpc.vpc_id

  depends_on = [module.ecs]
}
