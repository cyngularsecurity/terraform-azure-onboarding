module "onboarding" {
    source  = "cyngularsecurity/onboarding/azure"

    main_subscription_id = "7fe2354f-8fbb-4bf3-966e-d968a4d8f6bb"
    application_id       = "a44fc989-8824-4581-a7e9-72b18c9475ae"
    client_name          = "avona"
    locations            = ["israelcentral", "eastus2"]

    allow_function_logging = true
    caching_enabled = true
}

output "admin_consent_url" {
    description = "Admin Consent URL"
    value = module.onboarding.org_admin_consent_url
}