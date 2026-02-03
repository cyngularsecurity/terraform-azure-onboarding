module "onboarding" {
    source  = "cyngularsecurity/onboarding/azure"
    # version = "3.3.2"

    client_name    = "clipper"
    application_id = "f235d0ca-f71e-4fbb-b211-a6a629487f94"
    locations      = ["israelcentral", "canadacentral", "westus2"]

    main_subscription_id = "7fe2354f-8fbb-4bf3-966e-d968a4d8f6bb"
}

output "org_admin_consent_url" {
  description = "Admin Consent URL"
  value = module.onboarding.org_admin_consent_url
}
