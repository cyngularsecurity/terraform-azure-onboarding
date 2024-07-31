# resource "null_resource" "list_resources" {
#   for_each = toset(var.subscriptions)

#   provisioner "local-exec" {
#     command = "scripts/list_resources.sh ${each.value}"
#     environment = {
#       AZURE_SUBSCRIPTION_ID = each.value
#     }

#     # Capture the output to a file
#     interpreter = ["/bin/bash", "-c"]
#     command = <<EOT
#       ./scripts/list_resources.sh ${each.value} > resources_${each.value}.json
#     EOT
#   }

#   triggers = {
#     always_run = "${timestamp()}"
#   }
# }
