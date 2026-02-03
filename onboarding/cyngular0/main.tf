module "onboarding" {
    source  = "cyngularsecurity/onboarding/azure"

    main_subscription_id = "71b05b6d-2e8d-4e48-a80e-c0af5e4eaecc" // prod
    # main_subscription_id = "7fe2354f-8fbb-4bf3-966e-d968a4d8f6bb" // client
    application_id = "ac07cf95-71b9-4dc1-b111-abd42080c842"
    client_name    = "cyngular0"
    locations      = ["israelcentral", "eastus2", "eastus", "westus", "westus2", "westeurope"]

    ## false by default
    allow_function_logging = true
    caching_enabled        = true
}

output "admin_consent_url" {
    description = "Admin Consent URL"
    value = module.onboarding.org_admin_consent_url
}
