// ECR repositories for the ordersync project
resource "aws_ecr_repository" "order_api" {
  name                 = "order-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    project = "ordersync"
    env     = "dev"
  }
}

resource "aws_ecr_repository" "order_processor" {
  name                 = "order-processor"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  tags = {
    project = "ordersync"
    env     = "dev"
  }
}
