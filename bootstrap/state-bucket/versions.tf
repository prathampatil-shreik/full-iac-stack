terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }

  # Bootstrap uses local state intentionally.
  # The state bucket this configuration creates cannot store its own state.
  #
  # IMPORTANT: Never commit terraform.tfstate or terraform.tfstate.backup to Git.
  # These files are excluded by .gitignore at the repository root.
  # After applying this configuration, back up the local state file to a secure
  # location outside the repository, such as an encrypted file store or a
  # separately managed S3 bucket with restricted access.
}
