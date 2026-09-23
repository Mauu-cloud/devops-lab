# Crea en AWS lo necesario para que GitHub Actions se autentique SIN access keys:
#   1) Un "OIDC identity provider" que confía en los tokens de GitHub
#   2) Un rol IAM que SOLO puede asumir tu repo, en la rama main
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State remoto (descomentar en un entorno real). El bucket se crea antes, aparte.
  # backend "s3" {
  #   bucket       = "mi-empresa-tfstate"
  #   key          = "github-oidc/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true   # lock nativo en S3 (Terraform >= 1.10). Antes se usaba dynamodb_table
  # }
}

provider "aws" {
  region = var.region
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # CLAVE DE SEGURIDAD: solo este repo y esta rama pueden asumir el rol
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-${replace(var.github_repo, "/", "-")}"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

# Mínimo privilegio: para el lab solo lectura. En real, una policy a medida.
resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
