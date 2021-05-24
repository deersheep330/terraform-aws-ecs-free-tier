resource "aws_ecr_repository" "ecr_repositories" {

  count = length(var.ecr_repos)

  name = var.ecr_repos[count.index]
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
