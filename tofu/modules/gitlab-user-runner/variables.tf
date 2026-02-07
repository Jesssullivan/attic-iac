# GitLab User Runner Module - Variables

variable "group_id" {
  description = "GitLab group ID for runner registration"
  type        = number
}

variable "tag_list" {
  description = "Tags for the runner"
  type        = list(string)
  default     = []
}

variable "description" {
  description = "Description for the runner"
  type        = string
  default     = ""
}

variable "run_untagged" {
  description = "Allow runner to pick up untagged jobs"
  type        = bool
  default     = false
}

variable "access_level" {
  description = "Access level for the runner (not_protected or ref_protected)"
  type        = string
  default     = "not_protected"

  validation {
    condition     = contains(["not_protected", "ref_protected"], var.access_level)
    error_message = "access_level must be 'not_protected' or 'ref_protected'"
  }
}

variable "locked" {
  description = "Lock runner to current group"
  type        = bool
  default     = false
}

variable "maximum_timeout" {
  description = "Maximum timeout for jobs (seconds)"
  type        = number
  default     = 3600
}
