
terraform {
  // source = "git::git@github.com:example/modules.git//vpc?ref=v0.13.0"
  source = "tfr:///cyngularsecurity/onboarding/azure?version=3.0.14"

  # extra_arguments "custom_vars" {
  #   commands = ["plan", "apply"]
  #   arguments = [
  #     "-var-file=${get_terragrunt_dir()}/cyngular.tfvars"
  #   ]
  # }
}

// remote_state {
//   backend = "s3"
//   config = {
//     bucket         = "my-terraform-state"
//     key            = "${path_relative_to_include()}/terraform.tfstate"
//     region         = "us-east-1"
//     encrypt        = true
//     dynamodb_table = "my-lock-table"
//   }
// }

// inputs = {
//   vpc_name = "my-vpc"
//   cidr_block = "10.0.0.0/16"
// }

# include {
#   path = find_in_parent_folders()
# }
