data "aws_caller_identity" "primary" {
  provider = aws.primary
}

output "caller_identity" {
  value = data.aws_caller_identity.primary
}

output "user_names" {
  value = [for user in local.users: "${user.first_name} ${user.last_name}"]
}