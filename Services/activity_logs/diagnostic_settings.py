ALL_AND_AUDIT_LOG_SETTINGS = [
    {
        "categoryGroup": "audit",
        "enabled": True,
        "retentionPolicy": {
            "enabled": False,
            "days": 30
        }
    },
    {
        "categoryGroup": "allLogs",
        "enabled": True,
        "retentionPolicy": {
            "enabled": False,
            "days": 30
        }
    }
]
ALL_LOGS_SETTING = [
    {
        "categoryGroup": "allLogs",
        "enabled": True,
        "retentionPolicy": {
            "enabled": False,
            "days": 30
        }
    }
]
AUDIT_EVENT_LOG_SETTINGS = [
    {
        "category": "AuditEvent",
        "enabled": True,
        "retentionPolicy": {
            "enabled": False,
            "days": 30
        }
    }
]
ACTIVITY_LOG_SETTINGS = [
    {
        "category": "Security",
        "enabled": True
    },{
        "category": "Administrative",
        "enabled": True
    },{
        "category": "ServiceHealth",
        "enabled": True
    },{
        "category": "Alert",
        "enabled": True
    },{
        "category": "Recommendation",
        "enabled": True
    },{
        "category": "Policy",
        "enabled": True
    },{
        "category": "ResourceHealth",
        "enabled": True
    }
]
