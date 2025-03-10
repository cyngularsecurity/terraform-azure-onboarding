output "deploy_script_path" {
  value = local.deploy_script_path
}

output "deploy_script_env" {
  value = join("\n", [for k, v in local.deploy_script_env : "export ${k}=${v}"])
}

output "sync_triggers_command" {
  value = local.sync_triggers_command
}