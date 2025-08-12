locals {
  roles = toset(jsondecode(<<EOF
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
  ))

  app_insights_unsupported_locations = ["israelcentral"]

  valid_locations = [
    # Australia
    "australiacentral", "australiacentral2", "australiaeast", "australiasoutheast", "australiaeastfoundational",
    # Brazil
    "brazilsouth", "brazilsoutheast", "brazilus",
    # Canada
    "canadacentral", "canadaeast",
    # Central and South America
    "chilecentral",
    # Europe
    "austriaeast", "francecentral", "francesouth", "germanynorth", "germanywestcentral", "polandcentral", "spaincentral", "swedencentral", "swedensouth", "switzerlandnorth", "switzerlandwest", "belgiumcentral", "denmarkeast", "norwayeast", "norwaywest", "westeurope", "ukwest", "uksouth",
    # India
    "centralindia", "southindia", "westindia", "jioindiacentral", "jioindiawest",
    # Israel
    "israelcentral", "israelnorthwest",
    # Japan
    "japaneast", "japanwest",
    # Korea
    "koreacentral", "koreasouth",
    # Malaysia
    "malaysiasouth", "malaysiawest",
    # Mexico
    "mexicocentral",
    # New Zealand
    "newzealandnorth",
    # Qatar
    "qatarcentral",
    # South Africa
    "southafricanorth", "southafricawest",
    # Southeast Asia
    "eastasia", "southeastasia",
    # United Arab Emirates
    "uaecentral", "uaenorth",
    # United States
    "centralus", "centraluseuap", "eastus", "eastus2", "eastus2euap", "eastus3", "eastusslv", "northcentralus", "southcentralus", "southcentralus2", "southeastus", "southeastus3", "southeastus5", "westcentralus", "westus", "westus2", "westus3", "southwestus"
  ]

  resource_prefix = format("cyngular-%s", var.client_name)
  random_suffix   = random_string.suffix.result

  config        = data.azuread_client_config.current
  mgmt_group_id = local.config.tenant_id

  main_location = var.main_location != "" ? var.main_location : element(var.locations, 0)

  tags = {
    Vendor = "Cyngular Security"
  }
}