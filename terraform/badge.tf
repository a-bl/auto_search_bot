data "github_repository" "app" {
  full_name = var.github_repo_full_name
}

resource "github_repository_file" "readme" {
  repository = data.github_repository.app.name
  file       = "README.md"
  content    = templatefile("README.md.tpl", { badge_url = module.codebuild.badge_url })
}
