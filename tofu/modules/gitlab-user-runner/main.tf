# GitLab User Runner Module
#
# Registers a GitLab Runner via the gitlab_user_runner resource,
# automating the token lifecycle. No more manual token creation.

resource "gitlab_user_runner" "this" {
  runner_type     = "group_type"
  group_id        = var.group_id
  tag_list        = var.tag_list
  description     = var.description
  untagged        = var.run_untagged
  access_level    = var.access_level
  locked          = var.locked
  maximum_timeout = var.maximum_timeout
}
