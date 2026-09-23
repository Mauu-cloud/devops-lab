output "role_arn" {
  description = "Copiar a Settings > Secrets and variables > Actions > Variables > AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}
