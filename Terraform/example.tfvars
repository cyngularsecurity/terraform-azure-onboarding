
client_name    = "asos"
tenant_id      = "24d70ce4-12c4-4e49-8583-ce91546f86ea"
application_id = "9061c3d3-e5e8-4910-afff-79656dfb1e5e"

locations = ["westeurope", "eastus"]

tags = {
  Owner = "Cyngular"
}

roles_json = <<EOF
[
  "Reader",
  "Disk Pool Operator",
  "Data Operator for Managed Disks",
  "Disk Snapshot Contributor",
  "Microsoft Sentinel Reader",
  "API Management Workspace Reader",
  "Reader and Data Access"
]
EOF


## data sources:
# "NSG Flow Logs",
# "Activity Logs",
# "Audit Events"
