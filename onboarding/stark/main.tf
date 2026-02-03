module "onboarding" {
    source  = "cyngularsecurity/onboarding/azure"

    client_name    = "stark"

    main_subscription_id = "7fe2354f-8fbb-4bf3-966e-d968a4d8f6bb"
    application_id = "e976ca78-5c2d-4dd5-ae27-da4f08ce149b"
    locations      = ["israelcentral", "eastus2", "eastus", "westus", "westus2", "westeurope"]

    allow_function_logging = true
    caching_enabled = true
}

output "admin_consent_url" {
    description = "Admin Consent URL"
    value = module.onboarding.org_admin_consent_url
}