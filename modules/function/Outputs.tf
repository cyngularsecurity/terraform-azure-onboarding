output "sync_triggers" {
  value = try(jsondecode(nonsensitive(null_resource.sync_triggers.triggers.stderror)), null)
}