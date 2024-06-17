# client company name -
client_name = "asos"
# client company home tenant id -
tenant_id = "24d70ce4-12c4-4e49-8583-ce91546f86ea"
# Cyngular's client specific Application ID -
application_id = "9061c3d3-e5e8-4910-afff-79656dfb1e5e"

# client operational locations -
locations = ["westeurope", "eastus", "westus"]

# uncomment to deactivate, values are true by default -
# enable_audit_events_logs = false
# enable_activity_logs     = false
# enable_flow_logs         = false

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

// 'EOF' should trail an empty line -^-