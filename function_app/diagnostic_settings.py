ACTIVITY_LOG_SETTINGS = ["Security", "Administrative", "ServiceHealth", "Alert", "Recommendation", "Policy", "ResourceHealth", "Autoscale"]
ALL_AND_AUDIT_LOG_SETTINGS = {
    "AllLogs": True,  # categoryGroup
    "Audit": True     # categoryGroup
}

ALL_LOGS_SETTING = {
    "AllLogs": True   # categoryGroup
}

AUDIT_EVENT_LOG_SETTINGS = {
    "AuditEvent": False  # category
}

AKS_SETTINGS = {
    "kube-audit": False,    # category
    "kube-apiserver": False # category
}

all_logs_types = [ # resource types to configure diagnostic settings for, with category group of allLogs -- 1
    "Microsoft.Compute/components",
    "Microsoft.Compute/bastionHosts",
    "microsoft.recoveryservices/vaults",
    "Microsoft.Network/virtualNetworks",
    "microsoft.desktopvirtualization/workspaces",
    "microsoft.insights/datacollectionrules",
]

all_logs_and_audit_types = [ # resource types to configure diagnostic settings for, with category groups of allLogs, audit -- 2
    "Microsoft.KeyVault/vaults",
    "Microsoft.OperationalInsights/workspaces",
    "Microsoft.Network/publicIPAddresses",
    "Microsoft.EventHub/namespaces",
    "Microsoft.DBforMySQL/flexibleServers",
    "microsoft.cache/redis",
    "Microsoft.ServiceBus/namespaces",
    "Microsoft.DBforPostgreSQL/flexibleServers",
    "microsoft.synapse/workspaces",
]

blacklisted_types = [ # resource types to not configure diagnostic settings for
    "Microsoft.Storage/storageAccounts",

    "Microsoft.Network/networkWatchers",
    "Microsoft.Network/networkInterfaces",
    "Microsoft.Network/routetables",
    "Microsoft.Network/privateendpoints",
    "Microsoft.Network/loadBalancers",
    "Microsoft.Network/networkManagers",

    "Microsoft.Web/serverFarms",
    "Microsoft.Web/sites",

    "Microsoft.Compute/images",
    "Microsoft.Compute/disks",
    "Microsoft.Compute/snapshots",
    "Microsoft.Compute/sshPublicKeys",
    "Microsoft.Compute/virtualMachines",
    "Microsoft.Compute/availabilitysets",
    "Microsoft.Compute/virtualmachines/extensions",
    "Microsoft.Compute/virtualMachineScaleSets",

    "microsoft.operationsmanagement/solutions",
    "microsoft.managedidentity/userassignedidentities",

    "microsoft.devtestlab/labs",
    "microsoft.devtestlab/schedules",

    "Microsoft.Databricks/accessconnectors",
    "Microsoft.Databricks/workspaces",
    "microsoft.operationalinsights/querypacks",

    "Microsoft.EventGrid/systemTopics",

    "microsoft.insights/components",

    "Microsoft.ClassicNetwork/networkSecurityGroups",

    "Microsoft.Sql/servers",
    "Microsoft.Sql/servers/databases",
    "Microsoft.Network/networkSecurityGroups",
    "microsoft.virtualmachineimages/imagetemplates",
    "microsoft.network/networkwatchers/flowlogs",
    "microsoft.compute/galleries/images/versions",
    "microsoft.compute/galleries",
    "microsoft.compute/galleries/images",
]
